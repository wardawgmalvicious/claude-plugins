# Surfaces and organization sync

What each surface loads from one plugin folder, and what an organization
sync demands of the repository. Read 2026-10-22 from claude.com's
`plugins/platform-support`, `plugins/org-sync`, `plugins/admin` and
`plugins/org-rollout`. Nothing here was run in chat or Cowork.

## What each surface loads

Chat is claude.ai on the web, desktop and mobile; Cowork is Cowork tasks
in the desktop app; Claude Code is the terminal, the IDE extensions and
the desktop app's Code tab. "Ignored" skips the component; "refused"
rejects the whole plugin.

| Component | Chat | Cowork | Claude Code |
| --- | --- | --- | --- |
| Skills, `skills/<name>/SKILL.md` | loads | loads | loads |
| Commands, `commands/*.md` | loads as a skill | loads, run as `/plugin-name:command` | loads |
| Agents, `agents/*.md` | ignored | loads | loads |
| Hooks, `hooks/hooks.json` | ignored | loads | loads |
| Remote MCP server, `http` or `sse`, fixed URL | listed on the plugin's **Connectors** tab; works once connected there | loads; connect it on that tab | loads |
| Local MCP server, a command the app starts, `.mcpb` included | ignored | loads when the session runs on the user's computer | loads |
| MCP server referencing `${user_config.*}` | ignored when the URL holds the reference | ignored when a referenced option has no default; never prompts | loads and prompts |
| Executables in a top-level `bin/` | refused | refused | loads |
| LSP servers, output styles, themes | ignored | ignored | loads |
| `settings`, a root `settings.json` or the manifest key | ignored | ignored | its `agent` key alone, deprecated (Claude Code `CHANGELOG.md`, read 2026-11-14); `SKILL.md` step 3 |

## Where installs live

- **Chat and Cowork read plugins from the claude.ai account**, for the
  organization the user is in; Claude Code reads them from the machine,
  at user, project or local scope.
- **An account install travels to Claude Code** as a synced plugin at the
  next session start; a command-line install stays on that machine.
- **Account limits**: 25 marketplaces a user adds, per organization; each
  plugin up to 5,000 files and 200 MB. Claude Code has no account limits.
- **A marketplace a user adds on claude.ai** may be on GitHub or GitHub
  Enterprise, or a public GitLab or Bitbucket repository; Claude Code
  takes any git repository, URL or local path.

## Organization sync

Set up in **Organization settings > Plugins & skills**, **Add**, then
**Sync from GitHub** or **Sync from GitLab**. It reads the default
branch through the organization's GitHub App or GitLab token, so members
need no access to the repository.

The repository must pass these, or the plugin is rejected:

- **Visibility**: on github.com and gitlab.com, private or internal.
- **Plugin sources**: `github`, `url`, `git-subdir`, or a relative path
  starting `./`. A bare name under `metadata.pluginRoot` is rejected as
  an unsupported source.
- **Private sources**: a github.com source sharing the marketplace
  repository's owner, a GitHub Enterprise source with the App installed,
  or a `url` or `git-subdir` source on the same GitLab host (on
  gitlab.com, under the same top-level group or user). Any other source
  must be public on github.com, gitlab.com or bitbucket.org. Keeping
  each plugin inside the marketplace repository, by relative path,
  avoids the question: the sync packages it.
- **No top-level `bin/`**: rejected with `Plugin contains a top-level
  bin/ directory`, by sync or upload; the rest of the marketplace syncs.

When it syncs: on **Re-sync**, or on each push to the default branch
while **Sync automatically** is on, which needs the repository webhook.
Nothing syncs on a schedule, and tags are not read.

In Claude Code a change arrives as each `<name>@synced` plugin syncs at
the next session start, or, for a plugin installed from the marketplace
added by `claude plugin marketplace add --claudeai <name>` (2.1.273 or
later, registered under a name starting `claudeai-`), by auto-update,
on by default for such a marketplace and off for one added by source
(plugins/install, read 2026-11-06).

## Availability and its limits

Each plugin's **Default access**, labelled **Distribution**, **Audience**
or **Group access…** elsewhere in the admin pages:

| Setting | Members see | Can remove it |
| --- | --- | --- |
| **Not available** | nothing; hidden and unloaded, even where installed | not applicable |
| **Available to install** | it under **Discover** | yes |
| **Installed by default** | it installed | can turn it off |
| **Required** | it installed and always on | no |

- **A marketplace has its own Default access**, in its page's
  **Default settings** section: the level of every plugin from it that
  has no setting of its own, plugins added to it later included, so a
  plugin pushed to a synced marketplace arrives at that level. For
  Anthropic's directory the choices are **Not available** and
  **Available to install** only (admin, read 2026-11-07).
- **Availability adds no connector.** For a plugin installed by default
  or required, an Owner also adds its connector in **Organization
  settings > Connectors**, and members connect with their own accounts.
- **A synced item cannot be reverted**; an uploaded one can, from
  **Version history**. Fix forward in the repository and **Re-sync**,
  with the plugin **Not available** meanwhile, and on Enterprise any
  group with its own setting too.
- **Delete source** "permanently deletes every plugin in that
  marketplace for every member".
- **Both routes at once**: a developer whose managed settings install the
  plugin and whose account syncs it gets the managed copy, and the synced
  copy reports as not loaded.
- **Two switches stop synced plugins loading in Claude Code.** Turning
  **Skills** off in **Organization settings > Plugins & skills >
  Policy** stops it for the whole organization, and turns off plugins
  and the organization's own skills in claude.ai too: members read
  **Skills must be enabled in order to use plugins.** on **Customize >
  Plugins**. `syncClaudeAiPlugins: false` in Claude Code managed
  settings stops only the sync into Claude Code, leaving plugins on in
  claude.ai and Cowork (admin, read 2026-11-07).
