#!/usr/bin/env bash
# toolchain.sh — SessionStart hook, shipped in the toolchain plugin's
# hooks/hooks.json: makes jq and uv available to the skills and hooks of the
# plugins that list this one as a dependency, and checks gh.
#
# PER TOOL. jq and uv: a copy already on PATH is the user's and wins, and
# nothing is fetched. Else a copy in this plugin's data folder,
# ${CLAUDE_PLUGIN_DATA}/bin, at the version tools.lock pins, is used. Else
# that version is downloaded for this platform, its SHA-256 checked against
# tools.lock, run once with --version, and saved there. gh is checked, never
# fetched: on PATH, and signed in by `gh auth token`, which reads gh's own
# store and calls no API. pwsh is not checked: a skill that needs it says
# so itself.
#
# HOW THE TOOLS ARE FOUND. When it used the data folder, it appends the
# folder to PATH through CLAUDE_ENV_FILE, which reaches the Bash tool's
# commands for the rest of the session (hooks docs, "Persist environment
# variables", read 2026-11-18). Never the PowerShell tool's on Windows:
# Claude Code passes PowerShell no variable whose value holds / or \, and
# the unescaped $PATH the line needs makes it pass PowerShell none of the
# file's variables, other hooks' included (same section). So the line is
# written only when the data folder was used, and a machine with both tools
# writes nothing. Another plugin's hook does not see that PATH, nor does a
# hook in settings: a probe session with jq off PATH found this jq from the
# Bash tool and none from a second plugin's PreToolUse hook (2.1.327,
# 2026-11-18). So such a hook looks in <its data folder>/../toolchain-*/bin
# itself, as the fabric plugin's edit gate does; the folder is
# toolchain-<marketplace>, or toolchain-inline under --plugin-dir.
#
# QUIET WHEN ALL IS WELL. With every tool present it prints nothing. Else
# one JSON object: systemMessage, for the user, says what it fetched and
# where, or what is missing and its install line; additionalContext says
# the same to Claude, so a skill needing the tool can say why it fails. A
# compaction repeats the context and not the message.
#
# NEVER BLOCKS. SessionStart cannot block, and every path exits 0, a failed
# download included, which leaves the tool missing and names its install
# line. A download lands in a folder of its own under the data folder and is
# renamed into bin/ only once checked, so two sessions starting together
# each end with a whole binary; a run the hook's timeout killed leaves a
# folder the next fetch removes once it is ten minutes old.
#
# OPT OUT: the plugin's `fetch` option, set false in /config, fetches
# nothing and names the install line instead.
#
# PORTABLE BASH. macOS's /bin/bash is 3.2, so no associative arrays, no
# mapfile, and no "${arr[@]}" under set -u: the messages are strings. As
# fabric-edit-gate.sh does, the first lines re-run it under bash where `sh`
# is dash. On Windows with no Git for Windows, Claude Code runs the command
# in PowerShell, where `sh` is not found: a `hook error` notice each
# session, and nothing fetched.
#
# Test seam: TOOLCHAIN_LOCK names another lock file.

if [ -z "${BASH_VERSION:-}" ]; then
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    exit 0
fi
set -uo pipefail

INPUT=$(cat)
HOOK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOCK=${TOOLCHAIN_LOCK:-$HOOK_DIR/tools.lock}

SOURCE=startup
[[ $INPUT =~ \"source\"[[:space:]]*:[[:space:]]*\"([a-z]+)\" ]] && SOURCE=${BASH_REMATCH[1]}

case "${OSTYPE:-}" in
    linux*) OS=linux ;;
    darwin*) OS=macos ;;
    msys* | cygwin* | win32*) OS=windows ;;
    *) OS=other ;;
esac
case "${HOSTTYPE:-}" in
    x86_64 | amd64) ARCH=x86_64 ;;
    aarch64 | arm64) ARCH=aarch64 ;;
    *) ARCH=other ;;
esac
EXE=
[[ $OS == windows ]] && EXE=.exe

# C:\Work\x or C:/Work/x -> /c/Work/x, for Git Bash's PATH; a POSIX path
# passes unchanged. Windows only reaches the ${,,} expansion, which bash 3.2
# would refuse.
to_posix() {
    local p=${1//\\//} d
    if [[ $OS == windows && $p =~ ^([A-Za-z]):(/.*)?$ ]]; then
        d=${BASH_REMATCH[1]}
        p="/${d,,}${BASH_REMATCH[2]}"
    fi
    printf '%s' "$p"
}

DATA=${CLAUDE_PLUGIN_DATA:-}
[[ -n $DATA ]] || exit 0
DATA=$(to_posix "$DATA")
DATA=${DATA%/}
BIN=$DATA/bin

install_line() {
    case "$1-$OS" in
        jq-windows) echo 'winget install jqlang.jq' ;;
        uv-windows) echo 'winget install astral-sh.uv' ;;
        gh-windows) echo 'winget install GitHub.cli' ;;
        *-macos) echo "brew install $1" ;;
        jq-linux) echo 'sudo apt install jq, or your package manager'"'"'s jq' ;;
        uv-linux) echo 'curl -LsSf https://astral.sh/uv/install.sh | sh' ;;
        gh-linux) echo 'https://github.com/cli/cli#installation' ;;
        *) echo "install $1 and put it on PATH" ;;
    esac
}

