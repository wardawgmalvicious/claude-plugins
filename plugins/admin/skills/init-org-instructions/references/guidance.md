# Organization instructions: platform facts

Read 2026-11-10 unless marked. A live page that contradicts a line here
wins.

## The setting

From [Set organization instructions](https://support.claude.com/en/articles/14546867-set-organization-instructions):

- **Who:** Owners and Primary Owners on Team and Enterprise plans. Only
  Owners and above can view or edit the block.
- **Where:** Organization settings > Organization and access >
  Organization instructions. To remove the instructions, clear the field
  and save.
- **Limit:** 3,000 characters.
- **Timing:** changes may take up to an hour to take effect across Claude
  products.
- **Reach:** every conversation for everyone in the organization. The
  block is included in every message sent.
- **Precedence:** organization instructions win over a member's own
  instructions when the two directly contradict. A member's own
  instructions still apply to anything the organization's don't address.
  This is prompt-level, so "behavior may vary" in rare contradictory edge
  cases; the page says to test.
- **Limits of power:** organization instructions can't disable Claude's
  safety guidelines or content policies.
- **Best practices:** be concise, be specific, cover consistent
  behaviors, avoid conflicting lines, test in a new conversation, and
  review regularly.
- **Example kinds:** team identity, communication standards, response
  formatting, domain context, referral guidance, data handling reminders.

From the [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide),
§ *Using organization instructions to shape user behavior*, three uses
for steering usage:

- Have Claude confirm before generating a token-heavy format.
- Point to internal wikis and guidelines.
- Reinforce which model is the default.

## Instructions versus other customizations

Claude Academy, read from a capture taken 2026-11-09. A capture, or an
Academy file an admin keeps in a Project, is background, not proof of
current state: confirm a product claim on the live help center before
stating it.

- *Customize Claude*
  (`academy.claude.com/tutorials/customize-claude-cowork`): general rules
  go in instructions, a repeatable process in a skill. Instructions apply
  to every task; a skill loads only when relevant and can be shared.
  Member instructions come in two layers: Account-level, and Project
  instructions on top of them inside a Project. The tutorial says
  organization instructions apply "across your conversations, tasks, and
  Code". No Claude Code docs page mentions them (searched 2026-11-10), so
  treat the Claude Code claim as unconfirmed.
- *Governing customizations*
  (`academy.claude.com/courses/deploying-claude-enterprise-with-confidence/governing-customizations`):
  organization instructions are the organization's always-on context,
  for standing facts and standing instructions. One example is "citing
  the source document whenever Claude quotes internal material". The
  lesson's closing question for an admin is what two or three lines
  every conversation should carry.

## Governance posture, briefly

These settings live beside the block in Organization settings, and they
decide how far a skill routed out of the block can spread. From
[Manage plugins for your organization](https://claude.com/docs/plugins/admin.md):

- **Publishing** (Plugins & skills > Policy), for skills and plugins
  alike:
  - Requires review: nothing reaches other members until a reviewer
    approves. You can't review your own request.
  - Open: members publish without review, after the security scan where
    one runs.
  - Off: members can't publish.
- **Publishing default** when nobody has chosen a value:
  - Team: Open.
  - Enterprise: Open with security scanning on, else Requires review.
- **Skill sharing** lets members share with named people. **Share with
  groups** is Enterprise-only.
- **Group availability** is Enterprise-only. A group's own setting
  replaces the organization-wide one, even when stricter. Across several
  groups, the most permissive setting applies. On Team there are no
  groups: pilot by sharing with specific people.

Academy's three postures, from *Governing customizations*:

| Posture | Settings |
| --- | --- |
| Open build, reviewed spread | Skill sharing on; Publishing Requires review |
| Centralized | Skill sharing off; Publishing Off; Owners provision |
| Fully open | All sharing on; Publishing Open |

Loosening a posture is free. Tightening Publishing removes nothing
already published, while turning off Public projects makes existing
public projects private.
