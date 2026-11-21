<#
.SYNOPSIS
    List what a private GitHub repo would expose once public, and count
    the identity denylist's terms and gitleaks' findings in each part.
    Reads only, and prints no term.

.DESCRIPTION
    Going public shows everyone the code and every commit the remote
    serves, the issues and pull requests with their comments, the
    discussions, wiki, releases and Actions logs, and disables every push
    ruleset (GitHub's "Setting repository visibility", read 2026-11-04).
    The settings the switch leaves are audit-repo.ps1's, which this script
    does not judge: the skill runs that one after it, with -AsPublic.

    WHAT IS READ, each source printed as a count:
      history   every commit reachable from a ref the remote lists, as
                git ls-remote origin prints them: branches, tags and pull
                request refs. Read from the clone: each changed line and
                path, each message, author, committer and annotated tag,
                and each ref's name. A ref whose commit the clone lacks is
                counted unread, and the fetch that fixes it printed.
      secrets   gitleaks git over the clone's git directory, redacted, its findings split
                into commits the remote serves and commits only the clone
                holds, which the switch exposes to no one. Its default
                rules alone: the repo's own .gitleaks.toml, .gitleaksignore
                and gitleaks:allow comments were decided while it was
                private, and none is honoured.
      about     the repo's description, homepage and topics.
      addresses each author, committer and tagger address that is someone's
                mailbox, not GitHub's private noreply or any noreply
                address, printed where it holds no term.
      threads   issues and pull requests, closed ones too, with their
                comments, review comments and reviews, the titles each was
                renamed from and a body's edit history, through gh.
      and       discussions, the wiki, cloned into a temp folder, and
                releases, where the repo has them; the Actions runs and
                unexpired artifacts, counted; the push rulesets; each
                linked project's own visibility, which the switch leaves.

    THE DENYLIST is ~/.config/identity-denylist.txt, or IDENTITY_DENYLIST,
    parsed as the list's other readers parse it, so there is one list
    and one reading of it: this script's suite fails when they
    differ. No term is printed, since the list is itself the leak, nor
    any text holding one: a tag, a title or an address holding one prints
    as a placeholder, and any other line holding one, such as a failed
    call's error, is withheld whole. A missing denylist, or one with no
    active term, is a warning: every other source is still read, and no
    all-clear on a term prints, so a scan that never looked for one
    cannot exit 0. Its
    exempt: lines name no exception here, so a client's own repo hits on
    its own name; point IDENTITY_DENYLIST at a copy without it.

    WHAT IT DOES NOT READ: an edited comment's earlier versions, which any
    reader can open; labels, milestones and commit comments; a binary
    file's content, though its name is read;
    Actions logs and artifacts, and release assets; GitHub Pages and
    packages; and a commit no ref lists that GitHub still serves by its
    SHA, such as the head a force push replaced, which a pull request's
    timeline links.

    THE ACCOUNT IS -Login, PINNED HERE, where the caller names one, as
    audit-repo.ps1's is, whose header says why a caller's own pin cannot
    reach this script: its token is minted by gh auth token --user,
    whatever GH_TOKEN held, and the scan stops unless gh then acts as it.
    Without -Login it reads as gh answers, and names that account first.

    Exit codes: 0 every source read and nothing found; 1 a hit, an
    exposure to decide on, a source unread, or no denylist; 2 the scan
    could not run (gh or git missing, no token for -Login or gh acting as
    another account, the repo unreadable, a clone of another repo, or a
    read that failed partway).

.PARAMETER Repo
    owner/name. Defaults to the origin of the clone. Given, it must be
    that origin: the history read is the clone's.

.PARAMETER Clone
    A folder inside the clone whose history is read. Defaults to the
    working directory.

.PARAMETER Login
    The GitHub account to read as, pinned for the run: for an
    organization's repo, one with admin rights there. Left out, gh's own
    account answers; given empty, the scan stops.

.EXAMPLE
    pwsh -NoProfile -NonInteractive -File <skill>/scripts/going-public.ps1

.EXAMPLE
    pwsh -NoProfile -NonInteractive -File <skill>/scripts/going-public.ps1 -Repo <owner>/<repo> -Clone C:\src\repo -Login <admin>
#>
[CmdletBinding()]
param(
    [string]$Repo,
    [string]$Clone,
    [string]$Login
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Hits = 0
$script:Warnings = 0

# Every line printed passes this gate once the denylist is parsed: a
# message built from text the scan read, such as a failed call's error or
# a tool's own output, is withheld whole where it holds a term.
$script:AnyTerm = $null
function Protect-Text {
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ($script:AnyTerm -and $Text -and $script:AnyTerm.IsMatch($Text)) {
        return '<a line holding a denylist term, withheld>'
    }
    return $Text
}
function Step { param($m) Write-Host "`n=== $(Protect-Text "$m")" -ForegroundColor Cyan }
function Ok { param($m) Write-Host "  [ok]    $(Protect-Text "$m")" -ForegroundColor Green }
# An all-clear on the denylist's terms, printed only where one was read:
# with none, a single warning says no part was scanned for a term.
function OkTerm { param($m) if ($script:AnyTerm) { Ok $m } }
function Info { param($m) Write-Host "  [INFO]  $(Protect-Text "$m")" }
function Write-Reason {
    param($Why, $Fix)
    if ($Why) { Write-Host "          why: $(Protect-Text "$Why")" }
    if ($Fix) { Write-Host "          fix: $(Protect-Text "$Fix")" }
}
# A hit is text the switch would publish that holds a term or a secret.
function Hit {
    param($m, $Why, $Fix)
    Write-Host "  [HIT]   $(Protect-Text "$m")" -ForegroundColor Red
    Write-Reason -Why $Why -Fix $Fix
    $script:Hits++
}
# A warning is an exposure to decide on, or a source left unread.
function Warn {
    param($m, $Why, $Fix)
    Write-Host "  [WARN]  $(Protect-Text "$m")" -ForegroundColor Yellow
    Write-Reason -Why $Why -Fix $Fix
    $script:Warnings++
}
# Exit 2 rather than throw: a throw exits 1, which reads as findings.
function Exit-Scan {
    param($m)
    Write-Host "  [STOP]  $(Protect-Text "$m")" -ForegroundColor Red
    exit 2
}
trap { Exit-Scan "the scan stopped partway: $_" }

# No prompt may block a read: a credential helper asked for a wiki that
# does not exist would wait for a keyboard the agent shell does not have.
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

#region gh helpers
# gh writes UTF-8, and pwsh decodes a native command's output with the
# console's code page, so every call runs under UTF-8, as audit-repo.ps1's do.
function Invoke-Gh {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$GhArgs)
    $consoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    try {
        $out = gh @GhArgs 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $consoleEncoding
    }
    # A failed call can print the body it read before its error, as gh
    # 2.103.3 printed a paginated GraphQL answer ahead of its "gh:" line
    # (2026-11-04), and that body is the very text scanned. So a
    # failure is told by gh's own lines alone: stderr, or a stdout line
    # that opens "gh:", as a stand-in prints its errors; else the exit code.
    $stderr = @($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    $stdout = @($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
            ForEach-Object { "$_" -split '\r?\n' })
    # Never empty on a failure: a caller reads an empty one as a success.
    $stderrText = ($stderr -join ' ').Trim()
    $ghLines = @($stdout -match '^gh: ')
    $failure = if ($exitCode -eq 0) { '' }
    elseif ($stderrText) { $stderrText }
    elseif ($ghLines.Count -gt 0) { $ghLines -join ' ' }
    else { "gh exited $exitCode" }
    [pscustomobject]@{ ExitCode = $exitCode; Text = ($stdout -join "`n"); Failure = $failure }
}

# -Paginate reads every page, as one JSON array of the pages.
function Invoke-GhApi {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Endpoint, [switch]$Paginate)
    $ghArgs = @('api', '-X', 'GET', $Endpoint, '-H', 'Accept: application/vnd.github+json')
    if ($Paginate) { $ghArgs += @('--paginate', '--slurp') }
    Invoke-Gh -GhArgs $ghArgs
}

# GraphQL goes by POST, but a query only reads, and no mutation is sent.
# -Paginate needs the query to take $endCursor and name one pageInfo.
function Invoke-GhQuery {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Query, [hashtable]$Variables = @{}, [switch]$Paginate)
    $ghArgs = @('api', 'graphql', '-f', "query=$Query")
    foreach ($key in $Variables.Keys) { $ghArgs += @('-f', "$key=$($Variables[$key])") }
    if ($Paginate) { $ghArgs += @('--paginate', '--slurp') }
    Invoke-Gh -GhArgs $ghArgs
}

