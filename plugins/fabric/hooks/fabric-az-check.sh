#!/usr/bin/env bash
# fabric-az-check.sh — SessionStart hook, shipped in the fabric plugin's
# hooks/hooks.json: says at session start when the Azure CLI is missing or
# signed out, since the fabric skills send their Fabric and Graph requests
# through `az rest`, so a session hears of it before a call fails.
#
# WHY HERE AND NOT IN TOOLCHAIN. The toolchain plugin checks gh for every
# plugin that depends on it, but plugins that never call az depend on it
# too, git among them. A check there would speak in their sessions, and at
# every session start on a machine whose Claude Code points AZURE_CONFIG_DIR
# at a folder with no login. Here it speaks only where fabric is enabled
# (the user's call, 2026-11-20).
#
# WHAT IT CHECKS. az on PATH, else the install line, never fetched: the
# Azure CLI is an installer, not one binary to pin by checksum. Signed in
# means what `az account show` reads: a subscription marked
# "isDefault": true in <config dir>/azureProfile.json, the config dir being
# AZURE_CONFIG_DIR, else ~/.azure, which on Windows is under USERPROFILE,
# as Python's expanduser reads it there (Azure CLI 2.90.0 source:
# _environment.py get_config_dir, core __init__.py, _profile.py
# get_subscription, read 2026-11-20). An AZURE_CONFIG_DIR set but empty is
# no fallback: knack's CLIConfig takes the variable as it is, and every az
# command then fails, `FileNotFoundError ... ''` (observed 2026-11-20, az
# 2.90.0), so that is a message of its own. It reads that file itself
# rather than run az: `az account show` and `az --version` each took about 3.1 s here
# (2026-11-20), at every session start, and the file read starts nothing.
# Like `az account show`, it never reads a token, so an expired refresh
# token or a Conditional Access refusal still passes; it also skips az's
# filter on the active cloud.
#
# NO TENANT. It reports what az reads in this hook's environment, which is
# Claude Code's. A machine keeping one config folder per tenant may give the
# Bash tool's shell another, so where AZURE_CONFIG_DIR is set the message
# names that folder. A login in the wrong tenant passes, as it would for
# `az account show`.
#
# QUIET WHEN ALL IS WELL. With az present and signed in it prints nothing.
# Else one JSON object: systemMessage, for the user, and additionalContext,
# the same for Claude, so a skill whose az call fails can say why. After a
# compaction only the context is repeated, as toolchain.sh does.
#
# NEVER BLOCKS. SessionStart cannot block, and every path exits 0.
#
# RUNS UNDER BASH, WHATEVER `sh` IS. hooks.json starts it as `sh`, dash on
# Debian and Ubuntu, so the first lines, POSIX alone, re-run it under bash,
# as fabric-edit-gate.sh does. On Windows with no Git for Windows the
# command runs in PowerShell, where `sh` is not found: a `hook error` notice
# each session, and nothing checked.

if [ -z "${BASH_VERSION:-}" ]; then
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    exit 0
fi
set -uo pipefail

# Read stdin by the builtin, which spawns nothing, where $(cat) would.
INPUT=
IFS= read -r -d '' INPUT || true
SOURCE=startup
[[ $INPUT =~ \"source\"[[:space:]]*:[[:space:]]*\"([a-z]+)\" ]] && SOURCE=${BASH_REMATCH[1]}

case "${OSTYPE:-}" in
    linux*) OS=linux ;;
    darwin*) OS=macos ;;
    msys* | cygwin* | win32*) OS=windows ;;
    *) OS=other ;;
esac

# Install lines from Learn's Azure CLI install pages (read 2026-11-20): no
# one Linux command covers every distribution, so Linux gets the page.
install_line() {
    case "$OS" in
        windows) echo 'winget install --exact --id Microsoft.AzureCLI' ;;
        macos) echo 'brew install azure-cli' ;;
        linux) echo 'the steps for your distribution at https://learn.microsoft.com/cli/azure/install-azure-cli-linux' ;;
        *) echo 'the steps at https://learn.microsoft.com/cli/azure/install-azure-cli' ;;
    esac
}

LINE=
if ! type -P az >/dev/null 2>&1; then
    LINE="az is not on PATH: install it with $(install_line), then run az login"
elif [[ -n ${AZURE_CONFIG_DIR+set} && -z $AZURE_CONFIG_DIR ]]; then
    # knack reads the variable by os.environ.get, with no 'or', so an empty
    # value is az's config dir, and ensure_dir('') fails every command.
    LINE="AZURE_CONFIG_DIR is set but empty in this session, which makes every az command fail: unset it, or point it at a folder that is signed in"
else
    CONFIG_DIR=${AZURE_CONFIG_DIR:-}
    if [[ -z $CONFIG_DIR ]]; then
        HOME_DIR=${HOME:-}
        [[ $OS == windows && -n ${USERPROFILE:-} ]] && HOME_DIR=$USERPROFILE
        CONFIG_DIR=$HOME_DIR/.azure
    fi
    # Git Bash opens C:/x as it is; only the backslashes need turning.
    PROFILE=${CONFIG_DIR//\\//}/azureProfile.json
    TEXT=
    [[ -r $PROFILE ]] && { IFS= read -r -d '' TEXT <"$PROFILE" || true; }
    if [[ ! $TEXT =~ \"isDefault\"[[:space:]]*:[[:space:]]*true ]]; then
        if [[ -n ${AZURE_CONFIG_DIR:-} ]]; then
            LINE="az is not signed in for the folder AZURE_CONFIG_DIR names in this session, $AZURE_CONFIG_DIR: run az login with that variable set, or point it at a folder that is signed in"
        else
            LINE="az is not signed in: run az login"
        fi
    fi
fi

[[ -n $LINE ]] || exit 0

json_str() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\r'/}
    s=${s//$'\n'/\\n}
    s=${s//$'\t'/\\t}
    printf '"%s"' "$s"
}

CONTEXT="fabric plugin, at session start: $LINE. The fabric skills send their Fabric and Graph requests through az rest; where one fails, name this rather than retry it."
printf '{'
[[ $SOURCE == compact ]] || printf '"systemMessage":%s,' "$(json_str "fabric: $LINE")"
printf '"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$(json_str "$CONTEXT")"
exit 0
