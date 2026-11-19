<#
.SYNOPSIS
    Audit a GitHub repo's live settings and its About panel against a
    policy: personal, org-internal, org-published or releases. Reads only;
    changes nothing.

.DESCRIPTION
    Every call this script makes reads: a GET, or a GraphQL query for
    the social preview and for the boards, which no REST endpoint
    reports. Each finding prints with the reason the policy holds it and
    the change that would fix it, for the repo's owners to make.

    WHY NOT repo-settings.ps1 -Check, beside this script: -Check
    compares the live repo with a snapshot and throws where there is none,
    and -Export takes only the repo's owner or an organization's admin.
    This script compares with a policy instead, and needs no snapshot and
    no ownership, only an account with admin rights on the repo; the
    skill runs -Check after it where the clone keeps a snapshot.

    THE FOUR POLICIES. The first three want merge commits only, auto-delete
    of merged branches, and a read-only Actions token that cannot approve
    pull requests. personal and org-internal also warn, on a public repo alone,
    where no active rule on the default branch blocks force pushes or
    deletion (the user's call, 2026-11-03): a fast-forward push,
    land-branch's route, trips neither, where a pull request rule would
    reroute it. On a private repo each missing rule is context naming the
    skill's guard ruleset scaffold, never a warning (the user, 2026-11-04).
    org-internal is for an organization's repo that
    publishes nothing. org-published, for a repo whose default
    branch publishes to other people, adds an active ruleset on that
    branch (pull request, code-owner review, required status checks, no
    force push, no deletion), a CODEOWNERS file free of errors, and, given
    -ReleaseTagPattern, a tag ruleset that stops a release tag moving or
    being deleted. releases, for a repo holding only an app's installers
    and update feed while its source lives elsewhere, judges what that
    repo needs instead (the user's call, 2026-11-10): immutable releases
    and Actions off fail; the default branch's force-push and deletion
    guard, on any visibility, and issues, wiki and projects off warn; so
    does a README that names no route for reports where issues and
    Discussions are both off, read from its mailto: and its links to another
    repo's issues or Discussions, and private vulnerability
    reporting off, the private route for a security hole. The merge
    settings, the Actions token and a missing security policy print as
    context there, since no pull request lands and no workflow runs, and
    the policy is a scaffold to offer. On any other public repo, private
    vulnerability reporting and the security policy are one context line
    (the user's call, 2026-11-13). The skill's references/profiles.md says
    which to pick.

    REQUIRED CHECKS ARE MATCHED AGAINST CHECK RUNS GITHUB RECORDED, on the
    default branch's head and the five most recent pull requests' heads,
    never against job names in the workflow files: a matrix job reports
    one run per value, as test (20) and test (24), which a static read
    would have to expand (measured 2026-10-22). Commit statuses count too,
    since a required check can be either.

    HARDENING IS WARNED OF, NEVER FAILED, under any policy (the user's
    call, 2026-10-30): a workflow's uses: not pinned to a full commit SHA,
    read from the default branch's .github/workflows/ by the contents API,
    and the server's sha_pinning_required off; secret scanning or push
    protection off, where GitHub returns security_and_analysis at all,
    which it did not for a private personal repo (2026-10-30); a deploy
    key that can write; an environment with no deployment branch policy,
    which any branch can deploy to; a bypass actor on any active ruleset, not only
    the default branch's, its reason naming the force push and deletion
    an always or exempt bypass passes where the ruleset holds those rules
    too; a code-owner rule that keeps an approval
    across a new push; and, on a public repo, a default branch holding a
    pre-commit config that no workflow runs, which is context on any
    other (the user, 2026-11-03). A workflow the lockfile,
    .github/workflows/actions.lock, onboards has its actions' commits
    recorded there, so an action's tag is context; a reusable workflow's
    is not, since the lockfile does not pin one, and an image's is not,
    as the docs name none (GitHub docs, 2026-10-30).

    FOUR THINGS ARE CONTEXT, NEVER A FINDING (the user's call, 2026-11-02):
    each Actions policy that applies, by name, enforcement and rule types;
    a lockfile with no active policy, so only sha_pinning_required, for a
    tag or branch, or with that off nothing, blocks a workflow it does not
    onboard; a public repo's pull request cap and its bypass list; and
    secret_scanning_ai_detection, where GitHub returns it. No policy here
    asks for any of them, and each is a choice, or a bill, for the owner.
    The REST docs name two policy rule types, actor and event, and no
    lockfile rule (read 2026-11-02), so no line can say which policy
    requires the lockfile: the types print as GitHub returns them.

    THE ABOUT PANEL IS WARNED OF, NEVER FAILED: the description, homepage
    and topics as they stand, so the skill can propose new ones as a diff;
    the social preview; and the community profile's README, licence,
    CONTRIBUTING, code of conduct and pull request template. A missing
    card warns on a public repo and is context on a private one, whose
    links unfurl to no one outside it; a missing CONTRIBUTING, code of
    conduct or pull request template warns under org-published only.
    GitHub answers the community profile for a private repo too (two
    read 2026-10-24). It reports a single template file alone, so a null
    there looks in the repo, then in the owner's public defaults repo: a
    template folder alone is context, and an unread listing warns of that.

    THE HANDOFF BOARD IS WARNED OF, NEVER FAILED, under any policy, and
    a repo with no board is context (the user's call, 2026-10-29). The
    board is the one linked project carrying the contract's Status,
    Priority and Reopen-when, as the queue's scripts pick it, and is
    judged against provision-board's references/board-contract.md: its
    fields and options, its workflows on and off, and the needs:user
    label in the repo, the one label every board's repo gets; filing makes
    the rest as a brief names them. GraphQL reads a workflow's name and
    enabled flag alone, so a workflow's value and filter go unread, as do
    Code changes requested and Code review approved, which it never lists.
    A token without read:project leaves the board unread, never missing.
    Beside a board, Actions off or no close-parent.yml in the default
    branch's workflows warns too, since GitHub closes no parent with its
    last sub-issue: the file is found by its name alone, never by its text.

    A HANDOFF QUEUE'S LANDING IS WARNED OF, NEVER FAILED, under any
    policy. Where a board or docs/handoffs/ on the default branch holds a
    queue, its rule for briefs, .claude/rules/handoff-briefs.md, warns
    when missing or holding neither landing bullet's bold opening, since
    work-issue and lead-sessions stop at their preflight until it names
    one. The rule is grepped for the openings, as file-issue and
    provision-board grep it, never judged, so a landing in other words
    reads as none; the fix names the bullet for the route the active
    rules imply.

    THE CLAUDE CODE ACTION IS CONTEXT, under org-internal and
    org-published alone: which default-branch workflows have a
    uses: naming anthropics/claude-code-action, or that none does, for the
    skill to offer its workflow. It prints whatever the collaborator
    count, and personal and releases print nothing: the user kept the
    Action out of a personal repo, and no work lands in a releases
    repo. A workflow that a comment starts and that calls another repo's
    reusable workflow, as the docs' organization setup may, is named,
    since that workflow is not read and may run the Action. Whether the
    Claude GitHub App is
    installed, or the secret set, is not read.

    WHAT IT DOES NOT AUDIT: classic branch protection (reported, not
    read), push rulesets' rules, an environment's reviewers, variables
    and branch patterns, secrets, Dependabot and
    code scanning, composite actions' own uses: lines, a uses: in YAML
    flow style, and organization-level defaults, which it reads only as
    the repo sees them. The uses: scan reads lines, not YAML, so a line
    inside a run: block that starts with uses: is read as one. Nor does it
    read a repo's temporary interaction limits, which expire; the pull
    request cap's exemptions by account age or merged pull requests, which
    its REST schema does not carry; push protection for AI-detected
    secrets, which the repo schema gives no key of its own and which bills
    Secret Protection AI credits per push scanned (both read 2026-11-02);
    an ACCESSIBILITY.md, which no policy here asks for and the community
    profile's schema does not list; or what runs the pre-commit hooks
    beyond a workflow file's own lines, so a reusable workflow from
    another repo or an app such as pre-commit.ci reads as none, while a
    workflow that runs them on a trigger other than push or pull_request,
    or a line naming the command in an echo or a trailing comment, counts
    as one.

    A REPO GOING PUBLIC IS JUDGED AS PUBLIC under -AsPublic: each check a
    public repo alone gets, the branch guard, the licence, the card and
    the pre-commit workflow, warns as it will once the switch is made.
    Reads still follow the live visibility, so the pull request cap,
    which a private repo cannot answer, stays unread, and secret
    scanning's fix still names the spend a private organization repo
    pays. Where a private repo returns no security_and_analysis block,
    each secret-scanning key warns to be turned on after the switch,
    since GitHub turns neither on then. What the switch exposes is
    going-public.ps1's, beside this one.

    THE ACCOUNT IS -Login, PINNED HERE, where the caller names one: its
    token is minted by gh auth token --user, whatever GH_TOKEN held, and
    the run stops unless gh then acts as it, since a 404 from the wrong
    account reads as a missing repo. A caller's own pin held no further
    than its own call: each Bash tool call is a fresh shell, so an export
    of GH_TOKEN in one read unset in the next (2026-11-05), and a
    worktree session's guard refuses the export as too complex to verify
    (2.1.317, 2026-11-03). Without -Login the script reads as gh answers,
    a GH_TOKEN it inherited or else the keyring's active account, and
    names that account on its first line. The pin is this process's
    GH_TOKEN: under pwsh -File, as the skill runs it, it ends with the
    run, while a session that calls the script with & keeps it.

    Exit codes: 0 no FAIL, 1 one or more FAIL, 2 the repo could not be
    audited (gh missing, no token for -Login or gh acting as another
    account, the repo unreadable, merge settings that came back null
    because the account lacks the rights to read them, or any read that
    failed partway).

.PARAMETER Policy
    personal, org-internal, org-published or releases. No default: the
    choice is the audit.

.PARAMETER Repo
    owner/name. Defaults to the origin remote of the clone the working
    directory is in.

.PARAMETER ReleaseTagPattern
    The release tags' pattern as a tag ruleset names it, without the
    refs/tags/ prefix, for example *-v*. Compared as text, not as a
    pattern. Without it, tag rulesets are listed and not judged.

.PARAMETER AsPublic
    Judge a private or internal repo as it will be judged once public.

.PARAMETER Login
    The GitHub account to read as, pinned for the run: for an
    organization's repo, one with admin rights there. Left out, gh's own
    account answers; given empty, the run stops.

.EXAMPLE
    pwsh -NoProfile -File <skill>/scripts/audit-repo.ps1 -Policy personal

.EXAMPLE
    pwsh -NoProfile -File <skill>/scripts/audit-repo.ps1 -Repo <owner>/<repo> -Policy org-published -ReleaseTagPattern '*-v*' -Login <admin>
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('personal', 'org-internal', 'org-published', 'releases')][string]$Policy,
    [string]$Repo,
    [string]$ReleaseTagPattern,
    [switch]$AsPublic,
    [string]$Login
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
$script:Warnings = 0

function Step { param($m) Write-Host "`n=== $m" -ForegroundColor Cyan }
function Ok { param($m) Write-Host "  [ok]    $m" -ForegroundColor Green }
function Info { param($m) Write-Host "  [INFO]  $m" }
function Write-Reason {
    param($Why, $Fix)
    if ($Why) { Write-Host "          why: $Why" }
    if ($Fix) { Write-Host "          fix: $Fix" }
}
function Warn {
    param($m, $Why, $Fix)
    Write-Host "  [WARN]  $m" -ForegroundColor Yellow
    Write-Reason -Why $Why -Fix $Fix
    $script:Warnings++
}
function Fail {
    param($m, $Why, $Fix)
    Write-Host "  [FAIL]  $m" -ForegroundColor Red
    Write-Reason -Why $Why -Fix $Fix
    $script:Failures++
}
# Exit 2 rather than throw: a throw exits 1, which reads as findings.
function Exit-Audit {
    param($m)
    Write-Host "  [STOP]  $m" -ForegroundColor Red
    exit 2
}
# The same for a failure nothing below expects, such as a ruleset or the
# default branch that will not read partway through: the audit is
# unfinished, not failed.
trap { Exit-Audit "the audit stopped partway: $_" }

#region gh helpers
# gh writes UTF-8, and pwsh decodes a native command's output with the
# console's code page, which garbled an em dash in repo-settings.ps1's
# reads (measured there 2026-09-10). So every call runs under UTF-8.
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
    # A refusal names gh's own lines alone, never the body Text carries
    # beside them: gh 2.103.3 prints a 401's JSON body on stdout and its
    # "gh: Bad credentials (HTTP 401)" line on stderr, which 2>&1 merged
    # between the body's lines (probed 2026-11-05). So Failure is stderr,
    # or a stdout line that opens "gh:", as a stand-in prints its errors;
    # else the exit code. going-public.ps1's Invoke-Gh tells a failure the
    # same way.
    $stderr = @($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    $stdout = @($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
            ForEach-Object { "$_" -split '\r?\n' })
    $stderrText = ($stderr -join ' ').Trim()
    $ghLines = @($stdout -match '^gh: ')
    $failure = if ($exitCode -eq 0) { '' }
    elseif ($stderrText) { $stderrText }
    elseif ($ghLines.Count -gt 0) { $ghLines -join ' ' }
    else { "gh exited $exitCode" }
    [pscustomobject]@{ ExitCode = $exitCode; Text = (@($out) -join "`n"); Failure = $failure }
}

function Invoke-GhApi {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Endpoint)
    Invoke-Gh -GhArgs @('api', '-X', 'GET', $Endpoint, '-H', 'Accept: application/vnd.github+json')
}

# GraphQL goes by POST, but a query only reads, and this script sends no
# mutation. Each variable is a string, passed with -f so gh sends it as one.
function Invoke-GhQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Query,
        [hashtable]$Variables = @{}
    )
    $ghArgs = @('api', 'graphql', '-f', "query=$Query")
    foreach ($key in $Variables.Keys) { $ghArgs += @('-f', "$key=$($Variables[$key])") }
    Invoke-Gh -GhArgs $ghArgs
}

# The parsed answer, $null for a 404 where -NotFoundIsAnswer says a 404
# means something, and a throw for any other failure.
function Get-GhJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [switch]$NotFoundIsAnswer
    )
    $r = Invoke-GhApi -Endpoint $Endpoint
    if ($r.ExitCode -ne 0) {
        if ($NotFoundIsAnswer -and $r.Text -match 'HTTP 404') { return $null }
        throw "gh api $Endpoint failed: $($r.Text)"
    }
    if ([string]::IsNullOrWhiteSpace($r.Text)) { return $null }
    return ($r.Text | ConvertFrom-Json -AsHashtable)
}