# lock_row <tool>: sets VERSION, URL and SHA for this platform.
lock_row() {
    local tool ver plat url sha
    [[ -r $LOCK ]] || return 1
    while read -r tool ver plat url sha; do
        [[ $tool == "$1" && $plat == "$OS-$ARCH" ]] || continue
        VERSION=$ver URL=$url SHA=${sha%$'\r'}
        return 0
    done <"$LOCK"
    return 1
}

# The binaries a tool's release holds, each saved to bin/.
binaries_of() {
    case "$1" in
        uv) echo 'uv uvx' ;;
        *) echo "$1" ;;
    esac
}

pinned_present() { # <tool>: bin/ holds every binary at the pinned version
    local name stamp=
    for name in $(binaries_of "$1"); do
        [[ -f $BIN/$name$EXE ]] || return 1
    done
    [[ -r $BIN/.$1.version ]] && stamp=$(<"$BIN/.$1.version")
    [[ ${stamp%$'\r'} == "$VERSION" ]]
}

# ONE DEADLINE FOR EVERY DOWNLOAD. hooks.json allows 120 s, and a hook the
# timeout kills prints nothing, so no install line. curl restarts
# --max-time on each retry and counts a timeout as transient (its manual,
# 8.21.0), so --retry-max-time keeps retries to a quick failure, a 5xx, and
# each download gets what is left of 100 s, less 12 for unpacking and
# checking. Exit 28 is curl's own timeout code.
DEADLINE=$((SECONDS + 100))
download() { # <url> <dest>
    local left=$((DEADLINE - SECONDS - 12))
    ((left >= 10)) || return 28
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --proto '=https' --proto-redir '=https' --retry 2 --retry-max-time 10 \
            --connect-timeout 10 --max-time "$left" -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
        # wget's --timeout bounds each stalled read, not the download, so
        # timeout holds it to the deadline; 126 or 127, timeout would not
        # run, retries it bare.
        local rc=0
        timeout "$left" wget -q --https-only --tries=1 --timeout=20 -O "$2" "$1" || rc=$?
        [[ $rc -eq 124 ]] && return 28
        [[ $rc -eq 126 || $rc -eq 127 ]] || return "$rc"
        wget -q --https-only --tries=1 --timeout=20 -O "$2" "$1"
    else
        return 127
    fi
}

sha256_of() {
    local out
    if command -v sha256sum >/dev/null 2>&1; then
        out=$(sha256sum "$1") || return 1
    elif command -v shasum >/dev/null 2>&1; then
        out=$(shasum -a 256 "$1") || return 1
    else
        return 127
    fi
    printf '%s' "${out%% *}"
}

# unpacked <dir> <file>: the path of <file> at the top of <dir> or one
# folder down, where a tarball unpacks (uv-<target>/uv).
unpacked() {
    local d
    for d in "$1" "$1"/*; do
        [[ -f $d/$2 ]] && printf '%s' "$d/$2" && return 0
    done
    return 1
}

# fetch <tool>: sets WHY on failure, and KEPT when the download could not
# replace a copy already in bin/, which then stands.
fetch() {
    local tool=$1 tmp file got name src rc
    WHY=
    KEPT=0
    if ! lock_row "$tool"; then
        WHY="no pinned build for $OS-$ARCH"
        return 1
    fi
    if pinned_present "$tool"; then
        return 0
    fi
    [[ -d $DATA/tmp ]] && find "$DATA/tmp" -mindepth 1 -maxdepth 1 -mmin +10 -exec rm -rf {} + 2>/dev/null
    tmp=$DATA/tmp/$$-$tool
    rm -rf "$tmp"
    if ! mkdir -p "$tmp" "$BIN" 2>/dev/null; then
        WHY="cannot create $tmp"
        return 1
    fi
    file=$tmp/${URL##*/}
    download "$URL" "$file"
    rc=$?
    if [[ $rc -eq 127 ]]; then
        WHY="neither curl nor wget is on PATH"
    elif [[ $rc -ne 0 ]]; then
        WHY="the download failed (exit $rc): $URL"
    elif ! got=$(sha256_of "$file"); then
        WHY="no sha256sum or shasum to check it with"
    elif [[ $got != "$SHA" ]]; then
        WHY="its SHA-256 did not match tools.lock, so it was discarded"
    fi
    if [[ -n $WHY ]]; then
        rm -rf "$tmp"
        return 1
    fi
    case "$file" in
        *.tar.gz) tar -xzf "$file" -C "$tmp" 2>/dev/null || WHY="tar could not unpack ${file##*/}" ;;
        *.zip) unzip -q -o "$file" -d "$tmp" 2>/dev/null || WHY="unzip could not unpack ${file##*/}" ;;
        *) mv -f "$file" "$tmp/$tool$EXE" ;;
    esac
    # Every binary runs before any moves: uvx finds uv beside itself, so a
    # uvx checked after uv left the folder exits non-zero (2026-11-18).
    for name in $(binaries_of "$tool"); do
        [[ -n $WHY ]] && break
        if ! src=$(unpacked "$tmp" "$name$EXE"); then
            WHY="${file##*/} holds no $name$EXE"
        elif ! chmod +x "$src" 2>/dev/null || ! "$src" --version >/dev/null 2>&1; then
            WHY="the downloaded $name$EXE would not run, perhaps blocked by antivirus"
        fi
    done
    for name in $(binaries_of "$tool"); do
        [[ -n $WHY ]] && break
        src=$(unpacked "$tmp" "$name$EXE")
        # A rename within the data folder: the binary appears whole or not
        # at all. A move that fails, on a permission or an antivirus lock,
        # keeps the copy already there, which may be an older version, so
        # no version stamp is written and the next session fetches again.
        if ! mv -f "$src" "$BIN/$name$EXE" 2>/dev/null; then
            if [[ -f $BIN/$name$EXE ]]; then
                KEPT=1
            else
                WHY="cannot write $BIN/$name$EXE"
            fi
        fi
    done
    rm -rf "$tmp"
    [[ -z $WHY ]] || return 1
    ((KEPT)) || printf '%s\n' "$VERSION" >"$BIN/.$tool.version" 2>/dev/null
    return 0
}