# A key's value, or $null where the key is absent: strict mode throws on
# an absent key, and GitHub leaves some out.
function Get-Key {
    param($Map, [string]$Key)
    if ($Map -is [System.Collections.IDictionary] -and $Map.Contains($Key)) { return $Map[$Key] }
    return $null
}

function Get-List {
    param($Map, [string]$Key)
    return @(Get-Key $Map $Key | Where-Object { $null -ne $_ })
}

# Every item of a paginated REST list: the pages, each an array, flattened.
function Read-ItemList {
    param([Parameter(Mandatory)][string]$Endpoint)
    $read = Invoke-GhApi -Endpoint $Endpoint -Paginate
    if ($read.ExitCode -ne 0) { return [pscustomobject]@{ Items = @(); Error = $read.Failure } }
    # ConvertFrom-Json unrolls the outer array alone, so each page arrives whole.
    $pages = @($read.Text | ConvertFrom-Json -AsHashtable)
    $items = @(foreach ($page in $pages) { foreach ($item in @($page)) { if ($null -ne $item) { $item } } })
    [pscustomobject]@{ Items = $items; Error = $null }
}
#endregion

#region git helpers
# git under UTF-8 too, stdout and stderr apart; -InputLines feeds its stdin,
# which pwsh writes while it reads, so a long list cannot stall the pipe.
function Invoke-Git {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$GitArgs, [string[]]$InputLines)
    $consoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    try {
        $all = if ($PSBoundParameters.ContainsKey('InputLines')) {
            $InputLines | git @GitArgs 2>&1
        } else {
            git @GitArgs 2>&1
        }
        $exitCode = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $consoleEncoding
    }
    $errors = @($all | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    $lines = @($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    [pscustomobject]@{ ExitCode = $exitCode; Lines = $lines; Error = ($errors -join "`n") }
}

function Get-OriginRepo {
    param([string]$Url)
    if ($Url -notmatch 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/]+?)(\.git)?/?$') { return $null }
    return "$($Matches['owner'])/$($Matches['name'])"
}
#endregion