# A key's value, or $null where the key is absent: strict mode throws on
# an absent key, and GitHub leaves some out depending on the reader.
function Get-Key {
    param($Map, [string]$Key)
    if ($Map -is [System.Collections.IDictionary] -and $Map.Contains($Key)) { return $Map[$Key] }
    return $null
}

# A list key's items with no $null among them: @($null) has one element,
# so an absent list would otherwise count as one item.
function Get-List {
    param($Map, [string]$Key)
    return @(Get-Key $Map $Key | Where-Object { $null -ne $_ })
}

function Get-OriginRepo {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Root)
    $url = git -C $Root remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or $url -notmatch 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/]+?)(\.git)?$') {
        return $null
    }
    return "$($Matches['owner'])/$($Matches['name'])"
}
#endregion

#region Pre-flight
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Exit-Audit 'gh not found on PATH. hint: winget install GitHub.cli'
}
if (-not $Repo) {
    $workingDir = (Get-Location -PSProvider FileSystem).ProviderPath
    $cloneRoot = git -C $workingDir rev-parse --show-toplevel 2>$null
    $Repo = if ($LASTEXITCODE -eq 0) { Get-OriginRepo -Root $cloneRoot } else { $null }
    if (-not $Repo) { Exit-Audit "No GitHub origin remote for $workingDir; pass -Repo owner/name." }
}
if ($Repo -notmatch '^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$') { Exit-Audit "-Repo takes owner/name, not '$Repo'." }

# The account; see the header. Before any read, so a refused token reads
# nothing. The token is never printed: a failed mint prints gh's error.
if ($PSBoundParameters.ContainsKey('Login')) {
    if ([string]::IsNullOrWhiteSpace($Login)) {
        Exit-Audit '-Login names no account; leave it out to read as gh''s own.'
    }
    # Not through Invoke-Gh, which joins stderr to stdout: the token is
    # stdout's first line alone, and stderr is kept for the refusal.
    $mint = @(gh auth token --user $Login 2>&1)
    $mintExit = $LASTEXITCODE
    $mintErrors = @($mint | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
    $mintLines = @($mint | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
    $token = if ($mintExit -eq 0) { "$($mintLines | Select-Object -First 1)".Trim() } else { '' }
    if (-not $token) {
        # On a failure gh prints its error to stderr, or to stdout as a
        # stand-in may; neither holds a token then.
        $why = (@($mintErrors) + @($mintLines) | ForEach-Object { "$_" }) -join ' '
        Exit-Audit "gh has no token for $Login, the account -Login names, so nothing is read: $why"
    }
    $env:GH_TOKEN = $token
}

$user = Invoke-GhApi -Endpoint 'user'
# Not $login: a variable's name is case-blind, so that is the -Login parameter.
$actingAs = if ($user.ExitCode -eq 0) { ($user.Text | ConvertFrom-Json -AsHashtable)['login'] } else { '<unknown>' }
# Case-blind, as GitHub's logins are and as -ne compares.
if ($PSBoundParameters.ContainsKey('Login') -and $actingAs -ne $Login) {
    # A revoked token fails the read: name gh's error, not only <unknown>.
    $detail = if ($user.ExitCode -ne 0) { " gh api user failed: $($user.Failure)" } else { '' }
    Exit-Audit "gh acts as $actingAs, but -Login names $Login, so nothing is read.$detail"
}

$repoRead = Invoke-GhApi -Endpoint "repos/$Repo"
if ($repoRead.ExitCode -ne 0) {
    # gh answers 404 for a repo the account cannot see as for one that does
    # not exist, so the account is named first.
    Exit-Audit "gh, acting as $actingAs, cannot read $Repo -- the wrong account, or no such repo: $($repoRead.Failure)"
}
$repoJson = $repoRead.Text | ConvertFrom-Json -AsHashtable
if ($null -eq (Get-Key $repoJson 'allow_squash_merge')) {
    Exit-Audit ("Merge settings for $Repo came back null: $actingAs lacks the rights to read them. " +
        'Pass -Login an account with admin rights on the repo.')
}
$defaultBranch = $repoJson['default_branch']
$ownerType = $repoJson['owner']['type']
$isAdmin = [bool](Get-Key (Get-Key $repoJson 'permissions') 'admin')
$settingsUrl = "https://github.com/$Repo/settings"
# $isPublicNow decides what can be read, $isPublic how the repo is judged.
$isPublicNow = $repoJson['visibility'] -eq 'public'
$isPublic = $isPublicNow -or $AsPublic
#endregion

Step "$Repo -- policy $Policy -- read as $actingAs"
Info "owner type $ownerType; visibility $($repoJson['visibility']); default branch $defaultBranch"
if ($AsPublic -and -not $isPublicNow) {
    Info ('judged as public, as -AsPublic asks; what GitHub offers a public repo alone ' +
        'reads once the switch is made: secret scanning warns where unread, ' +
        'the pull request cap is unread')
}
if (-not $isAdmin) {
    Warn "$actingAs has no admin rights on $Repo" `
        -Why 'a ruleset hides its bypass list from an account without write access to it'
}
if ($Policy -eq 'personal' -and $ownerType -eq 'Organization') {
    Warn 'policy personal on an organization repo' `
        -Why 'org-internal is the policy for one that publishes nothing, org-published for one that does'
}
if ($Policy -eq 'org-internal' -and $ownerType -ne 'Organization') {
    Warn "policy org-internal on a repo owned by a $ownerType" `
        -Why 'personal asks the same of it, and says whose repo it is'
}

#region Merge settings
Step 'Merge settings'
$patch = "gh api -X PATCH repos/$Repo"
$mergeRules = @(
    @{ Key = 'allow_merge_commit'; Want = $true
        Why = "a merge commit keeps every commit's SHA, and it is land's route where a pull request is required" },
    @{ Key = 'allow_squash_merge'; Want = $false
        Why = 'a squash collapses the commits a branch was split into, so none can be reverted or cited alone' },
    @{ Key = 'allow_rebase_merge'; Want = $false
        Why = 'a rebase merge rewrites every SHA on the branch' },
    @{ Key = 'delete_branch_on_merge'; Want = $true
        Why = 'merged branches stay on the remote until someone prunes them' }
)
if ($Policy -eq 'releases') {
    # No pull request lands in a releases repo, so how one would merge
    # decides nothing there (the user, 2026-11-10): the values are context.
    $mergeValues = @($mergeRules | ForEach-Object { "$($_.Key) $("$(Get-Key $repoJson $_.Key)".ToLowerInvariant())" })
    Info "not judged under releases, as no pull request lands here: $($mergeValues -join ', ')"
} else {
    foreach ($rule in $mergeRules) {
        $value = $repoJson[$rule.Key]
        $wantText = "$($rule.Want)".ToLowerInvariant()
        if ($value -eq $rule.Want) {
            Ok "$($rule.Key) is $wantText"
        } else {
            Fail "$($rule.Key) is $("$value".ToLowerInvariant()), want $wantText" `
                -Why $rule.Why -Fix "$patch -F $($rule.Key)=$wantText"
        }
    }
}
#endregion

#region Secret scanning
# The repo's own read carries the block. GitHub left it out for a private
# repo of a personal account, where the plan offers no secret scanning,
# and returned it with every status on a public one (2026-10-30), so an
# absent block is context and only a disabled status warns. Under
# -AsPublic an absent block warns per key instead: GitHub turns neither on
# at the switch, so claude-plugins read both disabled right after its flip,
# and an [INFO] put neither in the checklist the owner works through
# (2026-11-17).
Step 'Secret scanning'
$analysis = Get-Key $repoJson 'security_and_analysis'
$scanning = [ordered]@{
    'secret_scanning'                 = 'a secret pushed from a clone without the pre-commit hooks reaches the remote unseen'
    'secret_scanning_push_protection' = 'a push carrying a secret is accepted, and found, if at all, only after it is public to every reader'
}
if ($analysis -isnot [System.Collections.IDictionary] -and $AsPublic -and -not $isPublicNow) {
    foreach ($key in $scanning.Keys) {
        Warn "$key unread while the repo is private: turn it on once the repo is public" `
            -Why "$($scanning[$key]); GitHub turns neither key on at the switch" `
            -Fix "after the switch, $patch -f 'security_and_analysis[$key][status]=enabled'"
    }
} elseif ($analysis -isnot [System.Collections.IDictionary]) {
    Info ("security_and_analysis not returned to ${actingAs}: the plan offers no secret scanning " +
        'here, or the account cannot read it')
} else {
    foreach ($key in $scanning.Keys) {
        $status = Get-Key (Get-Key $analysis $key) 'status'
        if ($status -eq 'enabled') {
            Ok "$key is enabled"
        } elseif ($null -eq $status) {
            Info "$key not returned"
        } else {
            $scanFix = "$patch -f 'security_and_analysis[$key][status]=enabled'"
            # Enabling it on a private or internal organization repo is billed
            # per active committer (docs/org-rollout.md, 2026-10-30), so the
            # fix says so before anyone runs it.
            if ($ownerType -eq 'Organization' -and -not $isPublicNow) {
                $scanFix = 'a spend: GitHub Secret Protection bills each active committer here, ' +
                    "so agree it first and read the usage change in the organization's global settings; then $scanFix"
            }
            Warn "$key is $status" -Why $scanning[$key] -Fix $scanFix
        }
    }
    # Context, as the help says. Two public repos of a personal account
    # returned no such key (2026-11-02), so an absent one prints nothing.
    $aiStatus = Get-Key (Get-Key $analysis 'secret_scanning_ai_detection') 'status'
    if ($null -ne $aiStatus) { Info "secret_scanning_ai_detection is $aiStatus" }
}
#endregion

#region Actions token
Step 'Actions token defaults'
# Under releases, Actions off is the ask, judged under Releases below, so
# the token a workflow would carry is not read.
$workflowRead = if ($Policy -ne 'releases') { Invoke-GhApi -Endpoint "repos/$Repo/actions/permissions/workflow" }
if ($Policy -eq 'releases') {
    Info 'not judged under releases: no workflow should run here, as Releases judges below'
} elseif ($workflowRead.ExitCode -ne 0) {
    Warn "could not read the Actions token defaults: $($workflowRead.Text)"
} else {
    $workflow = $workflowRead.Text | ConvertFrom-Json -AsHashtable
    $tokenFix = "gh api -X PUT repos/$Repo/actions/permissions/workflow " +
        '-f default_workflow_permissions=read -F can_approve_pull_request_reviews=false'
    if ($workflow['default_workflow_permissions'] -eq 'read') {
        Ok 'default_workflow_permissions is read'
    } else {
        Fail "default_workflow_permissions is $($workflow['default_workflow_permissions']), want read" `
            -Why ('GitHub says to grant the GITHUB_TOKEN the least required access; a workflow ' +
                'that needs more asks in its own permissions key') -Fix $tokenFix
    }
    if (-not $workflow['can_approve_pull_request_reviews']) {
        Ok 'can_approve_pull_request_reviews is false'
    } else {
        Fail 'can_approve_pull_request_reviews is true, want false' `
            -Why 'GitHub: "Enabling this can be a security risk"' -Fix $tokenFix
    }
}
#endregion