# gh_signed_in: bounded, retried bare where timeout cannot run (126, 127) or
# is Windows' TIMEOUT.EXE (1); `gh auth token` is safe to repeat.
gh_signed_in() {
    local rc=0
    timeout 10 gh auth token >/dev/null 2>&1 || rc=$?
    [[ $rc -eq 1 || $rc -eq 126 || $rc -eq 127 ]] || return "$rc"
    gh auth token >/dev/null 2>&1
}

opted_out() {
    case "${CLAUDE_PLUGIN_OPTION_FETCH:-true}" in
        false | False | FALSE | 0 | no) return 0 ;;
        *) return 1 ;;
    esac
}

LINES=
USED_BIN=0
FETCHED=0
add() { LINES="$LINES- $1"$'\n'; }

for TOOL in jq uv; do
    FOUND=$(type -P "$TOOL" 2>/dev/null) && [[ $(to_posix "$FOUND") != "$BIN/"* ]] && continue
    VERSION=
    if lock_row "$TOOL" && pinned_present "$TOOL"; then
        USED_BIN=1
        continue
    fi
    if opted_out; then
        add "$TOOL is not on PATH, and the toolchain plugin's fetch option is off: install it with $(install_line "$TOOL")"
        continue
    fi
    if fetch "$TOOL"; then
        USED_BIN=1
        FETCHED=1
        if ((KEPT)); then
            add "downloaded $TOOL $VERSION, its SHA-256 checked, but could not replace the copy already in $BIN, perhaps held by another session or an antivirus scan, or not writable; that copy, perhaps an older version, stays for now, and the next session tries again"
            continue
        fi
        NOTE="fetched $TOOL $VERSION into $BIN, its SHA-256 checked; the Bash tool finds it there"
        [[ $OS == windows ]] && NOTE="$NOTE, PowerShell does not, so to have it everywhere: $(install_line "$TOOL")"
        add "$NOTE"
    else
        add "$TOOL is not on PATH and was not fetched: $WHY. Install it with $(install_line "$TOOL")"
    fi
done

if ! type -P gh >/dev/null 2>&1; then
    add "gh is not on PATH: install it with $(install_line gh), then run gh auth login"
else
    gh_signed_in
    case $? in
        0) ;;
        124) add "gh did not answer gh auth token within 10 seconds, so whether it is signed in was not checked" ;;
        126 | 127) add "gh is on PATH but would not run: reinstall it with $(install_line gh)" ;;
        *) add "gh is not signed in: run gh auth login" ;;
    esac
fi

if [[ $USED_BIN -eq 1 && -n ${CLAUDE_ENV_FILE:-} ]]; then
    # shellcheck disable=SC2016 # $PATH is for the Bash tool to expand
    printf 'export PATH="$PATH":%q\n' "$BIN" >>"$CLAUDE_ENV_FILE" 2>/dev/null
fi

[[ -n $LINES ]] || exit 0

json_str() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\r'/}
    s=${s//$'\n'/\\n}
    s=${s//$'\t'/\\t}
    printf '"%s"' "$s"
}

LINES=${LINES%$'\n'}
CONTEXT="toolchain plugin, at session start:"$'\n'"$LINES"$'\n'"Skills of the plugins that depend on it run these tools; where one is missing, name its install line rather than retry the skill's script."
printf '{'
if [[ $SOURCE != compact || $FETCHED -eq 1 ]]; then
    printf '"systemMessage":%s,' "$(json_str "toolchain:"$'\n'"$LINES")"
fi
printf '"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$(json_str "$CONTEXT")"
exit 0