#region Pre-flight
foreach ($tool in @('gh', 'git')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { Exit-Scan "$tool not found on PATH" }
}
# The denylist first, so the gate is armed before any refusal names a
# clone, a path or a repo. It is the user's own, so a machine may hold
# none: the scan then reads every other source, warns once that no part
# was scanned for a term, and so never exits 0.
$listPath = if ($env:IDENTITY_DENYLIST) { $env:IDENTITY_DENYLIST } else { Join-Path $HOME '.config/identity-denylist.txt' }
$terms = @()
$wordTerms = @()
$script:NoList = $null
if (Test-Path -LiteralPath $listPath -PathType Leaf) {
    # Kept equal, line for line, to the parse of the list's other readers;
    # this script's suite fails when they differ.
    $listLines = @(Get-Content -LiteralPath $listPath | ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') -and -not $_.ToLowerInvariant().StartsWith('exempt:') })
    $terms = @($listLines | Where-Object { -not $_.ToLowerInvariant().StartsWith('word:') })
    $wordTerms = @($listLines | Where-Object { $_.ToLowerInvariant().StartsWith('word:') } |
            ForEach-Object { $_.Substring(5).Trim() } | Where-Object { $_ } |
            ForEach-Object { [regex]::new("(?<![0-9A-Za-z])$([regex]::Escape($_))(?![0-9A-Za-z])", 'IgnoreCase, CultureInvariant') })
    if ($terms.Count + $wordTerms.Count -eq 0) { $script:NoList = "the identity denylist at $listPath holds no active terms" }
} else {
    $script:NoList = "no readable identity denylist at $listPath"
}
# One pattern for every term, plain ones as literal text, word: ones where
# no ASCII letter or digit touches them, so each line costs one match.
$anyTerm = $null
if (-not $script:NoList) {
    $termPattern = @(@($terms | ForEach-Object { [regex]::Escape($_) }) + @($wordTerms | ForEach-Object { $_.ToString() })) -join '|'
    $anyTerm = [regex]::new($termPattern, 'IgnoreCase, CultureInvariant, Compiled')
}
$script:AnyTerm = $anyTerm

function Test-Term {
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if (-not $anyTerm -or [string]::IsNullOrEmpty($Text)) { return $false }
    return $anyTerm.IsMatch($Text)
}
# A name to print, or a placeholder where printing it would print a term.
function Format-Safe {
    param([AllowNull()][AllowEmptyString()][string]$Text, [string]$Kind)
    if (Test-Term $Text) { return "<a $Kind holding a denylist term>" }
    return $Text
}
# At most 15 ids, then how many more.
function Format-IdList {
    param([string[]]$Ids)
    $shown = @($Ids | Select-Object -First 15) -join ' '
    if ($Ids.Count -gt 15) { $shown += " and $($Ids.Count - 15) more" }
    return $shown
}

# Each refusal names what it read through Format-Safe, so a path or a repo
# holding a term still says which refusal fired.
$startDir = if ($Clone) { $Clone } else { (Get-Location -PSProvider FileSystem).ProviderPath }
$topRead = Invoke-Git -GitArgs @('-C', $startDir, 'rev-parse', '--show-toplevel')
if ($topRead.ExitCode -ne 0 -or $topRead.Lines.Count -eq 0) {
    Exit-Scan "$(Format-Safe $startDir 'path') is in no git clone: the history read is a clone's, so run from one or pass -Clone"
}
$cloneRoot = $topRead.Lines[0]
# The configured URL, not git remote get-url, which applies insteadOf.
$urlRead = Invoke-Git -GitArgs @('-C', $cloneRoot, 'config', '--get', 'remote.origin.url')
$originRepo = if ($urlRead.ExitCode -eq 0 -and $urlRead.Lines.Count -gt 0) { Get-OriginRepo $urlRead.Lines[0] } else { $null }
if (-not $originRepo) { Exit-Scan "the clone at $(Format-Safe $cloneRoot 'path') has no GitHub origin remote" }
if (-not $Repo) {
    $Repo = $originRepo
} elseif ($Repo -ne $originRepo) {
    Exit-Scan ("the clone at $(Format-Safe $cloneRoot 'path') is $(Format-Safe $originRepo 'repo')'s, " +
        "not $(Format-Safe $Repo 'repo')'s: the history read would be another repo's")
}
if ($Repo -notmatch '^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$') { Exit-Scan "-Repo takes owner/name, not '$(Format-Safe $Repo 'repo')'." }
$originUrl = $urlRead.Lines[0]

# The account; see the header. Before any read, so a refused token reads
# nothing. The token is stdout's first line, which Invoke-Gh keeps apart
# from stderr, and is never printed.
if ($PSBoundParameters.ContainsKey('Login')) {
    if ([string]::IsNullOrWhiteSpace($Login)) {
        Exit-Scan '-Login names no account; leave it out to read as gh''s own.'
    }
    $mint = Invoke-Gh -GhArgs @('auth', 'token', '--user', $Login)
    $token = if ($mint.ExitCode -eq 0) { "$(@($mint.Text -split '\r?\n') | Select-Object -First 1)".Trim() } else { '' }
    if (-not $token) {
        $why = if ($mint.Failure) { $mint.Failure } else { 'gh printed no token' }
        Exit-Scan ("gh has no token for $(Format-Safe $Login 'login'), the account -Login names, " +
            "so nothing is read: $(Format-Safe $why 'gh error')")
    }
    $env:GH_TOKEN = $token
}

$user = Invoke-GhApi -Endpoint 'user'
# Not $login: a variable's name is case-blind, so that is the -Login parameter.
$actingAs = if ($user.ExitCode -eq 0) { ($user.Text | ConvertFrom-Json -AsHashtable)['login'] } else { '<unknown>' }
# Case-blind, as GitHub's logins are and as -ne compares.
if ($PSBoundParameters.ContainsKey('Login') -and $actingAs -ne $Login) {
    # A revoked token fails the read: name gh's error, not only <unknown>.
    $detail = if ($user.ExitCode -ne 0) { " gh api user failed: $(Format-Safe $user.Failure 'gh error')" } else { '' }
    Exit-Scan ("gh acts as $(Format-Safe $actingAs 'login'), but -Login names $(Format-Safe $Login 'login'), " +
        "so nothing is read.$detail")
}
$repoRead = Invoke-GhApi -Endpoint "repos/$Repo"
if ($repoRead.ExitCode -ne 0) {
    Exit-Scan ("gh, acting as $(Format-Safe $actingAs 'login'), cannot read $(Format-Safe $Repo 'repo') " +
        "-- the wrong account, or no such repo: $(Format-Safe $repoRead.Failure 'gh error')")
}
$repoJson = $repoRead.Text | ConvertFrom-Json -AsHashtable
$visibility = Get-Key $repoJson 'visibility'
$repoOwner, $repoName = $Repo -split '/', 2
#endregion

Step "$Repo -- going public -- read as $actingAs"
$listCount = if ($script:NoList) { 'none' } else { "$($terms.Count + $wordTerms.Count) term(s)" }
Info "visibility $visibility; clone $cloneRoot; denylist $listCount"
if ($script:NoList) {
    Warn "$($script:NoList), so no part was scanned for a client's or an employer's name" `
        -Why 'the switch publishes every part this lists, and only the denylist names what must not be in one' `
        -Fix 'keep one at ~/.config/identity-denylist.txt, or point IDENTITY_DENYLIST at one, and run again'
}
if ($visibility -eq 'public') {
    Warn "$Repo is public already: what this lists is exposed now" `
        -Why 'a rewrite or a delete now leaves what forks, caches and clones already hold' `
        -Fix "recreate-repo, for a leak already pushed"
}
# Each field by name, since the term itself cannot be printed.
$aboutFields = [ordered]@{
    description = "$(Get-Key $repoJson 'description')"
    homepage    = "$(Get-Key $repoJson 'homepage')"
    topics      = (@(Get-List $repoJson 'topics') -join "`n")
}
$aboutHits = @($aboutFields.Keys | Where-Object { Test-Term $aboutFields[$_] })
if ($aboutHits.Count -gt 0) {
    Hit "the About panel holds a denylist term in its $($aboutHits -join ', ')" `
        -Fix "gh repo edit $Repo --description '<text>' --homepage '<url>' --remove-topic <topic>"
} else { OkTerm 'the About panel holds no denylist term' }

#region History
# Each history scan prints its own lines; $Revs are the tips to walk, or
# none for every ref of a mirror.
function Invoke-HistoryScan {
    param([Parameter(Mandatory)][string]$Root, [string[]]$Revs, [Parameter(Mandatory)][string]$Label)
    $walk = if ($Revs) { @('--stdin') } else { @('--all') }
    $feed = if ($Revs) { @{ InputLines = $Revs } } else { @{} }

    # Messages and people, one record per commit.
    $metaRead = Invoke-Git -GitArgs (@('-C', $Root, 'log') + $walk +
        @('--no-color', '--format=%x1e%h%x1f%an%x1f%ae%x1f%cn%x1f%ce%x1f%B')) @feed
    if ($metaRead.ExitCode -ne 0) { throw "git log failed in ${Root}: $($metaRead.Error)" }
    $records = @(($metaRead.Lines -join "`n") -split [char]0x1e | Where-Object { $_.Trim() })
    $messageHits = [System.Collections.Generic.List[string]]::new()
    $peopleHits = [System.Collections.Generic.List[string]]::new()
    $addresses = [ordered]@{}
    foreach ($record in $records) {
        $fields = $record -split [char]0x1f, 6
        if ($fields.Count -lt 6) { continue }
        $sha = $fields[0].Trim()
        if (Test-Term $fields[5]) { $messageHits.Add($sha) }
        if (Test-Term ($fields[1..4] -join ' ')) { $peopleHits.Add($sha) }
        foreach ($address in @($fields[2], $fields[4])) {
            if (-not $address) { continue }
            if (-not $addresses.Contains($address)) { $addresses[$address] = [System.Collections.Generic.HashSet[string]]::new() }
            $null = $addresses[$address].Add($sha)
        }
    }
    Info "$Label`: $($records.Count) commit(s) read"

    # Changed lines and paths, streamed: a repo's whole patch history may
    # not fit a string. -U0 reads changed lines alone, deleted files
    # included, and each merge is read against its first parent.
    $changeHits = [System.Collections.Generic.HashSet[string]]::new()
    $binaries = 0
    $current = ''
    $patchErrors = [System.Collections.Generic.List[string]]::new()
    # quotepath off: git otherwise prints a non-ASCII path as octal escapes,
    # "a/caf\303\251.txt", which no term with an accent can match.
    $patchArgs = @('-C', $Root, '-c', 'core.quotepath=off', 'log') + $walk + @('-p', '-U0', '--no-color', '--no-ext-diff', '--no-textconv',
        '--no-renames', '--diff-merges=first-parent', '--format=%x1e%h')
    # ForEach-Object runs its block in this scope, so $current and $binaries
    # carry from line to line.
    $readLine = {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $patchErrors.Add("$_"); return }
        $line = [string]$_
        if ($line.Length -gt 0 -and $line[0] -eq [char]0x1e) { $current = $line.Substring(1); return }
        if ($line.StartsWith('Binary files ')) { $binaries++ }
        if ($anyTerm -and $anyTerm.IsMatch($line)) { $null = $changeHits.Add($current) }
    }
    $consoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    try {
        if ($Revs) { $Revs | git @patchArgs 2>&1 | ForEach-Object $readLine }
        else { git @patchArgs 2>&1 | ForEach-Object $readLine }
        $patchExit = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $consoleEncoding
    }
    if ($patchExit -ne 0) { throw "git log -p failed in ${Root}: $($patchErrors -join ' ')" }

    # A force push is no remedy: pull request refs pin every commit a pull
    # request touched, and GitHub serves an unreachable commit by its SHA
    # until it collects it (recreate-repo's references/pushed-leaks.md).
    $rewrite = ('rewrite it out with git filter-repo{0}, then publish that history as a new repo by ' +
        'recreate-repo''s route: a force push leaves the old commits served by SHA and by pull request refs')
    if ($changeHits.Count -gt 0) {
        Hit "$Label`: $($changeHits.Count) commit(s) add or remove a line or path holding a denylist term: $(Format-IdList @($changeHits))" `
            -Why 'every version of every file the remote serves turns readable, a deleted one too' -Fix ($rewrite -f '')
    } else { OkTerm "$Label`: no changed line or path holds a denylist term" }
    if ($messageHits.Count -gt 0) {
        Hit "$Label`: $($messageHits.Count) commit message(s) hold a denylist term: $(Format-IdList $messageHits)" `
            -Why 'each message turns readable with its commit' -Fix ($rewrite -f '')
    } else { OkTerm "$Label`: no commit message holds a denylist term" }
    if ($peopleHits.Count -gt 0) {
        Hit "$Label`: $($peopleHits.Count) commit(s) name an author or committer holding a denylist term: $(Format-IdList $peopleHits)" `
            -Why 'each name and address turns readable with its commit' -Fix ($rewrite -f ' --mailmap')
    } else { OkTerm "$Label`: no author or committer holds a denylist term" }
    if ($binaries -gt 0) { Info "$Label`: $binaries binary change(s): each name read, the content not" }
    return $addresses
}

# Addresses that are no one's mailbox: an account's private noreply on
# GitHub, and any noreply or no-reply address, as a co-author trailer's
# tool or GitHub's web editor commits as.
function Test-NoReply {
    param([string]$Address)
    return ($Address -match '@users\.noreply\.github\.com$') -or ($Address -match '^no-?reply@')
}

function Write-AddressFinding {
    param([System.Collections.IDictionary]$Addresses, [string]$Label)
    $open = @($Addresses.Keys | Where-Object { -not (Test-NoReply $_) })
    if ($open.Count -eq 0) { Ok "$Label`: every author and committer address is a noreply one"; return }
    $commits = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($address in $open) { $commits.UnionWith($Addresses[$address]) }
    $shown = @($open | Where-Object { -not (Test-Term $_) })
    $held = $open.Count - $shown.Count
    $list = $shown -join ', '
    if ($held -gt 0) { $list = (@($list, "$held holding a denylist term") | Where-Object { $_ }) -join ', and ' }
    Warn "$Label`: $($open.Count) address(es) that are no noreply one, on $($commits.Count) commit(s): $list" `
        -Why 'every address in the history turns readable, and a crawler can collect it' `
        -Fix ('only a history rewrite changes it, published as a history hit says: git filter-repo --mailmap; ' +
            'for new commits, git config user.email <id>+<login>@users.noreply.github.com')
}

Step 'History the remote serves'
$shallow = Invoke-Git -GitArgs @('-C', $cloneRoot, 'rev-parse', '--is-shallow-repository')
if ($shallow.ExitCode -eq 0 -and $shallow.Lines.Count -gt 0 -and $shallow.Lines[0] -eq 'true') {
    Warn 'the clone is shallow: commits before its depth are unread' -Fix "git -C $cloneRoot fetch --unshallow"
}
$lsRemote = Invoke-Git -GitArgs @('-C', $cloneRoot, 'ls-remote', 'origin')
if ($lsRemote.ExitCode -ne 0) {
    Exit-Scan "git ls-remote origin failed, so which refs the remote serves is unknown: $($lsRemote.Error)"
}
$refs = @(foreach ($line in $lsRemote.Lines) {
        $parts = $line -split "`t", 2
        if ($parts.Count -eq 2 -and $parts[1] -ne 'HEAD') { [pscustomobject]@{ Sha = $parts[0]; Ref = $parts[1] } }
    })
$refNames = @($refs | ForEach-Object { $_.Ref -replace '\^\{\}$', '' } | Sort-Object -Unique)
$branchCount = @($refNames | Where-Object { $_.StartsWith('refs/heads/') }).Count
$tagCount = @($refNames | Where-Object { $_.StartsWith('refs/tags/') }).Count
$pullCount = @($refNames | Where-Object { $_.StartsWith('refs/pull/') }).Count
Info "the remote lists $($refNames.Count) ref(s): $branchCount branch(es), $tagCount tag(s), $pullCount pull request ref(s)"
$refHits = @($refNames | Where-Object { Test-Term $_ })
if ($refHits.Count -gt 0) {
    Hit "$($refHits.Count) ref name(s) the remote lists hold a denylist term" `
        -Why 'branch and tag names turn readable, and a pull request page keeps its branch name after a delete' `
        -Fix 'rename or delete each before the switch; a pull request ref is GitHub''s and goes only with the repo'
} else { OkTerm 'no ref name holds a denylist term' }

$shas = @($refs | ForEach-Object { $_.Sha } | Sort-Object -Unique)
$types = @{}
if ($shas.Count -gt 0) {
    $check = Invoke-Git -GitArgs @('-C', $cloneRoot, 'cat-file', '--batch-check') -InputLines $shas
    if ($check.ExitCode -ne 0) { throw "git cat-file failed: $($check.Error)" }
    foreach ($line in $check.Lines) {
        $parts = $line -split ' '
        if ($parts.Count -ge 2) { $types[$parts[0]] = $parts[1] }
    }
}
$missing = @($shas | Where-Object { -not $types.ContainsKey($_) -or $types[$_] -eq 'missing' })
if ($missing.Count -gt 0) {
    Warn "$($missing.Count) ref tip(s) the remote lists are not in this clone: the history behind them is unread" `
        -Fix ("git -C $cloneRoot fetch origin '+refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*' " +
            "'+refs/pull/*:refs/remotes/origin/pull/*', then run again")
}
$tips = @($shas | Where-Object { $types.ContainsKey($_) -and $types[$_] -in @('commit', 'tag') })

$historyAddresses = [ordered]@{}
$publicCommits = [System.Collections.Generic.HashSet[string]]::new()
if ($tips.Count -eq 0) {
    Info 'no commit to read: the remote lists no ref this clone holds'
} else {
    $revList = Invoke-Git -GitArgs @('-C', $cloneRoot, 'rev-list', '--stdin') -InputLines $tips
    if ($revList.ExitCode -ne 0) { throw "git rev-list failed: $($revList.Error)" }
    $publicCommits.UnionWith([string[]]@($revList.Lines))
    $historyAddresses = Invoke-HistoryScan -Root $cloneRoot -Revs $tips -Label 'history'
}

# An annotated tag is an object of its own, its message and tagger apart
# from the commit's.
$tagObjects = @($tips | Where-Object { $types[$_] -eq 'tag' })
$tagHits = 0
foreach ($tag in $tagObjects) {
    $tagRead = Invoke-Git -GitArgs @('-C', $cloneRoot, 'cat-file', 'tag', $tag)
    if ($tagRead.ExitCode -ne 0) { throw "git cat-file tag failed: $($tagRead.Error)" }
    if (Test-Term ($tagRead.Lines -join "`n")) { $tagHits++ }
    foreach ($line in $tagRead.Lines) {
        if ($line -match '^tagger .*<(?<address>[^>]*)>') {
            $address = $Matches['address']
            if (-not $historyAddresses.Contains($address)) { $historyAddresses[$address] = [System.Collections.Generic.HashSet[string]]::new() }
            $null = $historyAddresses[$address].Add($tag.Substring(0, 7))
        }
    }
}
if ($tagObjects.Count -gt 0) {
    if ($tagHits -gt 0) {
        Hit "$tagHits of $($tagObjects.Count) annotated tag(s) hold a denylist term in their message or tagger" `
            -Fix 'delete and recreate each tag before the switch, locally and on the remote'
    } else { OkTerm "no annotated tag holds a denylist term ($($tagObjects.Count) read)" }
}
if ($tips.Count -gt 0) { Write-AddressFinding -Addresses $historyAddresses -Label 'history' }
#endregion

#region Secrets
# gitleaks reads every local ref, the default for gitleaks git, so a
# finding is split by whether a ref the remote lists reaches its commit.
function Invoke-SecretScan {
    param([Parameter(Mandatory)][string]$Root, [System.Collections.Generic.HashSet[string]]$Served, [string]$Label)
    if (-not (Get-Command gitleaks -ErrorAction SilentlyContinue)) {
        Warn "$Label`: gitleaks not found on PATH, so no secret scan ran" -Fix 'winget install Gitleaks.Gitleaks'
        return
    }
    # The repo's own suppressions are decisions made while it was private,
    # so none is honoured: no .gitleaks.toml or GITLEAKS_CONFIG (a config of
    # gitleaks' default rules alone), no .gitleaksignore (an empty folder in
    # its place) and no gitleaks:allow comment. A token marked allow gave
    # 0 findings under the old flags, 2 under these (2026-11-04, 8.30.1).
    # gitleaks also reads <source>/.gitleaksignore whatever the ignore path
    # says, so its source is the git directory, where no working-tree file
    # sits: a fingerprinted token stayed dropped with the work tree as the
    # source, and was found with the git directory (8.30.1, 2026-11-04).
    $gitDirRead = Invoke-Git -GitArgs @('-C', $Root, 'rev-parse', '--absolute-git-dir')
    if ($gitDirRead.ExitCode -ne 0 -or $gitDirRead.Lines.Count -eq 0) {
        throw "git rev-parse --absolute-git-dir failed in ${Root}: $($gitDirRead.Error)"
    }
    $scanSource = $gitDirRead.Lines[0]
    $stem = Join-Path ([System.IO.Path]::GetTempPath()) "going-public-$([guid]::NewGuid().ToString('N'))"
    $report = "$stem.json"
    $leaksConfig = "$stem.toml"
    $noIgnore = "$stem-ignore"
    try {
        Set-Content -LiteralPath $leaksConfig -Value "[extend]`nuseDefault = true" -NoNewline
        $null = New-Item -ItemType Directory -Path $noIgnore
        $consoleEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
        try {
            $out = gitleaks git --no-banner --no-color --redact --exit-code 0 --log-level error `
                --ignore-gitleaks-allow --config $leaksConfig --gitleaks-ignore-path $noIgnore `
                --report-format json --report-path $report $scanSource 2>&1
            $leaksExit = $LASTEXITCODE
        } finally {
            [Console]::OutputEncoding = $consoleEncoding
        }
        if ($leaksExit -ne 0 -or -not (Test-Path -LiteralPath $report)) {
            Warn "$Label`: gitleaks exited $leaksExit, so the secret scan is unread: $(@($out) -join ' ')"
            return
        }
        $raw = Get-Content -LiteralPath $report -Raw
        # The whole if inside @(): an empty array assigned from a bare if
        # unrolls to $null, whose .Count strict mode refuses.
        $findings = @(if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $raw | ConvertFrom-Json -AsHashtable | Where-Object { $null -ne $_ }
            })
        $exposed = @($findings | Where-Object { $null -eq $Served -or $Served.Contains("$(Get-Key $_ 'Commit')") })
        $localOnly = $findings.Count - $exposed.Count
        if ($exposed.Count -gt 0) {
            $where = @($exposed | ForEach-Object {
                    $commit = "$(Get-Key $_ 'Commit')"
                    # A repo's own config can name a rule after anything.
                    "$(Format-Safe "$(Get-Key $_ 'RuleID')" 'rule name') at $($commit.Substring(0, [Math]::Min(7, $commit.Length)))"
                } | Sort-Object -Unique)
            Hit "$Label`: gitleaks found $($exposed.Count) secret(s) in commits the remote serves: $(Format-IdList $where)" `
                -Why 'a secret in any commit turns readable, and a revoked one still names its system' `
                -Fix 'revoke each first; then rewrite it out and publish as a history hit says, or keep the repo private'
        } else { Ok "$Label`: gitleaks found no secret in a commit the remote serves" }
        if ($localOnly -gt 0) { Info "$Label`: $localOnly gitleaks finding(s) in commits only this clone holds, which the switch exposes to no one" }
    } finally {
        foreach ($temp in @($report, $leaksConfig, $noIgnore)) {
            if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
        }
    }
}

Step 'Secrets in the history'
if ($tips.Count -gt 0) { Invoke-SecretScan -Root $cloneRoot -Served $publicCommits -Label 'history' }
else { Info 'no history to scan' }
#endregion

#region Issues and pull requests
Step 'Issues and pull requests'
# A thread's number from a comment's issue_url or pull_request_url.
function Get-ThreadNumber {
    param([string]$Url)
    if ($Url -match '/(\d+)$') { return "#$($Matches[1])" }
    return '#?'
}
# Report one kind of text: how many were read, and which threads hold a term.
function Write-TextFinding {
    param([string]$Kind, [int]$Read, [string[]]$Threads, [string]$Fix)
    $unique = @($Threads | Sort-Object { [int]($_ -replace '\D', '0') } -Unique)
    if ($unique.Count -gt 0) {
        Hit "$Kind`: $($unique.Count) thread(s) hold a denylist term, of $Read read: $(Format-IdList $unique)" `
            -Why 'every reader sees it, a closed thread and an edit history too' -Fix $Fix
    } else { OkTerm "$Kind`: none of $Read holds a denylist term" }
}
$editFix = ('edit it out, then delete each earlier revision under "edited", Options, Delete revision ' +
    'from history; or delete the comment')

$issueRead = Read-ItemList "repos/$Repo/issues?state=all&per_page=100"
if ($issueRead.Error) {
    if ($issueRead.Error -match 'HTTP 410') { Info 'issues are off' }
    else { Warn "issues unread: $($issueRead.Error)" }
} else {
    $issues = @($issueRead.Items | Where-Object { $null -eq (Get-Key $_ 'pull_request') })
    $threads = @($issues | Where-Object { Test-Term "$(Get-Key $_ 'title')`n$(Get-Key $_ 'body')" } |
            ForEach-Object { "#$(Get-Key $_ 'number')" })
    Write-TextFinding -Kind 'issues, title and body' -Read $issues.Count -Threads $threads -Fix $editFix
}
$pullRead = Read-ItemList "repos/$Repo/pulls?state=all&per_page=100"
if ($pullRead.Error) { Warn "pull requests unread: $($pullRead.Error)" } else {
    $threads = @($pullRead.Items | Where-Object {
            Test-Term ("$(Get-Key $_ 'title')`n$(Get-Key $_ 'body')`n" +
                "$(Get-Key (Get-Key $_ 'head') 'ref')`n$(Get-Key (Get-Key $_ 'base') 'ref')") } |
            ForEach-Object { "#$(Get-Key $_ 'number')" })
    Write-TextFinding -Kind 'pull requests, title, body and branch' -Read $pullRead.Items.Count -Threads $threads -Fix $editFix
}
$commentRead = Read-ItemList "repos/$Repo/issues/comments?per_page=100"
if ($commentRead.Error) {
    if ($commentRead.Error -match 'HTTP 410') { Info 'issue comments are off with the issues' }
    else { Warn "comments unread: $($commentRead.Error)" }
} else {
    $threads = @($commentRead.Items | Where-Object { Test-Term (Get-Key $_ 'body') } |
            ForEach-Object { Get-ThreadNumber (Get-Key $_ 'issue_url') })
    Write-TextFinding -Kind 'comments' -Read $commentRead.Items.Count -Threads $threads -Fix $editFix
}
# A review comment shows its diff hunk beside it, which may come from a
# commit a force push has since replaced.
$reviewCommentRead = Read-ItemList "repos/$Repo/pulls/comments?per_page=100"
if ($reviewCommentRead.Error) { Warn "review comments unread: $($reviewCommentRead.Error)" } else {
    $threads = @($reviewCommentRead.Items | Where-Object {
            Test-Term "$(Get-Key $_ 'body')`n$(Get-Key $_ 'diff_hunk')`n$(Get-Key $_ 'path')" } |
            ForEach-Object { Get-ThreadNumber (Get-Key $_ 'pull_request_url') })
    Write-TextFinding -Kind 'review comments, with their diff hunks' -Read $reviewCommentRead.Items.Count -Threads $threads -Fix $editFix
}

# What REST does not return: a title's earlier wording, a body's edit
# history and a review's own text. A connection past its first page is
# counted unread rather than paged, each page holding a thread's first 50.
# Its hasNextPage says so, never its totalCount, which counts what
# itemTypes filters out: 10 beside a filteredCount of 0 on a pull request
# here (2026-11-04).
$threadPart = @'
number
userContentEdits(first: 50) { pageInfo { hasNextPage } nodes { diff } }
timelineItems(first: 50, itemTypes: [RENAMED_TITLE_EVENT]) { pageInfo { hasNextPage } nodes { ... on RenamedTitleEvent { previousTitle } } }
'@
$historyQueries = [ordered]@{
    'issues'        = "query Issues(`$owner: String!, `$name: String!, `$endCursor: String) { repository(owner: `$owner, name: `$name) { issues(first: 50, after: `$endCursor) { pageInfo { hasNextPage endCursor } nodes { $threadPart } } } }"
    'pull requests' = "query PullRequests(`$owner: String!, `$name: String!, `$endCursor: String) { repository(owner: `$owner, name: `$name) { pullRequests(first: 50, after: `$endCursor) { pageInfo { hasNextPage endCursor } nodes { $threadPart reviews(first: 50) { pageInfo { hasNextPage } nodes { body } } } } } }"
}
# Whether a nested connection has more than its first page.
function Test-NextPage {
    param($Connection)
    return [bool](Get-Key (Get-Key $Connection 'pageInfo') 'hasNextPage')
}
foreach ($kind in $historyQueries.Keys) {
    $read = Invoke-GhQuery -Query $historyQueries[$kind] -Variables @{ owner = $repoOwner; name = $repoName } -Paginate
    if ($read.ExitCode -ne 0) { Warn "$kind`: earlier titles, edit history and reviews unread: $($read.Failure)"; continue }
    $connection = if ($kind -eq 'issues') { 'issues' } else { 'pullRequests' }
    $nodes = @(foreach ($page in @($read.Text | ConvertFrom-Json -AsHashtable)) {
            Get-List (Get-Key (Get-Key (Get-Key $page 'data') 'repository') $connection) 'nodes'
        })
    $titleHits = [System.Collections.Generic.List[string]]::new()
    $editHits = [System.Collections.Generic.List[string]]::new()
    $reviewHits = [System.Collections.Generic.List[string]]::new()
    $partial = 0
    foreach ($node in $nodes) {
        $number = "#$(Get-Key $node 'number')"
        foreach ($part in @('userContentEdits', 'timelineItems', 'reviews')) {
            if (Test-NextPage (Get-Key $node $part)) { $partial++ }
        }
        if (Test-Term ((Get-List (Get-Key $node 'timelineItems') 'nodes' | ForEach-Object { Get-Key $_ 'previousTitle' }) -join "`n")) { $titleHits.Add($number) }
        if (Test-Term ((Get-List (Get-Key $node 'userContentEdits') 'nodes' | ForEach-Object { Get-Key $_ 'diff' }) -join "`n")) { $editHits.Add($number) }
        if (Test-Term ((Get-List (Get-Key $node 'reviews') 'nodes' | ForEach-Object { Get-Key $_ 'body' }) -join "`n")) { $reviewHits.Add($number) }
    }
    Write-TextFinding -Kind "$kind, earlier titles" -Read $nodes.Count -Threads $titleHits `
        -Fix ('a rename keeps the old title in the timeline: only deleting an issue removes it, and GitHub ' +
            'documents no delete for a pull request, which goes only with the repo')
    Write-TextFinding -Kind "$kind, a body's edit history" -Read $nodes.Count -Threads $editHits -Fix $editFix
    if ($kind -eq 'pull requests') { Write-TextFinding -Kind 'pull request reviews' -Read $nodes.Count -Threads $reviewHits -Fix $editFix }
    if ($partial -gt 0) {
        Warn "$kind`: $partial thread part(s) hold more than 50 edits, renames or reviews, and the rest went unread"
    }
}
Info "not read: an edited comment's earlier versions, which any reader can open under its 'edited' menu, nor labels, milestones and commit comments"
#endregion

#region Discussions, wiki and releases
Step 'Discussions, wiki and releases'
if (Get-Key $repoJson 'has_discussions') {
    $discussionQuery = 'query Discussions($owner: String!, $name: String!, $endCursor: String) { repository(owner: $owner, name: $name) { discussions(first: 25, after: $endCursor) { pageInfo { hasNextPage endCursor } nodes { number title body comments(first: 50) { pageInfo { hasNextPage } nodes { body replies(first: 50) { pageInfo { hasNextPage } nodes { body } } } } } } } }'
    $read = Invoke-GhQuery -Query $discussionQuery -Variables @{ owner = $repoOwner; name = $repoName } -Paginate
    if ($read.ExitCode -ne 0) { Warn "discussions unread: $($read.Failure)" } else {
        $nodes = @(foreach ($page in @($read.Text | ConvertFrom-Json -AsHashtable)) {
                Get-List (Get-Key (Get-Key (Get-Key $page 'data') 'repository') 'discussions') 'nodes'
            })
        $threads = [System.Collections.Generic.List[string]]::new()
        $partial = 0
        foreach ($node in $nodes) {
            $comments = Get-Key $node 'comments'
            if (Test-NextPage $comments) { $partial++ }
            $texts = @("$(Get-Key $node 'title')", "$(Get-Key $node 'body')")
            foreach ($comment in (Get-List $comments 'nodes')) {
                $texts += "$(Get-Key $comment 'body')"
                $replies = Get-Key $comment 'replies'
                if (Test-NextPage $replies) { $partial++ }
                $texts += @(Get-List $replies 'nodes' | ForEach-Object { "$(Get-Key $_ 'body')" })
            }
            if (Test-Term ($texts -join "`n")) { $threads.Add("#$(Get-Key $node 'number')") }
        }
        Write-TextFinding -Kind 'discussions, with comments and replies' -Read $nodes.Count -Threads $threads -Fix $editFix
        if ($partial -gt 0) { Warn "discussions: $partial part(s) hold more than 50 comments or replies, and the rest went unread" }
    }
} else { Info 'discussions are off' }

# The wiki is a repository of its own beside the code, cloned whole into
# a temp folder, since no API reads it.
if (Get-Key $repoJson 'has_wiki') {
    $wikiUrl = ($originUrl -replace '\.git/?$', '') + '.wiki.git'
    $wikiRefs = Invoke-Git -GitArgs @('-C', $cloneRoot, 'ls-remote', $wikiUrl)
    if ($wikiRefs.ExitCode -ne 0) {
        if ($wikiRefs.Error -match 'not found|does not appear to be a git repository') { Info 'the wiki is on, with no page' }
        else { Warn "wiki unread: git ls-remote failed: $($wikiRefs.Error)" }
    } elseif ($wikiRefs.Lines.Count -eq 0) {
        Info 'the wiki is on, with no page'
    } else {
        $wikiDir = Join-Path ([System.IO.Path]::GetTempPath()) "going-public-wiki-$([guid]::NewGuid().ToString('N'))"
        try {
            $wikiClone = Invoke-Git -GitArgs @('-C', $cloneRoot, 'clone', '--quiet', '--mirror', $wikiUrl, $wikiDir)
            if ($wikiClone.ExitCode -ne 0) { Warn "wiki unread: git clone failed: $($wikiClone.Error)" } else {
                $wikiAddresses = Invoke-HistoryScan -Root $wikiDir -Label 'wiki'
                Write-AddressFinding -Addresses $wikiAddresses -Label 'wiki'
                Invoke-SecretScan -Root $wikiDir -Served $null -Label 'wiki'
            }
        } finally {
            if (Test-Path -LiteralPath $wikiDir) { Remove-Item -LiteralPath $wikiDir -Recurse -Force }
        }
    }
} else { Info 'the wiki is off' }

$releaseRead = Read-ItemList "repos/$Repo/releases?per_page=100"
if ($releaseRead.Error) { Warn "releases unread: $($releaseRead.Error)" } else {
    $published = @($releaseRead.Items | Where-Object { -not (Get-Key $_ 'draft') })
    $drafts = $releaseRead.Items.Count - $published.Count
    $releaseHits = @(foreach ($release in $published) {
            $assetNames = @(Get-List $release 'assets' | ForEach-Object { Get-Key $_ 'name' })
            $text = "$(Get-Key $release 'tag_name')`n$(Get-Key $release 'name')`n$(Get-Key $release 'body')`n" +
                ($assetNames -join "`n")
            if (Test-Term $text) { Format-Safe "$(Get-Key $release 'tag_name')" 'tag' }
        })
    if ($releaseHits.Count -gt 0) {
        Hit "releases: $($releaseHits.Count) of $($published.Count) hold a denylist term in a name, a note or an asset's name: $(Format-IdList $releaseHits)" `
            -Fix 'edit or delete each before the switch'
    } else { OkTerm "releases: none of $($published.Count) holds a denylist term" }
    $assetCount = @($published | ForEach-Object { Get-List $_ 'assets' }).Count
    if ($assetCount -gt 0) { Info "releases: $assetCount asset(s), each name read, the files not" }
    if ($drafts -gt 0) { Info "releases: $drafts draft(s), which stay visible to writers alone" }
}
#endregion

#region Actions
Step 'Actions'
$runRead = Invoke-GhApi -Endpoint "repos/$Repo/actions/runs?per_page=1"
if ($runRead.ExitCode -ne 0) { Warn "workflow runs unread: $($runRead.Failure)" } else {
    $runCount = [int](Get-Key ($runRead.Text | ConvertFrom-Json -AsHashtable) 'total_count')
    if ($runCount -gt 0) {
        Warn "$runCount workflow run(s): every log turns readable, and none was read here" `
            -Why 'a log keeps what each step printed: paths, names, and a secret the masking missed' `
            -Fix "read them first, or delete them: gh run list -R $Repo -L $runCount --json databaseId, then gh run delete <id> -R $Repo"
    } else { Ok 'no workflow run' }
}
$artifactRead = Read-ItemList "repos/$Repo/actions/artifacts?per_page=100"
if ($artifactRead.Error) { Warn "artifacts unread: $($artifactRead.Error)" } else {
    $live = @($artifactRead.Items | ForEach-Object { Get-List $_ 'artifacts' } | Where-Object { -not (Get-Key $_ 'expired') })
    if ($live.Count -gt 0) {
        Warn "$($live.Count) unexpired artifact(s): each turns downloadable, and none was read here" `
            -Fix "gh api -X DELETE repos/$Repo/actions/artifacts/<id>, for each to keep private"
    } else { Ok 'no unexpired artifact' }
}
#endregion

#region Rulesets, projects and what the switch erases
Step 'Rulesets, projects and what the switch erases'
$pushRead = Invoke-GhApi -Endpoint "repos/$Repo/rulesets?targets=push&includes_parents=true"
if ($pushRead.ExitCode -ne 0) { Warn "push rulesets unread: $($pushRead.Failure)" } else {
    $pushSets = @($pushRead.Text | ConvertFrom-Json -AsHashtable |
            Where-Object { $null -ne $_ -and (Get-Key $_ 'target') -eq 'push' -and (Get-Key $_ 'enforcement') -ne 'disabled' })
    if ($pushSets.Count -gt 0) {
        $names = @($pushSets | ForEach-Object { Format-Safe "$(Get-Key $_ 'name')" 'name' })
        Warn "$($pushSets.Count) push ruleset(s) the switch disables: $($names -join ', ')" `
            -Why 'what each blocks from being pushed reaches the remote once the repo is public' `
            -Fix 'move what each blocks into the pre-commit hooks before the switch'
    } else { Ok 'no push ruleset' }
}
Info "the default branch's guard against force pushes and deletion is audit-repo.ps1's, run with -AsPublic"

$projectQuery = 'query Projects($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { projectsV2(first: 50) { totalCount nodes { number title public url } } } }'
$projectRead = Invoke-GhQuery -Query $projectQuery -Variables @{ owner = $repoOwner; name = $repoName }
$projects = if ($projectRead.ExitCode -eq 0) {
    Get-Key (Get-Key (Get-Key ($projectRead.Text | ConvertFrom-Json -AsHashtable) 'data') 'repository') 'projectsV2'
} else { $null }
if ($null -eq $projects) {
    $why = if ($projectRead.Failure) { $projectRead.Failure } else { 'the answer held no projectsV2' }
    Warn "linked projects unread: $why"
} else {
    $nodes = @(Get-List $projects 'nodes')
    if ($nodes.Count -eq 0) { Info 'no linked project' }
    foreach ($project in $nodes) {
        $title = Format-Safe "$(Get-Key $project 'title')" 'title'
        if (Get-Key $project 'public') {
            Info "project $(Get-Key $project 'number') '$title' is public: this repo's items on it turn readable there"
        } else {
            Info "project $(Get-Key $project 'number') '$title' is private, and the switch leaves it so"
        }
    }
}
Info ("the switch erases $([int](Get-Key $repoJson 'stargazers_count')) star(s) and " +
    "$([int](Get-Key $repoJson 'subscribers_count')) watcher(s), and detaches " +
    "$([int](Get-Key $repoJson 'forks_count')) private fork(s) as repos of their own")
#endregion

Step "Summary: $script:Hits HIT, $script:Warnings WARN"
if ($script:Hits + $script:Warnings -gt 0) { exit 1 }
exit 0