#region Actions pins
# GitHub says to pin each action to a commit SHA, since "a tag can be moved
# or deleted if a bad actor gains access to the repository storing the
# action" (secure-use reference, read 2026-10-30). Warned of under either
# policy, as the help says.
Step 'Actions pins'
$actionsOn = $true
$pinning = $null
$actionsRead = Invoke-GhApi -Endpoint "repos/$Repo/actions/permissions"
if ($actionsRead.ExitCode -ne 0) {
    Warn "could not read the Actions permissions: $($actionsRead.Text)"
} else {
    $actions = $actionsRead.Text | ConvertFrom-Json -AsHashtable
    if (-not (Get-Key $actions 'enabled')) {
        $actionsOn = $false
        Info 'Actions is disabled: no workflow runs, so none is judged'
    } else {
        Info "allowed_actions is $(Get-Key $actions 'allowed_actions')"
        $pinning = Get-Key $actions 'sha_pinning_required'
        if ($pinning -eq $true) {
            Ok 'sha_pinning_required is true'
        } elseif ($null -eq $pinning) {
            Info 'sha_pinning_required not returned'
        } else {
            # The page by choice, said on the line: a report's reader opens no reference (2026-11-03).
            Warn 'sha_pinning_required is false' `
                -Why 'the server runs an action by a tag, which whoever gains its repo can move' `
                -Fix ("$settingsUrl/actions -- Require actions to be pinned to a full-length commit SHA " +
                    '(the page by choice: the REST PUT exists, but its docs leave unsaid what an ' +
                    "omitted allowed_actions becomes; audit-repo's references/profiles.md)")
        }
    }
}

# A use pinned to this repo's own commit, a full commit SHA, or an image
# digest. Anything else names a ref its owner can move. $/ is the
# lockfile's form of a local action, run "at the workflow's commit"
# (GitHub docs, 2026-10-30). A SHA is matched in lower case, as git
# prints one; how GitHub reads one in capitals was not checked, so it warns.
function Test-PinnedUse {
    param([string]$Use)
    if ($Use.StartsWith('./') -or $Use.StartsWith('$/')) { return $true }
    if ($Use.StartsWith('docker://')) { return $Use -cmatch '@sha256:[0-9a-f]{64}$' }
    return $Use -cmatch '@[0-9a-f]{40}$'
}

# The text of a contents API answer for a file, or $null where it carries
# none, as for a file past its size limit.
function ConvertFrom-RepoContent {
    param($File)
    $content = Get-Key $File 'content'
    if ((Get-Key $File 'encoding') -ne 'base64' -or [string]::IsNullOrEmpty($content)) { return $null }
    # FromBase64String skips the line breaks GitHub puts in the text.
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($content))
}

# A file's text on the default branch, or $null where the contents API
# returned none.
function Get-RepoFileText {
    param([string]$FilePath)
    $escaped = @($FilePath -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
    return ConvertFrom-RepoContent (Get-GhJson "repos/$Repo/contents/$escaped")
}

$workflowDir = '.github/workflows'
# What the pre-commit region below reads off the same files: which run the
# hooks, and how many went unread; the Claude Code Action's, which use it
# and which call another repo's reusable workflow; and the board's, their
# names.
$listed = $false
$preCommitRunners = @()
$claudeActionRunners = @()
$reusableCallers = @()
$unreadWorkflows = 0
$workflowNames = @()
if ($actionsOn) {
    # The contents API reads the default branch when given no ref.
    $listRead = Invoke-GhApi -Endpoint "repos/$Repo/contents/$workflowDir"
    $entries = @()
    $listed = $true
    if ($listRead.ExitCode -eq 0) {
        $entries = @($listRead.Text | ConvertFrom-Json -AsHashtable |
                Where-Object { $null -ne $_ -and $_['type'] -eq 'file' })
    } elseif ($listRead.Text -notmatch 'HTTP 404') {
        $listed = $false
        Warn "could not list ${workflowDir}: $($listRead.Text)"
    }
    # The lockfile records each action's commit for the workflows it
    # onboards, keyed by quoted path under workflows:, superseding a pin,
    # but no reusable workflow's, and it names no image (GitHub docs,
    # 2026-10-30). A workflow it does not name runs its tags as written,
    # unless sha_pinning_required blocks them (GitHub docs, 2026-11-02).
    $lockText = ''
    $lockFound = @($entries | Where-Object { $_['name'] -ceq 'actions.lock' }).Count -gt 0
    if ($lockFound) {
        $lockText = "$(Get-RepoFileText "$workflowDir/actions.lock")"
        if ($lockText) {
            Info "$workflowDir/actions.lock found: a workflow it onboards has its actions' tags as context"
        } else {
            Info "$workflowDir/actions.lock found but not read, as the contents API returned no text: every tag warns"
        }
    }
    $workflowFiles = @($entries | Where-Object { $_['name'] -match '\.ya?ml$' })
    $workflowNames = @($workflowFiles | ForEach-Object { $_['name'] })
    $looseFiles = 0
    # Files unread or left to the lockfile: no proof every use is pinned.
    $notProven = 0
    foreach ($entry in $workflowFiles) {
        $path = $entry['path']
        $text = Get-RepoFileText $path
        if ($null -eq $text) {
            Info "${path}: not read, as the contents API returned no text for it"
            $notProven++
            $unreadWorkflows++
            continue
        }
        $lines = @($text -split "`r?`n")
        # The action, or pre-commit run as a command, pre_commit as a module;
        # a comment line runs nothing.
        $hookLines = @($lines | Where-Object {
                $_ -notmatch '^\s*#' -and $_ -match 'pre-commit/action@|\bpre[-_]commit\s+run\b'
            })
        if ($hookLines.Count -gt 0) { $preCommitRunners += $path }
        $uses = @(foreach ($line in $lines) {
                if ($line -match '^\s*(-\s+)?uses:\s*(?<use>[^\s#]+)') { $Matches['use'].Trim('"', "'") }
            })
        # GitHub matches an owner and a repo name in any case.
        if (@($uses | Where-Object { $_ -match '^anthropics/claude-code-action@' }).Count -gt 0) {
            $claudeActionRunners += $path
        }
        # The docs' organization setup may define the job once as a reusable
        # workflow each repo calls, its uses: lines in a repo this run does
        # not read. Only a caller a mention can start counts: shared CI on
        # push or pull_request is no such setup.
        $mentionTriggers = @($lines | Where-Object {
                $_ -notmatch '^\s*#' -and $_ -match '\b(issue_comment|pull_request_review_comment)\b'
            })
        $remoteCalls = @($uses | Where-Object { $_ -match '/\.github/workflows/' -and -not $_.StartsWith('./') })
        if ($mentionTriggers.Count -gt 0 -and $remoteCalls.Count -gt 0) {
            $reusableCallers += $path
        }
        $loose = @($uses | Where-Object { -not (Test-PinnedUse $_) } | Sort-Object -Unique)
        $onboarded = $lockText -cmatch ('(?m)^\s+[''"]?' + [regex]::Escape($path) + '[''"]?\s*:')
        if ($onboarded) {
            $outside = @($loose | Where-Object { $_ -match '/\.github/workflows/' -or $_.StartsWith('docker://') })
            $covered = @($loose | Where-Object { $_ -notin $outside })
            if ($covered.Count -gt 0) {
                Info "${path}: by tag, for the lockfile: $($covered -join ', ')"
                $notProven++
            }
            $loose = $outside
        }
        if ($loose.Count -gt 0) {
            Warn "${path}: $($loose.Count) uses: not pinned to a commit SHA: $($loose -join ', ')" `
                -Why ('GitHub: "a tag can be moved or deleted if a bad actor gains access to the ' +
                    'repository storing the action"') `
                -Fix ('pin each to the commit its tag names, the tag kept as a comment: ' +
                    'uses: <action>@<40-hex SHA> # <tag>')
            $looseFiles++
        }
    }
    # A folder that went unread has its WARN above, never "no workflow".
    if ($listed -and $workflowFiles.Count -eq 0) {
        Info "no workflow files in $workflowDir on $defaultBranch"
    } elseif ($workflowFiles.Count -gt 0 -and $looseFiles -eq 0 -and $notProven -eq 0) {
        Ok "every uses: in the $($workflowFiles.Count) workflow file(s) is pinned"
    }

    # Context, as the help says. The list holds a higher level's policies too,
    # has_parents defaulting to true (REST docs, read 2026-11-02), and a 404,
    # which the docs list and no repo here has answered, is no failed read.
    $policyRead = Invoke-GhApi -Endpoint "repos/$Repo/actions/policies?per_page=100"
    if ($policyRead.ExitCode -eq 0) {
        $policyList = $policyRead.Text | ConvertFrom-Json -AsHashtable
        $policies = @(Get-List $policyList 'policies')
        foreach ($actionsPolicy in $policies) {
            $policyRuleTypes = @(Get-List $actionsPolicy 'rules' | ForEach-Object { Get-Key $_ 'type' })
            $ruleNames = if ($policyRuleTypes.Count -gt 0) { $policyRuleTypes -join ', ' } else { 'none listed' }
            Info ("Actions policy '$(Get-Key $actionsPolicy 'name')', from $(Get-Key $actionsPolicy 'source_type'), " +
                "$(Get-Key $actionsPolicy 'enforcement'): rules $ruleNames")
        }
        $policyTotal = Get-Key $policyList 'total_count'
        if ($policyTotal -gt $policies.Count) {
            Info "only the first $($policies.Count) of $policyTotal Actions policies read"
        } elseif ($policies.Count -eq 0) {
            Info 'no Actions policy applies here'
        }
        $activePolicies = @($policies | Where-Object { (Get-Key $_ 'enforcement') -eq 'active' })
        if ($lockFound -and $activePolicies.Count -eq 0 -and $policyTotal -le $policies.Count) {
            # The pin rule blocks a workflow the lockfile does not onboard
            # where a uses: names a tag or branch, and passes one pinned by
            # full SHAs, which only Require lockfile blocks (GitHub docs,
            # read 2026-11-02). Unread, the rule is said to be unread, not off.
            $unonboardedNote = if ($pinning -eq $true) {
                'a workflow it does not onboard runs unless a uses: names a tag or branch, ' +
                'which sha_pinning_required blocks'
            } elseif ($pinning -eq $false) {
                'nothing blocks a workflow it does not onboard'
            } else {
                'whether sha_pinning_required blocks a workflow it does not onboard was not read'
            }
            Info "$workflowDir/actions.lock found, with no active Actions policy: $unonboardedNote"
        }
    } elseif ($policyRead.Text -match 'HTTP 404') {
        Info 'Actions policies not read: GitHub answered 404'
    } else {
        Warn "could not read the Actions policies: $($policyRead.Text)"
    }
}
#endregion

#region Releases
# The releases policy's own checks, for a repo holding only an app's
# installers and update feed, its source elsewhere. The two the
# policy exists for fail, the rest warn (the user, 2026-11-10); the default
# branch's guard is judged with the other policies' below.
if ($Policy -eq 'releases') {
    Step 'Releases'
    # GitHub answers 200 with enabled where immutable releases are on, 404
    # where they are off, and asks for admin read access (REST "Check if
    # immutable releases are enabled for a repository", read 2026-11-10),
    # so a 404 to an account without it is not judged.
    $immutableRead = Invoke-GhApi -Endpoint "repos/$Repo/immutable-releases"
    # Immutability binds only releases published after the switch (GitHub's
    # "Preventing changes to your releases", read 2026-11-10). The why says
    # so, keeping the fix a command that runs as printed.
    $immutableWhy = ("a published release's assets can be replaced and its tag moved, so a download " +
        'or the update feed can serve a file other than the one released; turning it on binds only ' +
        'releases published afterwards, and earlier ones stay mutable')
    $immutableFix = "gh api -X PUT repos/$Repo/immutable-releases"
    $immutable = if ($immutableRead.ExitCode -eq 0) { $immutableRead.Text | ConvertFrom-Json -AsHashtable }
    if ($null -ne $immutable -and (Get-Key $immutable 'enabled') -eq $true) {
        Ok 'immutable releases are enabled'
        if ((Get-Key $immutable 'enforced_by_owner') -eq $true) { Info 'immutable releases are enforced by the owner' }
    } elseif ($immutableRead.ExitCode -eq 0 -or ($immutableRead.Text -match 'HTTP 404' -and $isAdmin)) {
        Fail 'immutable releases are disabled' -Why $immutableWhy -Fix $immutableFix
    } elseif ($immutableRead.Text -match 'HTTP 404') {
        Info "immutable releases not judged: GitHub answers 404 for off, and asks for admin rights, which $actingAs lacks"
    } else {
        Warn "could not read immutable releases: $($immutableRead.Failure)"
    }

    # With Actions off, a token that can write contents and workflows, a
    # classic token's workflow scope or a fine-grained one's Workflows
    # permission, which GitHub asks for to write .github/workflows/ (REST
    # "Create or update file contents" and "Permissions required for
    # fine-grained personal access tokens", read 2026-11-10), cannot add a
    # workflow here that runs. Only enabled is required by the PUT (REST
    # docs, read 2026-11-10).
    if ($actionsRead.ExitCode -ne 0) {
        Info 'Actions not judged: its permissions went unread, as warned above'
    } elseif ($actionsOn) {
        Fail 'Actions is enabled' `
            -Why ('nothing is built here, and a token that can write contents and workflows, a ' +
                'classic token''s workflow scope or a fine-grained one''s Workflows permission, ' +
                'can add a workflow that then runs with this repo''s token') `
            -Fix "gh api -X PUT repos/$Repo/actions/permissions -F enabled=false"
    } else {
        Ok 'Actions is disabled'
    }

    $features = [ordered]@{
        'has_issues'   = 'no work lands here to track: the README routes reports to the source repo''s issues, or to this repo''s Discussions where the source is private'
        'has_wiki'     = 'a second place to document the app, apart from its source, that no one keeps'
        'has_projects' = 'a board here tracks no work, since none lands here'
    }
    foreach ($key in $features.Keys) {
        $value = Get-Key $repoJson $key
        if ($value -eq $false) { Ok "$key is false" }
        elseif ($null -eq $value) { Info "$key not returned" }
        else { Warn "$key is true, want false" -Why $features[$key] -Fix "$patch -F $key=false" }
    }

    # With issues off, a downloader needs another route to report a problem:
    # this repo's Discussions, a mailto: or the issues or Discussions of
    # another repo. A linked repo's tracker leads nowhere where the repo is
    # private, archived or has that tracker off, so the repo is read.
    # has_discussions is judged only here, as a
    # route, never as a feature to turn off. The README text comes from its
    # own read: the community profile's readme entry says only whether one
    # exists.
    $issuesOn = Get-Key $repoJson 'has_issues'
    $discussionsOn = Get-Key $repoJson 'has_discussions'
    if ($issuesOn -eq $true) {
        # The has_issues WARN above stands for this one.
    } elseif ($null -eq $issuesOn -or $null -eq $discussionsOn) {
        Info 'report route not judged: has_issues or has_discussions was not returned'
    } elseif ($discussionsOn -eq $true) {
        Ok 'downloaders can report in Discussions: has_discussions is true'
    } else {
        $routeWhy = 'downloaders have nowhere to report a problem: issues and Discussions are both off'
        $routeFix = ("gh repo edit $Repo --enable-discussions, then a README line linking " +
            "https://github.com/$Repo/discussions/categories/q-a")
        $readmeRead = Invoke-GhApi -Endpoint "repos/$Repo/readme"
        $readmeText = $null
        $readmeCause = ''
        if ($readmeRead.ExitCode -eq 0) {
            try {
                $readmeJson = $readmeRead.Text | ConvertFrom-Json -AsHashtable
                $encoded = "$(Get-Key $readmeJson 'content')" -replace '\s', ''
                $readmeText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
            } catch {
                $readmeText = $null
                $readmeCause = 'its content did not decode'
            }
        } elseif ($readmeRead.Text -match 'HTTP 404') {
            $readmeText = ''
        } else {
            $readmeCause = $readmeRead.Failure
        }
        if ($null -eq $readmeText) {
            Info "report route not judged: the README went unread: $readmeCause"
        } else {
            # mailto: is a route; so is the issues or Discussions of another repo
            # that others can read and that has that tracker on. A link to this
            # repo's own is no route, both being off here.
            $routeFound = $readmeText -match 'mailto:'
            $routeUnread = @()
            # Each linked repo, case-blind as GitHub reads its names, with the
            # trackers its links name: its issues and Discussions can each be off.
            $sources = [ordered]@{}
            # The owner takes -Repo's own shape, and a name of . or .. is
            # dropped, so a README's text never walks the API path.
            $linkPattern = ('https://github\.com/(?<owner>[A-Za-z0-9_-]+)/(?<name>[A-Za-z0-9_.-]+)/' +
                '(?<kind>issues|discussions)\b')
            $linkOptions = [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
            foreach ($link in [regex]::Matches($readmeText, $linkPattern, $linkOptions)) {
                $linkedName = $link.Groups['name'].Value
                $linked = "$($link.Groups['owner'].Value)/$linkedName"
                if (($linkedName -in '.', '..') -or ($linked -ieq $Repo)) { continue }
                if (-not $sources.Contains($linked)) { $sources[$linked] = [ordered]@{} }
                $sources[$linked]["has_$($link.Groups['kind'].Value.ToLowerInvariant())"] = $true
            }
            foreach ($linked in $sources.Keys) {
                if ($routeFound) { break }
                $sourceRead = Invoke-GhApi -Endpoint "repos/$linked"
                $sourceJson = $null
                if ($sourceRead.ExitCode -eq 0) {
                    try { $sourceJson = $sourceRead.Text | ConvertFrom-Json -AsHashtable } catch { $sourceJson = $null }
                }
                $isPrivate = Get-Key $sourceJson 'private'
                $trackers = @($sources[$linked].Keys)
                $trackersOn = @($trackers | ForEach-Object { Get-Key $sourceJson $_ })
                if ($isPrivate -eq $true) {
                    Info "the README's link to $linked leads nowhere: it is private"
                } elseif ($null -eq $isPrivate) {
                    $cause = if ($sourceRead.ExitCode -ne 0) { $sourceRead.Failure } else { 'private not returned' }
                    $routeUnread += "$linked ($cause)"
                } elseif ((Get-Key $sourceJson 'archived') -eq $true) {
                    # An archived repo's issues are read-only (GitHub's
                    # "Archiving repositories"), so no one can report there.
                    Info "the README's link to $linked leads nowhere: it is archived"
                } elseif ($trackersOn -contains $true) {
                    $routeFound = $true
                } elseif ($trackersOn -contains $null) {
                    $missing = @($trackers | Where-Object { $null -eq (Get-Key $sourceJson $_) })
                    $routeUnread += "$linked ($($missing -join ' or ') not returned)"
                } else {
                    Info ("the README's link to $linked leads nowhere: its " +
                        "$(($trackers -replace '^has_', '') -join ' and ') are off")
                }
            }
            if ($routeFound) {
                Ok 'the README names a route for reports'
            } elseif ($routeUnread.Count -gt 0) {
                Info "report route not judged: could not read whether $($routeUnread -join ', ') takes reports"
            } else {
                Warn 'issues and Discussions are off, and the README names no route for reports' `
                    -Why $routeWhy -Fix $routeFix
            }
        }
    }
}
#endregion

#region Security route
# A releases repo's downloaders have a public route for a problem,
# and a hole in the installer or the update feed reported there is
# disclosed before it is fixed. Private vulnerability reporting adds a
# private one, a report form on the Security and quality tab that a public repo's
# owners turn on (GitHub's "Configuring private vulnerability reporting for
# a repository", read 2026-11-13). Under releases it warns when off and a
# missing security policy is context, the policy being a scaffold; on any
# other public repo the two are one context line (the user, 2026-11-13).
if ($Policy -eq 'releases' -or $isPublicNow) {
    Step 'Security route'
    # The GET answered {"enabled": ...} to an account without admin rights
    # on two public repos, and 404 on a private one, where the setting does
    # not exist (measured 2026-11-13, gh 2.103.3); the REST docs name no
    # permission for it. So a 404 or a refusal is not judged.
    $reportingRead = Invoke-GhApi -Endpoint "repos/$Repo/private-vulnerability-reporting"
    $reporting = $null
    $reportingCause = 'enabled not returned'
    if ($reportingRead.ExitCode -eq 0) {
        try {
            $reporting = Get-Key ($reportingRead.Text | ConvertFrom-Json -AsHashtable) 'enabled'
        } catch {
            $reportingCause = 'its answer did not parse'
        }
    } else {
        $reportingCause = $reportingRead.Failure
    }
    # The community profile's REST schema lists no security policy, so
    # GraphQL's isSecurityPolicyEnabled is read, GitHub's own finding (both
    # read 2026-11-13): true for a repo with a root SECURITY.md and false
    # for one with none (2026-11-13).
    $securityOwner, $securityName = $Repo.Split('/')
    $securityQuery = 'query SecurityPolicy($owner: String!, $name: String!) { repository(owner: $owner, ' +
        'name: $name) { isSecurityPolicyEnabled securityPolicyUrl } }'
    $securityRead = Invoke-GhQuery -Query $securityQuery -Variables @{ owner = $securityOwner; name = $securityName }
    $securityRepo = $null
    $securityCause = 'isSecurityPolicyEnabled not returned'
    if ($securityRead.ExitCode -eq 0) {
        try {
            $securityRepo = Get-Key (Get-Key ($securityRead.Text | ConvertFrom-Json -AsHashtable) 'data') 'repository'
        } catch {
            $securityCause = 'its answer did not parse'
        }
    } else {
        $securityCause = $securityRead.Failure
    }
    $hasSecurityPolicy = Get-Key $securityRepo 'isSecurityPolicyEnabled'
    $securityPolicyUrl = Get-Key $securityRepo 'securityPolicyUrl'

    if ($Policy -eq 'releases') {
        if ($reporting -eq $true) {
            Ok 'private vulnerability reporting is enabled'
        } elseif ($reporting -eq $false) {
            Warn 'private vulnerability reporting is disabled' `
                -Why ('a hole in the installer or the update feed has only public routes to report it, ' +
                    'which disclose it before it is fixed') `
                -Fix "gh api -X PUT repos/$Repo/private-vulnerability-reporting"
        } elseif (-not $isPublicNow) {
            $later = if ($AsPublic) { ': turn it on once the repo is public' } else { '' }
            Info "private vulnerability reporting not judged: GitHub offers it on a public repo alone$later"
        } else {
            Info "private vulnerability reporting not judged: $reportingCause"
        }
        if ($hasSecurityPolicy -eq $true) {
            Ok "a security policy is found: $securityPolicyUrl"
        } elseif ($hasSecurityPolicy -eq $false) {
            Info 'no security policy: a SECURITY.md naming the private route is offered as a scaffold'
        } else {
            Info "security policy not read: $securityCause"
        }
    } else {
        $reportingState = if ($reporting -eq $true) { 'enabled' }
        elseif ($reporting -eq $false) { 'disabled' }
        else { "unread ($reportingCause)" }
        $securityState = if ($hasSecurityPolicy -eq $true) { "found, $securityPolicyUrl" }
        elseif ($hasSecurityPolicy -eq $false) { 'none' }
        else { "unread ($securityCause)" }
        Info "context under ${Policy}: private vulnerability reporting $reportingState; security policy $securityState"
    }
}
#endregion

#region Pre-commit in CI
# The hooks gate only a clone where `pre-commit install` ran: a clone without
# them, an outside pull request and a commit made in GitHub's web editor skip
# every one, and only a workflow runs them on the server. Warned of on a
# public repo alone, as the personal policy's branch guard is (the user,
# 2026-11-03), and context on any other.
Step 'Pre-commit in CI'
$hookConfig = '.pre-commit-config.yaml'
$configRead = Invoke-GhApi -Endpoint "repos/$Repo/contents/$hookConfig"
if ($configRead.ExitCode -ne 0) {
    if ($configRead.Text -match 'HTTP 404') {
        Info "no $hookConfig on $defaultBranch"
    } else {
        Warn "could not read ${hookConfig}: $($configRead.Text)"
    }
} elseif ($preCommitRunners.Count -gt 0) {
    Ok "pre-commit runs on the server: $($preCommitRunners -join ', ')"
} elseif ($actionsOn -and -not $listed) {
    # The listing's WARN above stands for this one.
    Info "whether a workflow runs $hookConfig's hooks was not read"
} elseif ($unreadWorkflows -gt 0) {
    Info "no workflow read runs pre-commit, and $unreadWorkflows went unread"
} else {
    $noRunner = if ($actionsOn) { 'no workflow runs pre-commit' } else { 'Actions is disabled' }
    $hookGap = "$hookConfig on $defaultBranch, and $noRunner"
    if ($Policy -eq 'releases') {
        # Its fix would turn Actions on, which Releases above fails.
        Info "${hookGap}: context under releases, where Actions is meant to be off"
    } elseif ($isPublic) {
        $runnerFix = ("a workflow running pre-commit run --all-files on push and pull_request, " +
            "which the skill's step 8 scaffolds")
        if (-not $actionsOn) { $runnerFix = "$settingsUrl/actions -- allow actions, then $runnerFix" }
        Warn $hookGap `
            -Why ('its hooks gate only a clone where pre-commit install ran: a clone without them, ' +
                'an outside pull request and a commit made on GitHub skip every one') `
            -Fix $runnerFix
    } else {
        Info "${hookGap}: context on a repo that is $($repoJson['visibility'])"
    }
}
#endregion

#region Claude Code Action
# An organization's repo is offered the Claude Code GitHub Action, the
# workflow that answers an @claude mention: context alone, and shown
# whatever the collaborator count, since no read tells whether a
# co-developer would mention @claude, and the offer waits for its own yes.
# personal keeps the Action out, and no work lands in a releases repo.
# Read off the uses: lines the pins region read, so a workflow left unread
# is said, never taken for none.
if ($Policy -in @('org-internal', 'org-published')) {
    Step 'Claude Code Action'
    $claudeAction = 'anthropics/claude-code-action'
    if ($claudeActionRunners.Count -gt 0) {
        Info "$claudeAction runs in $($claudeActionRunners -join ', ')"
    } elseif (-not $actionsOn) {
        Info "no workflow runs ${claudeAction}, as Actions is disabled: $settingsUrl/actions allows it"
    } elseif (-not $listed) {
        # The listing's WARN above stands for this one.
        Info "whether a workflow runs $claudeAction was not read"
    } elseif ($unreadWorkflows -gt 0) {
        Info "no workflow read runs $claudeAction, and $unreadWorkflows went unread"
    } elseif ($reusableCallers.Count -gt 0) {
        # It may run the Action, and a second workflow would answer each
        # mention twice, so the skill asks before offering.
        Info ("no workflow on $defaultBranch runs $claudeAction itself, and " +
            "$($reusableCallers -join ', ') call(s) another repo's reusable workflow on a comment, not read")
    } else {
        Info ("no workflow on $defaultBranch runs ${claudeAction}, so an @claude mention starts nothing: " +
            "the skill's step 8 offers it")
    }
}
#endregion

#region Rulesets
Step 'Rulesets'
$rulesets = @()
$rulesetRead = Invoke-GhApi -Endpoint "repos/$Repo/rulesets"
if ($rulesetRead.ExitCode -ne 0) {
    Warn "could not list rulesets: $($rulesetRead.Text)" `
        -Why 'rulesets need GitHub Team or Enterprise for a private or internal repo'
} else {
    foreach ($summary in @($rulesetRead.Text | ConvertFrom-Json -AsHashtable)) {
        if ($null -eq $summary) { continue }
        $rulesets += , (Get-GhJson "repos/$Repo/rulesets/$($summary['id'])")
    }
}
if ($rulesets.Count -eq 0) { Info 'no rulesets, at this level or above' }
foreach ($ruleset in $rulesets) {
    $source = Get-Key $ruleset 'source_type'
    Info ("ruleset '$($ruleset['name'])': target $($ruleset['target']), $($ruleset['enforcement']), " +
        "from $source")
    if ($ruleset['enforcement'] -ne 'active') {
        Info "  not enforced, so none of its rules are among the active rules below"
    }
}

# The default branch's active rules, from rulesets at any level. Rulesets
# set to evaluate or disabled are left out by GitHub.
$branchRules = @()
$branchRulesRead = Invoke-GhApi -Endpoint "repos/$Repo/rules/branches/$defaultBranch"
if ($branchRulesRead.ExitCode -eq 0) {
    $branchRules = @($branchRulesRead.Text | ConvertFrom-Json -AsHashtable | Where-Object { $null -ne $_ })
} else {
    Warn "could not read the active rules on ${defaultBranch}: $($branchRulesRead.Text)"
}
# An unread list is empty, so every check below that reads a rule as absent
# would claim what it never saw: each says "not judged" instead.
$rulesUnread = $branchRulesRead.ExitCode -ne 0
$notRead = "the active rules on $defaultBranch did not read"
$ruleTypes = @($branchRules | ForEach-Object { $_['type'] } | Sort-Object -Unique)
$branchRulesetIds = @($branchRules | ForEach-Object { $_['ruleset_id'] } | Sort-Object -Unique)

# Every active ruleset's bypass list, whatever it targets: while only the
# default branch's were read, a branch-name ruleset that a deploy key
# bypassed always went unreported (an organization's repo, 2026-10-26).
foreach ($ruleset in @($rulesets | Where-Object { $_['enforcement'] -eq 'active' })) {
    $name = $ruleset['name']
    $scope = if ($ruleset['id'] -in $branchRulesetIds) { $defaultBranch } else { 'the refs it targets' }
    if (-not $ruleset.Contains('bypass_actors')) {
        Warn "ruleset '$name': bypass list not returned to $actingAs" `
            -Why 'GitHub returns it only to an account with write access to the ruleset'
        continue
    }
    # A bypass covers the whole ruleset, so one that holds the guard rules
    # beside a pull request rule lets its bypassing admin force-push or
    # delete the branch too (an organization's repo, 2026-11-04). A
    # pull_request bypass still needs a pull request, so only always and
    # exempt pass the guard.
    $guardHeld = @(@(Get-List $ruleset 'rules') | ForEach-Object { $_['type'] } |
            Where-Object { $_ -in 'deletion', 'non_fast_forward' } | Sort-Object -Unique)
    $guardWhy = ''
    $guardFix = $null
    if ($guardHeld.Count -gt 0) {
        $guardWhy = "; it holds $($guardHeld -join ' and ') too, so that actor can also force-push or delete"
        $guardFix = ("move deletion and non_fast_forward to a ruleset of their own with no bypass: " +
            "audit-repo's ruleset-guard.json scaffold, then drop them here")
    }
    foreach ($actor in @($ruleset['bypass_actors'])) {
        if ($null -eq $actor) { continue }
        # A DeployKey actor may carry no id.
        $actorId = Get-Key $actor 'actor_id'
        $who = if ($null -ne $actorId) { "$($actor['actor_type']) $actorId" } else { "$($actor['actor_type'])" }
        switch ($actor['bypass_mode']) {
            'always' {
                Warn "ruleset '$name': $who bypasses always" `
                    -Why ("a bypassing actor's push to $scope is accepted and skips every rule " +
                        "the ruleset sets, with no error$guardWhy") `
                    -Fix $guardFix
            }
            'pull_request' {
                Warn "ruleset '$name': $who bypasses on pull requests" `
                    -Why ("GitHub: it can bypass rules on pull requests, so it can merge one into " +
                        "$scope without its review or checks; fine while one person maintains it")
            }
            'exempt' {
                Warn "ruleset '$name': $who is exempt" `
                    -Why ('GitHub: rules are not run for that actor and no bypass audit entry is created' +
                        $guardWhy) `
                    -Fix $guardFix
            }
            default { Info "ruleset '$name': $who, bypass mode $($actor['bypass_mode'])" }
        }
    }
}

# Branch names: context, on an organization's repo alone, since GitHub's
# docs put metadata rules under Enterprise Cloud (read 2026-11-04).
if ($ownerType -eq 'Organization' -and $rulesetRead.ExitCode -eq 0) {
    $namers = @($rulesets | Where-Object { $_['enforcement'] -eq 'active' } | Where-Object {
            $candidate = $_
            @(Get-List $candidate 'rules' | Where-Object { $_['type'] -eq 'branch_name_pattern' }).Count -gt 0
        } | ForEach-Object { "'$($_['name'])'" })
    if ($namers.Count -gt 0) {
        Info "branch names: ruleset $($namers -join ', ') holds a branch_name_pattern rule"
    } else {
        Info ("branch names: no branch_name_pattern rule is active; audit-repo's ruleset-branch-names.json " +
            'scaffold holds every other branch to <type>/<kebab-slug>, where the plan offers metadata rules')
    }
}

# The branch's own protected flag is true under a ruleset alone, with the
# classic endpoint answering 404 "Branch not protected" (measured
# 2026-10-22), so only that endpoint says whether classic protection is on.
$headSha = (Get-GhJson "repos/$Repo/branches/$defaultBranch")['commit']['sha']
# Set before the branch that reads it, which strict mode needs below.
$classic = $null
if ($isAdmin) {
    $classic = Get-GhJson "repos/$Repo/branches/$defaultBranch/protection" -NotFoundIsAnswer
    if ($null -ne $classic) {
        # The route out is the changelog's, 2026-10-20: the docs page still
        # describes only converting one rule at a time (read 2026-11-01).
        Info ("classic branch protection is on for ${defaultBranch}: not audited, and enforced beside any ruleset; " +
            "to move it, $settingsUrl/rules -- Import branch protection rules, which previews the rulesets " +
            'and offers to keep or delete the originals')
    }
} else {
    Info 'classic branch protection not read: it needs admin rights'
}
#endregion

#region Deploy keys
# A key that can write pushes from wherever it is stored, and is usually
# why a ruleset names a DeployKey bypass (an organization's repo,
# 2026-10-26). Listing keys needs admin rights.
Step 'Deploy keys'
if (-not $isAdmin) {
    Info 'deploy keys not read: listing them needs admin rights'
} else {
    $keysRead = Invoke-GhApi -Endpoint "repos/$Repo/keys?per_page=100"
    if ($keysRead.ExitCode -ne 0) {
        Warn "could not read the deploy keys: $($keysRead.Text)"
    } else {
        $deployKeys = @($keysRead.Text | ConvertFrom-Json -AsHashtable | Where-Object { $null -ne $_ })
        if ($deployKeys.Count -eq 0) { Ok 'no deploy keys' }
        foreach ($deployKey in $deployKeys) {
            # ConvertFrom-Json turns an ISO time into a DateTime, which a
            # string prints in the console's culture.
            $created = Get-Key $deployKey 'created_at'
            $added = if ($created -is [datetime]) {
                $created.ToUniversalTime().ToString('yyyy-MM-dd')
            } else { "$created" }
            $label = "deploy key '$(Get-Key $deployKey 'title')', added $added"
            if (Get-Key $deployKey 'read_only') {
                Info "$label, read-only"
            } else {
                Warn "$label, can write" `
                    -Why 'it pushes as no person, past any rule a DeployKey bypass waives' `
                    -Fix "$settingsUrl/keys -- where nothing pushes with it, delete it and add it again read-only"
            }
        }
    }
}
#endregion

#region Environments
# A job naming an environment gets its secrets and an OIDC subject,
# repo:<owner>/<repo>:environment:<name>, that names no branch, and an
# environment's deployment branches default to no restriction (GitHub
# docs, read 2026-11-17). So with no branch policy, any branch, and a
# workflow_dispatch run against one, deploys as whatever trusts it.
# Listing environments takes read access alone. Protected branches only
# is context: it lets every branch deploy while none is protected, which
# this script does not total.
Step 'Environments'
$environmentsRead = Invoke-GhApi -Endpoint "repos/$Repo/environments?per_page=100"
if ($environmentsRead.ExitCode -ne 0) {
    Warn "could not read the environments: $($environmentsRead.Failure)"
} else {
    $environmentList = $environmentsRead.Text | ConvertFrom-Json -AsHashtable
    # @(): a function's empty array arrives as $null, whose .Count strict mode refuses.
    $environments = @(Get-List $environmentList 'environments')
    $environmentTotal = Get-Key $environmentList 'total_count'
    if ($environments.Count -eq 0) { Ok 'no environments' }
    if ($environmentTotal -gt $environments.Count) {
        Info "only the first $($environments.Count) of $environmentTotal environments read"
    }
    foreach ($environment in $environments) {
        $environmentName = Get-Key $environment 'name'
        # Not $policy: variable names ignore case, and that is -Policy.
        $branchPolicy = Get-Key $environment 'deployment_branch_policy'
        if ($null -eq $branchPolicy) {
            Warn "environment '$environmentName': any branch can deploy to it" `
                -Why ('a job naming it from any branch gets its secrets and its OIDC subject, ' +
                    'which names no branch') `
                -Fix ("$settingsUrl/environments -- Deployment branches and tags: " +
                    'Selected branches and tags; provision-deploy-identity sets them ' +
                    'before any credential trusts it')
        } elseif (Get-Key $branchPolicy 'custom_branch_policies') {
            Ok "environment '$environmentName' deploys from selected branches and tags"
        } else {
            Info ("environment '$environmentName' deploys from protected branches only, " +
                'every branch while none is protected')
        }
    }
}
#endregion

#region Pull request limits
# Context, as the help says. A private repo answers 405, "Interaction limits
# are not available for private repositories" (2026-11-02), and limits bind
# only people without write access, so only a public repo is read.
Step 'Pull request limits'
if (-not $isPublicNow) {
    Info 'pull request limits not read: GitHub offers them on a public repo alone'
} elseif (-not $isAdmin) {
    Info 'pull request limits not read: they need admin rights'
} else {
    $capRead = Invoke-GhApi -Endpoint "repos/$Repo/interaction-limits/pulls/creation-cap"
    if ($capRead.ExitCode -ne 0) {
        Warn "could not read the pull request cap: $($capRead.Text)"
    } else {
        $cap = $capRead.Text | ConvertFrom-Json -AsHashtable
        if (Get-Key $cap 'enabled') {
            $drafts = if (Get-Key $cap 'include_drafts') { 'counted' } else { 'not counted' }
            Info "pull request cap is on: $(Get-Key $cap 'max_open_pull_requests') open per person, drafts $drafts"
        } else {
            Info 'pull request cap is off'
        }
    }
    $bypassRead = Invoke-GhApi -Endpoint "repos/$Repo/interaction-limits/pulls/bypass-list"
    if ($bypassRead.ExitCode -ne 0) {
        Warn "could not read the pull request cap's bypass list: $($bypassRead.Text)"
    } else {
        $bypassLogins = @($bypassRead.Text | ConvertFrom-Json -AsHashtable | Where-Object { $null -ne $_ } |
                ForEach-Object { Get-Key $_ 'login' })
        if ($bypassLogins.Count -gt 0) { Info "pull request cap bypass list: $($bypassLogins -join ', ')" }
    }
}
#endregion

#region Default branch rules
Step "Active rules on $defaultBranch"
if ($ruleTypes.Count -gt 0) { Info "active: $($ruleTypes -join ', ')" }
$rulesetFix = "$settingsUrl/rules -- a branch ruleset targeting ~DEFAULT_BRANCH"
# The skill's scaffolds create each ruleset by API on the user's yes
# (references/scaffolds.md, Branch rulesets); a fix line names its file.
$guardScaffold = "or audit-repo's ruleset-guard.json scaffold"

if ('required_linear_history' -in $ruleTypes -and 'pull_request' -in $ruleTypes) {
    Fail 'required_linear_history beside a pull_request rule' `
        -Why 'pull requests into the branch must then squash or rebase, so no merge keeps the split' `
        -Fix $rulesetFix
}
foreach ($rule in @($branchRules | Where-Object { $_['type'] -eq 'pull_request' })) {
    $parameters = Get-Key $rule 'parameters'
    $methods = @(Get-List $parameters 'allowed_merge_methods')
    $rewriting = @($methods | Where-Object { $_ -in 'squash', 'rebase' })
    if ($rewriting.Count -gt 0) {
        Fail "a pull_request rule allows $($rewriting -join ' and ')" `
            -Why 'the merge box then offers a merge that collapses or rewrites the branch' `
            -Fix "$rulesetFix; allowed merge methods: merge only"
    } elseif ($methods.Count -gt 0) {
        Ok "pull requests merge by $($methods -join ', ')"
    }
    # Whether an approval outlives a new push, which matters once code
    # owners review (an organization's repo kept both off, 2026-10-26).
    $dismissStale = [bool](Get-Key $parameters 'dismiss_stale_reviews_on_push')
    $lastPush = [bool](Get-Key $parameters 'require_last_push_approval')
    Info ("pull requests: dismiss_stale_reviews_on_push $("$dismissStale".ToLowerInvariant()), " +
        "require_last_push_approval $("$lastPush".ToLowerInvariant())")
}
# GitHub enforces the strictest of every pull_request rule on the branch,
# so a rule from one ruleset can dismiss what another's code owner gave.
$pullParameters = @($branchRules | Where-Object { $_['type'] -eq 'pull_request' } |
        ForEach-Object { Get-Key $_ 'parameters' })
$ownerReview = @($pullParameters | Where-Object { Get-Key $_ 'require_code_owner_review' }).Count -gt 0
$staleDismissed = @($pullParameters | Where-Object { Get-Key $_ 'dismiss_stale_reviews_on_push' }).Count -gt 0
if ($ownerReview -and -not $staleDismissed) {
    Warn 'a code owner review is required, and an approval survives a new push' `
        -Why 'a change pushed after the approval merges on it, unreviewed by its code owner' `
        -Fix "$rulesetFix; dismiss stale pull request approvals when new commits are pushed"
}

if ($Policy -eq 'org-published') {
    $wanted = [ordered]@{
        'pull_request'           = 'changes reach the branch that publishes only through a pull request'
        'required_status_checks' = 'nothing else stops a change that fails CI from merging'
        'non_fast_forward'       = 'a force push can rewrite what has already published'
        'deletion'               = 'the branch that publishes can be deleted'
    }
    foreach ($type in $wanted.Keys) {
        if ($rulesUnread) { Info "$type not judged: $notRead" }
        elseif ($type -in $ruleTypes) { Ok "$type is active" }
        else {
            $scaffold = if ($type -in 'deletion', 'non_fast_forward') { $guardScaffold }
            else { "or audit-repo's ruleset-pull-request.json scaffold" }
            Fail "no active $type rule on $defaultBranch" -Why $wanted[$type] -Fix "$rulesetFix, $scaffold"
        }
    }
    $pullRules = @($branchRules | Where-Object { $_['type'] -eq 'pull_request' })
    $codeOwnerReview = @($pullRules | Where-Object {
            Get-Key (Get-Key $_ 'parameters') 'require_code_owner_review' })
    if ($pullRules.Count -gt 0 -and $codeOwnerReview.Count -eq 0) {
        Fail 'no pull_request rule requires a code owner review' `
            -Why 'the policy hands each folder to its maintainer through CODEOWNERS' `
            -Fix ("$rulesetFix; require review from Code Owners, once a CODEOWNERS file on " +
                "$defaultBranch names an owner: until then the rule asks no one's review")
    }
} elseif ((($Policy -in @('personal', 'org-internal')) -and $isPublic) -or $Policy -eq 'releases') {
    # Warned, never failed, as hardening is (the user, 2026-11-03). A
    # fast-forward push trips neither rule: land-branch's default route
    # pushed main through such a ruleset, no bypass, on another public
    # personal repo, exit 0 (2026-11-02). The reason holds whoever owns the
    # repo, so org-internal takes it too, on a public repo alone (the user,
    # 2026-11-03); a private one keeps the line below. releases takes it on
    # any visibility, as a releases repo was set up with it (the user,
    # 2026-11-10).
    $guards = if ($Policy -eq 'releases') {
        # A releases repo may be private, so its reasons name no visibility.
        [ordered]@{
            'non_fast_forward' = 'a force push can rewrite the history of the branch whose README downloaders read'
            'deletion'         = 'no rule stops the branch holding the README downloaders read from being deleted'
        }
    } else {
        [ordered]@{
            'non_fast_forward' = 'a force push can drop commits that clones and forks of a public repo have fetched'
            'deletion'         = 'no rule stops the branch a public repo serves from being deleted'
        }
    }
    # Classic protection blocks both by default, but binds an admin only
    # under "Do not allow bypassing the above settings" (GitHub's About
    # protected branches, read 2026-11-03), so the warning stands and its
    # reason names what to check.
    $classicSettings = @{ 'non_fast_forward' = 'Allow force pushes'; 'deletion' = 'Allow deletions' }
    foreach ($type in $guards.Keys) {
        if ($rulesUnread) { Info "$type not judged: $notRead" }
        elseif ($type -in $ruleTypes) { Ok "$type is active" }
        else {
            $why = $guards[$type]
            if ($null -ne $classic) {
                $why += ("; classic protection on $defaultBranch blocks this unless its " +
                    "$($classicSettings[$type]) is on, but an admin passes it unless Do not allow " +
                    'bypassing the above settings is on: check both, or import it to a ruleset')
            }
            Warn "no active $type rule on $defaultBranch" -Why $why `
                -Fix ("$rulesetFix, with Restrict deletions and Block force pushes alone and no " +
                    "pull request rule, so land-branch still lands by fast-forward; $guardScaffold")
        }
    }
} elseif ($rulesUnread) {
    Info "rules on $defaultBranch not judged: $notRead"
} else {
    # personal or org-internal on a private repo: offered, never warned of
    # (the user, 2026-11-04). GitHub's plans page lists protected branches
    # in private repos under Pro and Team, not Free (read 2026-11-04).
    foreach ($type in 'non_fast_forward', 'deletion') {
        if ($type -in $ruleTypes) { Ok "$type is active" }
        else {
            Info ("no active $type rule on ${defaultBranch}: audit-repo's ruleset-guard.json scaffold " +
                'blocks force pushes and deletion and still lets land-branch fast-forward; ' +
                'a private repo needs a paid plan for it')
        }
    }
}
#endregion

#region Required checks
Step 'Required status checks'
$required = @($branchRules | Where-Object { $_['type'] -eq 'required_status_checks' } | ForEach-Object {
        $checkRule = $_
        @(Get-List (Get-Key $checkRule 'parameters') 'required_status_checks') | ForEach-Object { $_['context'] }
    } | Sort-Object -Unique)
if ($rulesUnread) {
    Info "required checks not judged: $notRead"
} elseif ($required.Count -eq 0) {
    Info 'no required status checks'
} else {
    $shas = @($headSha)
    $pulls = Get-GhJson "repos/$Repo/pulls?state=all&sort=updated&direction=desc&per_page=5"
    $shas += @(@($pulls) | Where-Object { $null -ne $_ } | ForEach-Object { $_['head']['sha'] })
    $shas = @($shas | Sort-Object -Unique)
    $seen = @()
    foreach ($sha in $shas) {
        $runs = Get-GhJson "repos/$Repo/commits/$sha/check-runs?per_page=100"
        $seen += @(@($runs['check_runs']) | Where-Object { $null -ne $_ } | ForEach-Object { $_['name'] })
        $statuses = Get-GhJson "repos/$Repo/commits/$sha/status"
        $seen += @(@($statuses['statuses']) | Where-Object { $null -ne $_ } | ForEach-Object { $_['context'] })
    }
    $seen = @($seen | Sort-Object -Unique)
    if ($seen.Count -eq 0) {
        Info "no check runs or statuses on the $($shas.Count) commit(s) read: required checks not compared (Actions retention may have deleted them)"
    } else {
        foreach ($context in $required) {
            if ($context -cin $seen) {
                Ok "required check '$context' reported"
            } else {
                Fail "required check '$context' reported on none of the $($shas.Count) commit(s) read" `
                    -Why ('a required check nothing reports leaves pull requests on "Waiting for status ' +
                        'to be reported": a renamed job, a matrix job named without its values, or a ' +
                        'workflow a path filter skipped') `
                    -Fix "require one of the names GitHub recorded: $($seen -join ', ')"
            }
        }
    }
}
#endregion

#region CODEOWNERS
Step 'CODEOWNERS'
$codeowners = Get-GhJson "repos/$Repo/codeowners/errors" -NotFoundIsAnswer
if ($null -eq $codeowners) {
    $missing = 'no CODEOWNERS file in .github/, the root or docs/'
    if ($Policy -eq 'org-published') {
        Fail $missing -Why 'the policy hands each folder to its maintainer through CODEOWNERS' `
            -Fix ('add .github/CODEOWNERS, each owner an account or team with write access, before ' +
                'the code-owner rule, which asks no review of content no owner covers')
    } else {
        Info $missing
    }
} elseif (@($codeowners['errors']).Count -eq 0) {
    Ok 'CODEOWNERS parses with no errors'
} else {
    foreach ($e in @($codeowners['errors'])) {
        $fix = if (Get-Key $e 'suggestion') { $e['suggestion'] } else { $null }
        Fail "$($e['path']):$($e['line']): $($e['kind']) -- $($e['message'])" `
            -Why 'GitHub skips an invalid line, so the paths it names have no owner' -Fix $fix
    }
}
#endregion

#region Release tags
$tagRulesets = @($rulesets | Where-Object { $_['target'] -eq 'tag' })
if ($ReleaseTagPattern -or $tagRulesets.Count -gt 0) { Step 'Release tags' }
if ($ReleaseTagPattern) {
    $ref = "refs/tags/$ReleaseTagPattern"
    $guards = @($tagRulesets | Where-Object {
            $include = @(Get-List (Get-Key (Get-Key $_ 'conditions') 'ref_name') 'include')
            $_['enforcement'] -eq 'active' -and ($ref -cin $include -or '~ALL' -cin $include)
        })
    $types = @($guards | ForEach-Object { @($_['rules']) | ForEach-Object { $_['type'] } } | Sort-Object -Unique)
    foreach ($type in 'update', 'deletion') {
        if ($type -in $types) {
            Ok "an active tag ruleset blocks $type on $ref"
        } else {
            Fail "no active tag ruleset blocks $type on $ref" `
                -Why 'a release tag that moves or disappears changes what a version means after it shipped' `
                -Fix "$settingsUrl/rules -- a tag ruleset on $ref restricting updates and deletions"
        }
    }
    if ('creation' -in $types) { Info "only bypassing accounts can create tags matching $ref" }
} elseif ($tagRulesets.Count -gt 0) {
    Info 'tag rulesets listed above are not judged: pass -ReleaseTagPattern to check one'
}
#endregion

#region About panel
# Warned of, never failed: none of it changes what a merge does. The live
# values print as they stand, so a proposed About text is a diff against
# them, and the edit is gh repo edit, which the skill runs only on a yes.
Step 'About panel'
$edit = "gh repo edit $Repo"
$description = Get-Key $repoJson 'description'
if ([string]::IsNullOrWhiteSpace($description)) {
    Warn 'no description' `
        -Why "the About panel, GitHub's search and every link's unfurl show it" `
        -Fix "$edit --description '<one sentence>'"
} else {
    Info "description: $description"
}
$homepage = Get-Key $repoJson 'homepage'
if ([string]::IsNullOrWhiteSpace($homepage)) { Info 'no homepage' } else { Info "homepage: $homepage" }
$topics = @(Get-List $repoJson 'topics')
if ($topics.Count -eq 0) {
    Warn 'no topics' -Why 'topics are how GitHub search and the topic pages find a repo' `
        -Fix "$edit --add-topic <topic>"
} else {
    Info "topics: $($topics -join ', ')"
}

# The card has a read side only: no mutation and no REST field sets it
# (re-probed 2026-10-24), so its fix is the settings page, by hand.
$repoOwner, $repoName = $Repo.Split('/')
$cardQuery = 'query Card($owner: String!, $name: String!) { repository(owner: $owner, name: $name) ' +
    '{ usesCustomOpenGraphImage openGraphImageUrl } }'
$cardRead = Invoke-GhQuery -Query $cardQuery -Variables @{ owner = $repoOwner; name = $repoName }
$card = if ($cardRead.ExitCode -eq 0) {
    Get-Key (Get-Key ($cardRead.Text | ConvertFrom-Json -AsHashtable) 'data') 'repository'
} else { $null }
if ($null -eq $card) {
    Warn "could not read the social preview: $($cardRead.Text)"
} elseif (Get-Key $card 'usesCustomOpenGraphImage') {
    Ok "a social preview is uploaded: $(Get-Key $card 'openGraphImageUrl')"
} else {
    $noCard = 'no social preview uploaded'
    $cardFix = "$settingsUrl -- General, Social preview, by hand: no API uploads one"
    if ($isPublic) {
        Warn $noCard -Why "a shared link unfurls with the owner's avatar instead" -Fix $cardFix
    } else {
        Info "${noCard}: links to a private repo unfurl to no one outside it"
    }
}

# The profile reports a single template file alone: two public repos holding
# only a PULL_REQUEST_TEMPLATE folder read null (2026-11-02), and GitHub's docs
# have that folder chosen with ?template=, so a null is looked behind here. File
# names are matched without case, as the docs say; the folder's is matched alike
# on the assumption GitHub treats it so.
function Find-PullRequestTemplate {
    param([Parameter(Mandatory)][string]$FullName)
    $found = @{ File = $null; Folder = $null; Unread = $null }
    foreach ($dir in @('.github', '', 'docs')) {
        $endpoint = if ($dir) { "repos/$FullName/contents/$dir" } else { "repos/$FullName/contents" }
        $read = Invoke-GhApi -Endpoint $endpoint
        if ($read.ExitCode -ne 0) {
            if ($read.Text -notmatch 'HTTP 404') { $found.Unread = $read.Text }
            continue
        }
        foreach ($item in @($read.Text | ConvertFrom-Json -AsHashtable)) {
            $name = "$(Get-Key $item 'name')"
            $itemType = Get-Key $item 'type'
            $shown = if ($dir) { "$dir/$name" } else { $name }
            if ($itemType -eq 'file' -and $name -imatch '^pull_request_template(\.[^.]+)?$') {
                if (-not $found.File) { $found.File = $shown }
            } elseif ($itemType -eq 'dir' -and $name -ieq 'PULL_REQUEST_TEMPLATE') {
                if (-not $found.Folder) { $found.Folder = $shown }
            }
        }
    }
    return $found
}

# A null file is one GitHub did not find; README and licence are looked
# for in the root, .github/ and docs/, as GitHub looks for them.
$profileRead = Invoke-GhApi -Endpoint "repos/$Repo/community/profile"
if ($profileRead.ExitCode -ne 0) {
    Warn "could not read the community profile: $($profileRead.Text)"
} else {
    $files = Get-Key ($profileRead.Text | ConvertFrom-Json -AsHashtable) 'files'
    $community = @(
        @{ Key = 'readme'; Label = 'README'; Loud = $true
            Why = 'the About text and a newcomer both start from it' },
        @{ Key = 'license'; Label = 'licence'; Loud = $isPublic
            Why = 'without one, default copyright holds, and no one else may reuse the code' },
        @{ Key = 'contributing'; Label = 'CONTRIBUTING'; Loud = $Policy -eq 'org-published'
            Why = 'people publishing here have no written way to start' },
        @{ Key = 'code_of_conduct'; Label = 'code of conduct'; Loud = $Policy -eq 'org-published'
            Why = 'nothing written sets how the people publishing here treat each other' }
    )
    foreach ($entry in $community) {
        if ($null -ne (Get-Key $files $entry.Key)) {
            Ok "$($entry.Label) found"
        } elseif ($entry.Loud) {
            Warn "no $($entry.Label)" -Why $entry.Why
        } else {
            Info "no $($entry.Label)"
        }
    }

    if ($null -ne (Get-Key $files 'pull_request_template')) {
        Ok 'pull request template found'
    } else {
        $templates = Find-PullRequestTemplate -FullName $Repo
        $defaultsRepo = "$repoOwner/.github"
        $defaults = $null
        if (-not $templates.File -and -not $templates.Folder -and $Repo -ne $defaultsRepo) {
            # GitHub serves an owner's defaults only from a public .github repo.
            $defaultsRead = Invoke-GhApi -Endpoint "repos/$defaultsRepo"
            if ($defaultsRead.ExitCode -ne 0) {
                if ($defaultsRead.Text -notmatch 'HTTP 404') { $templates.Unread = $defaultsRead.Text }
            } elseif ((Get-Key ($defaultsRead.Text | ConvertFrom-Json -AsHashtable) 'visibility') -eq 'public') {
                $defaults = Find-PullRequestTemplate -FullName $defaultsRepo
                if ($defaults.Unread) { $templates.Unread = $defaults.Unread }
            }
        }
        if ($templates.File) {
            Ok "pull request template found: $($templates.File)"
        } elseif ($templates.Folder) {
            Info "pull request templates in a folder only, chosen with ?template=, else a pull request opens blank: $($templates.Folder)"
        } elseif ($defaults -and $defaults.File) {
            Ok "pull request template from $defaultsRepo, the owner's default: $($defaults.File)"
        } elseif ($defaults -and $defaults.Folder) {
            Info "pull request templates in a folder only, chosen with ?template=, else a pull request opens blank: $($defaults.Folder) in $defaultsRepo, the owner's default"
        } elseif ($templates.Unread) {
            # An unread listing is not an absent template.
            Warn "could not look for a pull request template: $($templates.Unread)"
        } elseif ($Policy -eq 'org-published') {
            Warn 'no pull request template' `
                -Why 'a pull request opens with nothing asking why it was made or what was checked'
        } else {
            Info 'no pull request template'
        }
    }
}
#endregion

#region Handoff board
# Warned of, never failed, as the help says. The contract's values are
# provision-board's references/board-contract.md, held here as constants:
# a change there changes these in the same commit, and the suite builds
# its board from that file's tables, so a value either side lacks fails it.
Step 'Handoff board'
$boardTemplate = 'Backlog template'
# What makes a linked project the board, as handoff-status.py's CONTRACT
# reads one: these three fields, each with every option the contract names,
# bar Priority's Urgent, or for Priority P1 to P3 in their place, or an organization's
# own, an issue field listing no options.
$boardIdentity = @('Status', 'Priority', 'Reopen-when')
$namedPriorityOptions = @('High', 'Medium', 'Low')
# A board not yet moved off these is still the board, and warns of the gap.
$olderPriorityOptions = @('P1', 'P2', 'P3')
$boardFields = [ordered]@{
    'Status'      = @{ Type = 'SINGLE_SELECT'; Options = @('Open', 'Deferred', 'In flight', 'Done') }
    'Priority'    = @{ Type = 'SINGLE_SELECT'; Options = @('Urgent', 'High', 'Medium', 'Low') }
    'Reopen-when' = @{ Type = 'TEXT'; Options = @() }
    'Work model'  = @{ Type = 'SINGLE_SELECT'; Options = @('haiku', 'sonnet', 'opus', 'fable') }
    'Work effort' = @{ Type = 'SINGLE_SELECT'; Options = @('low', 'medium', 'high', 'xhigh', 'max') }
}
$workflowsOn = [ordered]@{
    'Item added to project'          = 'a new card is ready unless set otherwise'
    'Item reopened'                  = 'a reopened issue is work again'
    'Item closed'                    = 'a closed issue is off the queue, landed or dropped, and the card moves to Done'
    'Auto-archive items'             = 'Done stays short'
    'Auto-add to project'            = 'an issue anyone files reaches the board'
    'Auto-add sub-issues to project' = "a sub-issue from another repo joins its parent's board"
}
# GraphQL lists neither Code changes requested nor Code review approved,
# which the contract also keeps off (2026-10-27, re-read 2026-10-29).
$workflowsOff = [ordered]@{
    'Pull request merged'          = 'the board holds issues, not pull requests'
    'Auto-close issue'             = 'a card dragged to Done would close an issue whose work has not landed'
    'Pull request linked to issue' = 'the contract keeps it off until the repo lands by pull request'
}
# A pull request rule on the default branch is that landing, so either state
# of it is the repo's call. $ruleTypes was read in the rules section above;
# with the rules unread, whether the repo lands so is unknown, so neither.
if ($rulesUnread -or 'pull_request' -in $ruleTypes) { $workflowsOff.Remove('Pull request linked to issue') }
# The one label every board's repo gets, provision-board.sh's NEEDS_LABELS;
# filing makes each other needs:* and platform:* label as a brief names it.
$boardLabels = @('needs:user')

# A project's fields, name to type and option names, keyed exactly, as the
# queue's scripts compare names: @{} would take a field named status, and
# PSScriptAnalyzer refuses an ordinal hashtable, so a Dictionary holds them.
function Get-ProjectField {
    param($Project)
    $map = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($field in @(Get-List (Get-Key $Project 'fields') 'nodes')) {
        $fieldName = Get-Key $field 'name'
        if (-not $fieldName) { continue }
        $map[$fieldName] = @{
            Type    = Get-Key $field 'dataType'
            Options = @(Get-List $field 'options' | ForEach-Object { $_['name'] })
            # Asked of a single select only, so a text field has no such key.
            IssueBacked = $fieldName -ceq 'Priority' -and $field.Contains('options') -and
                @($field['options']).Count -eq 0
        }
    }
    return $map
}
# The contract's options a field lacks; an issue field's are judged on the repo.
# Priority takes no exception: a board short of Urgent lacks it, and only the
# identity check below spares that.
function Get-MissingOption {
    param($Have, [string]$FieldName)
    if ($Have[$FieldName].IssueBacked) { return @() }
    $offered = @($Have[$FieldName].Options)
    return @($boardFields[$FieldName].Options | Where-Object { $_ -cnotin $offered })
}
# Whether provision-board can bring a Priority to the contract. It renames P1 to
# P3 under their ids and adds Urgent, and leaves as found any other option, and P1
# beside High, which has no name to move to.
function Test-PriorityMovable {
    param([string[]]$Offered)
    $known = @('Urgent') + $namedPriorityOptions + $olderPriorityOptions
    if (@($Offered | Where-Object { $_ -cnotin $known }).Count -gt 0) { return $false }
    foreach ($index in 0..($olderPriorityOptions.Count - 1)) {
        if ($olderPriorityOptions[$index] -cin $Offered -and
            $namedPriorityOptions[$index] -cin $Offered) { return $false }
    }
    return $true
}

# The labels are asked for by the prefix they share, as a variable, so no
# double quote rides in gh's argument.
$boardQuery = 'query Boards($owner: String!, $name: String!, $needs: String!) { ' +
    'repository(owner: $owner, name: $name) { ' +
    'issueFields(first: 25) { nodes { ... on IssueFieldSingleSelect { name options { name } } } } ' +
    'projectsV2(first: 20) { totalCount nodes { ' +
    'number title url closed fields(first: 50) { nodes { ' +
    '... on ProjectV2FieldCommon { name dataType } ' +
    '... on ProjectV2SingleSelectField { options { name } } } } ' +
    'workflows(first: 30) { nodes { name enabled } } } } ' +
    'needs: labels(first: 100, query: $needs) { nodes { name } } } }'
# Whether a board holds the queue, for the landing below: $null while the
# boards, or some of them, went unread.
$queueBoard = $null
$boardRead = Invoke-GhQuery -Query $boardQuery -Variables @{
    owner = $repoOwner; name = $repoName; needs = 'needs:' }
$boardRepo = if ($boardRead.ExitCode -eq 0) {
    Get-Key (Get-Key ($boardRead.Text | ConvertFrom-Json -AsHashtable) 'data') 'repository'
} else { $null }
if ($null -eq $boardRepo) {
    # The scope error's type is the one handoff-status.py reads; gh's own
    # line names the scope. A board unread is never reported missing.
    if ($boardRead.Text -match 'INSUFFICIENT_SCOPES|read:project') {
        Warn "could not read the boards: the token $actingAs acts with lacks the read:project scope" `
            -Why 'a board unread is not a board missing, so none is judged' `
            -Fix 'gh auth refresh -s read:project, for the account the audit read as'
    } else {
        Warn "could not read the boards: $($boardRead.Text)"
    }
} else {
    # A null node is a linked project this account cannot see, so nodes are
    # counted before any is dropped, read by index: Get-List would drop them
    # unseen, and Get-Key's return unrolls a lone null to none.
    $projectList = Get-Key $boardRepo 'projectsV2'
    $projectNodes = @()
    if ($projectList -is [System.Collections.IDictionary] -and $projectList.Contains('nodes') -and
        $null -ne $projectList['nodes']) {
        $projectNodes = @($projectList['nodes'])
    }
    $hidden = @($projectNodes | Where-Object { $null -eq $_ }).Count
    $linkedCount = [int](Get-Key $projectList 'totalCount')
    if ($linkedCount -gt $projectNodes.Count) {
        Info "only the first $($projectNodes.Count) of $linkedCount linked projects read"
    }
    if ($hidden -gt 0) { Info "$hidden linked project(s) not visible to $actingAs" }

    $boards = @()
    foreach ($project in @($projectNodes | Where-Object { $null -ne $_ })) {
        $projectName = "project $($project['number']) '$($project['title'])'"
        if (Get-Key $project 'closed') { Info "$projectName is closed"; continue }
        if ($project['title'] -ceq $boardTemplate) {
            Info "$projectName is the template boards are copied from, not a board"
            continue
        }
        $have = Get-ProjectField $project
        $lacks = @(foreach ($fieldName in $boardIdentity) {
                if (-not $have.ContainsKey($fieldName)) { $fieldName; continue }
                $missing = @(Get-MissingOption $have $fieldName)
                # Urgent is a person's, so identity asks only for what a brief maps to,
                # as handoff-status.py's CONTRACT does; a field gap warns below.
                if ($fieldName -ceq 'Priority') {
                    $offeredNames = @($have[$fieldName].Options)
                    $olderShort = @($olderPriorityOptions | Where-Object { $_ -cnotin $offeredNames })
                    $missing = @(if ($olderShort.Count -gt 0) { $missing | Where-Object { $_ -cin $namedPriorityOptions } })
                }
                if ($missing.Count -gt 0) {
                    $otherSpelling = if ($fieldName -ceq 'Priority') { ', or P1, P2 and P3' } else { '' }
                    "$fieldName option(s) $($missing -join ', ')$otherSpelling"
                }
            })
        if ($lacks.Count -eq 0) {
            $boards += , @{ Project = $project; Name = $projectName; Fields = $have }
        } else {
            Info "$projectName carries no board contract: lacks $($lacks -join '; ')"
        }
    }

    if ($boards.Count -gt 0) {
        $queueBoard = $true
    } elseif ($linkedCount -le $projectNodes.Count -and $hidden -eq 0) {
        $queueBoard = $false
    }

    if ($boards.Count -eq 0 -and ($linkedCount -gt $projectNodes.Count -or $hidden -gt 0)) {
        Info 'no board among the linked projects read: some went unread, so none is judged missing'
    } elseif ($boards.Count -eq 0) {
        Info 'no linked project carries the board contract: provision-board makes one'
    } elseif ($boards.Count -gt 1) {
        Warn "$(($boards | ForEach-Object { $_.Name }) -join ' and ') each carry the board contract" `
            -Why "set-card.py and the queue view then read neither, so no card can be claimed" `
            -Fix 'close all but one, or unlink it from the repo'
    } else {
        $board = $boards[0]
        $boardUrl = Get-Key $board.Project 'url'
        Ok "board: $($board.Name), $boardUrl"

        $gaps = 0
        foreach ($fieldName in $boardFields.Keys) {
            $want = $boardFields[$fieldName]
            if (-not $board.Fields.ContainsKey($fieldName)) {
                Warn "board: no field $fieldName" `
                    -Why "the queue's scripts read and write the contract's fields by name" `
                    -Fix 'provision-board, which adds each field a board lacks'
                $gaps++
                continue
            }
            $type = $board.Fields[$fieldName].Type
            if ($type -cne $want.Type) {
                Warn "board: field $fieldName is $type, want $($want.Type)" `
                    -Why "the queue's scripts write it as the contract types it" `
                    -Fix "the project's settings, $fieldName, by hand"
                $gaps++
                continue
            }
            $missing = @(Get-MissingOption $board.Fields $fieldName)
            if ($missing.Count -gt 0) {
                Warn "board: field $fieldName lacks $($missing -join ', ')" `
                    -Why 'a value the field does not offer cannot be set on a card' `
                    -Fix $(if ($fieldName -ceq 'Priority' -and
                            (Test-PriorityMovable $board.Fields[$fieldName].Options)) {
                            $mends = @(
                                if (@($missing | Where-Object { $_ -cin $namedPriorityOptions }).Count -gt 0) {
                                    'moves P1 to P3 to High, Medium and Low under the same ids'
                                }
                                if ('Urgent' -cin $missing) { 'adds Urgent' }
                            )
                            "provision-board, which $($mends -join ' and ')"
                        } else {
                            "the project's settings, $fieldName, by hand: add each, keeping the " +
                            "options there, whose ids hold every card's value"
                        })
                $gaps++
            }
        }
        if ($board.Fields.ContainsKey('Priority') -and $board.Fields['Priority'].IssueBacked) {
            $issuePriority = @(Get-List (Get-Key $boardRepo 'issueFields') 'nodes' |
                    Where-Object { (Get-Key $_ 'name') -ceq 'Priority' })
            $offeredPriority = @($issuePriority | ForEach-Object { Get-List $_ 'options' } |
                    ForEach-Object { $_['name'] })
            $shortPriority = @($namedPriorityOptions | Where-Object { $_ -cnotin $offeredPriority })
            if ($shortPriority.Count -gt 0) {
                Warn "board: the owner's Priority lacks $($shortPriority -join ', ')" `
                    -Why "a brief's priority maps to High, Medium and Low, so set-card.py cannot write it" `
                    -Fix "the owner's settings, Planning, its Priority field, by hand: add each"
                $gaps++
            }
        }
        if ($gaps -eq 0) { Ok "board: fields $($boardFields.Keys -join ', ')" }

        # No API turns a workflow on or off, so each fix is the UI.
        $flows = @(Get-List (Get-Key $board.Project 'workflows') 'nodes')
        $flowsOn = @($flows | Where-Object { Get-Key $_ 'enabled' } | ForEach-Object { $_['name'] })
        $menu = "$boardUrl -- the menu, Workflows"
        $gaps = 0
        foreach ($flow in $workflowsOn.Keys) {
            if ($flow -cnotin $flowsOn) {
                Warn "board: workflow $flow is off" -Why $workflowsOn[$flow] `
                    -Fix "$menu, $flow, Edit, as board-contract.md sets it, Save and turn on workflow"
                $gaps++
            }
        }
        foreach ($flow in $workflowsOff.Keys) {
            if ($flow -cin $flowsOn) {
                Warn "board: workflow $flow is on" -Why $workflowsOff[$flow] -Fix "$menu, $flow, off"
                $gaps++
            }
        }
        if ($gaps -eq 0) { Ok 'board: workflows on and off as the contract sets them' }
        Info ("board, unread: each workflow's value and filter, and Code changes requested and " +
            'Code review approved, which GraphQL does not list')

        $repoLabels = @(@(Get-List (Get-Key $boardRepo 'needs') 'nodes') |
            ForEach-Object { $_['name'] })
        $missingLabels = @($boardLabels | Where-Object { $_ -notin $repoLabels })
        if ($missingLabels.Count -gt 0) {
            Warn "board: the repo lacks label(s) $($missingLabels -join ', ')" `
                -Why "the queue reads a brief's needs from its issue's labels" `
                -Fix 'provision-board, which creates each label every board repo gets'
        } else {
            Ok "board: the label(s) $($boardLabels -join ', ')"
        }

        # GitHub closes no parent with its last sub-issue, and no commit can say
        # it is the last while a sibling lands beside it (board-contract.md,
        # Parents and sub-issues), so only a workflow closes one unasked.
        # Read by the file name the scaffold writes, never by its text.
        $closerName = 'close-parent.yml'
        $closerWhy = 'GitHub closes no parent with its last sub-issue, so each waits for the user to close it'
        $closerFix = "the skill's close-parent workflow, in references/scaffolds.md"
        if (-not $actionsOn) {
            Warn 'board: Actions is disabled, so no workflow closes a parent with its last sub-issue' `
                -Why $closerWhy -Fix "$settingsUrl/actions -- allow actions, then $closerFix"
        } elseif (-not $listed) {
            # The listing's WARN above stands for this one.
            Info "board: whether $workflowDir/$closerName is on $defaultBranch was not read"
        } elseif ($closerName -cin $workflowNames) {
            Ok "board: $workflowDir/$closerName on $defaultBranch closes a parent with its last sub-issue"
        } else {
            Warn "board: no $workflowDir/$closerName on $defaultBranch" -Why $closerWhy -Fix $closerFix
        }
    }
}
#endregion

#region Handoff landing
# A queue's branches land as its rule for briefs says, and work-issue and
# lead-sessions stop at their preflight where it names no landing, as one
# did in an organization's repo whose audit that day had warned of nothing
# (2026-11-03). Warned of, never failed, as the help says. The rule is read
# for the template bullets' bold openings, by the pattern file-issue's step
# 1 and provision-board's step 4 grep with, so a change to one is made in
# all three. -cmatch over the whole text matches as their grep -E does: in
# case, and within a line, since the pattern holds no line break.
Step 'Handoff landing'
$briefRule = '.claude/rules/handoff-briefs.md'
$landingPattern = 'worktree lands (from the main checkout|by pull request)'
$queueName = if ($queueBoard) { 'the board' } else { $null }
$filesUnread = $false
if (-not $queueName) {
    # A file queue is docs/handoffs/ on the default branch, as the scaffold
    # reads one missing where there is none.
    $filesRead = Invoke-GhApi -Endpoint "repos/$Repo/contents/docs/handoffs"
    if ($filesRead.ExitCode -eq 0) {
        $queueName = 'docs/handoffs/'
    } elseif ($filesRead.Text -notmatch 'HTTP 404') {
        $filesUnread = $true
        Warn "could not read docs/handoffs/: $($filesRead.Text)"
    }
}
if (-not $queueName) {
    # A queue unread is not a queue missing, as a board unread is not.
    if ($null -eq $queueBoard -or $filesUnread) {
        Info 'whether the repo keeps a handoff queue was not read, so no landing is judged'
    } else {
        Info 'no handoff queue, a board or docs/handoffs/, so no landing is judged'
    }
} else {
    # The bullet for the route, as the scaffold's step 2 picks it.
    $bullet = if ($rulesUnread) {
        "the fast-forward landing bullet, or the pull-request one where $defaultBranch takes " +
        "changes by pull request alone: $notRead"
    } elseif ('pull_request' -in $ruleTypes) {
        "its pull-request landing bullet, as a pull_request rule is active on $defaultBranch"
    } elseif ($null -ne $classic) {
        "the landing bullet for the route the user names: classic protection on $defaultBranch, " +
        'not audited, may refuse a fast-forward'
    } elseif (-not $isAdmin) {
        "the fast-forward landing bullet, or the pull-request one where $defaultBranch takes " +
        'changes by pull request alone: classic protection is unread without admin rights'
    } else {
        "its fast-forward landing bullet, as no pull_request rule is active on $defaultBranch"
    }
    $landingWhy = 'work-issue and lead-sessions stop at their preflight until the rule names a landing'
    $scaffoldStep = "the skill's handoff-queue step 2, in references/scaffolds.md"
    $ruleRead = Invoke-GhApi -Endpoint "repos/$Repo/contents/$briefRule"
    if ($ruleRead.ExitCode -ne 0) {
        if ($ruleRead.Text -match 'HTTP 404') {
            Warn "$queueName holds a handoff queue, and no $briefRule on $defaultBranch names its landing" `
                -Why $landingWhy -Fix "${scaffoldStep}: the rule from its template, with $bullet"
        } else {
            Warn "could not read ${briefRule}: $($ruleRead.Text)"
        }
    } else {
        $ruleFile = if ([string]::IsNullOrWhiteSpace($ruleRead.Text)) { $null } else {
            $ruleRead.Text | ConvertFrom-Json -AsHashtable
        }
        $ruleText = ConvertFrom-RepoContent $ruleFile
        # An empty file comes back as base64 of nothing: text naming no
        # landing, not text the API withheld.
        if ($null -eq $ruleText -and (Get-Key $ruleFile 'encoding') -eq 'base64' -and
            (Get-Key $ruleFile 'size') -eq 0) { $ruleText = '' }
        if ($null -eq $ruleText) {
            Info "$briefRule not read, as the contents API returned no text for it: no landing is judged"
        } elseif ($ruleText -cmatch $landingPattern) {
            Ok "$briefRule names a landing: $($Matches[0])"
        } else {
            Warn "$briefRule names no landing for the queue $queueName holds" `
                -Why $landingWhy -Fix "${scaffoldStep}: add $bullet, copied, its bold opening as written"
        }
    }
}
#endregion

Step "Summary: $script:Failures FAIL, $script:Warnings WARN"
if ($script:Failures -gt 0) { exit 1 }
exit 0
