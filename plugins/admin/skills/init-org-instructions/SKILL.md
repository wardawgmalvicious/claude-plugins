---
name: "init-org-instructions"
description: "Writes, audits, or revises a claude.ai organization's instructions: the Organization instructions block an Owner sets in Organization settings, which loads in every member's conversations. Use whenever an Owner or admin wants org instructions, organization preferences, or company-wide standing guidance for Claude drafted, reviewed, cut under the 3,000-character limit, or rebuilt, including while rolling out a Team or Enterprise plan. For a member's own Instructions for Claude, use `init-account-instructions`; for one Project's instructions, `init-project-instructions`, where the essentials plugin is installed."
---

# Init Org Instructions

Build a complete, paste-ready replacement for the organization's **Organization instructions**, in Organization settings > Organization and access. Only Owners and Primary Owners on Team and Enterprise plans can set, view or edit them. You can't write to the setting, so the deliverable is text the admin pastes and saves.

The block is included in every message everyone in the organization sends, on every surface that carries it. It takes precedence over each member's own instructions, which still apply wherever the organization's say nothing. The field holds at most 3,000 characters, and a saved change can take up to an hour to reach every Claude product. So a line earns its place only if deleting it would change Claude's behavior in a typical conversation for most members. Call this the deletion test. A rule only one team needs costs everyone else context on every message.

Past this skill, look in its `references/`: [guidance.md](references/guidance.md) holds the platform facts, with sources, and [skeleton.md](references/skeleton.md) the sections. Past those, read support.claude.com's *Set organization instructions* and claude.com's *Manage plugins for your organization* live. A live page that contradicts a line here wins, bar a dated measured line that names the page it overrules and the call that measured it, which a page changed since its date sends back to re-measure. An observed claim is cited or marked pending a doc check, and stands, marked observed, only where no page covers it.

## Arguments

Treat any text passed with the invocation as focus or constraints for this run:
- None: build a fresh block, or revise the existing one, interviewing only where something is missing, stale, vague, conflicting or over the limit.
- `audit`: findings only, with no interview and no block unless asked.
- Anything else: a focus area or a specific change (e.g., "tighten", "add a data-handling section"). Ask only what the change depends on, and still emit the block in full.

## Step 1: Gather context

Collect, cheapest first. Don't narrate lookups; the Sources line reports them.

1. **The existing block.** Organization instructions may be in your context; identify them only if they're unambiguous, never by guessing at Anthropic's system prompt, the admin's own Account instructions, Project instructions or styles. Otherwise ask the admin to paste the current text from the setting, or confirm it's empty. Treat a pasted block as approved, even if an earlier run drafted it.
2. **Plan and role.** Confirm the admin is an Owner or Primary Owner; anyone else can draft, but an Owner must save. Ask whether the plan is Team or Enterprise only where it changes routing: on Enterprise, a plugin can be limited to a user group.
3. **The organization's own sources.** Ask which sources speak for the organization: its website or About page, an employee handbook, a style guide, a policy index, a document-control site. Read them where your tools reach (web fetch, or a connected SharePoint, Google Drive or similar), and say which you couldn't reach. Use only facts these sources state or the admin confirms.
   - Confirm each document the block cites, its number, title and current revision, in the library that controls it. A copy under an archive or superseded folder, such as Historical or Archive, is not current.
   - Where one document turns up in more than one site or as lettered variants, report every copy found and ask which is controlled. Don't pick one.
4. **AI-use policy.** If the organization has one, read it. The block must not contradict it, and can cite it; it often names where AI incidents are reported. Check every draft against it, the existing block included, and report any conflict first, as a blocker, before other changes: the block can't overrule a controlled policy, and the policy's owner settles the conflict.
5. **What has gone wrong.** Ask what members have had to correct repeatedly, or what Claude has gotten wrong about the organization. Corrections that recur across teams are the strongest evidence for an org-wide line.

You can't see members' own instructions or their chats. Don't guess at them, and don't treat the admin's own chats as the organization's voice.

If a source is unavailable, note it and continue with the rest.

## Step 2: Classify and filter

Route every candidate, interview answers included, to exactly one destination:
- **Organization block:** standing facts and rules most members' conversations need. Who the organization is and who its customers are, data handling, claims that must be accurate, where policies live and how to cite them, where to send people, terminology, formatting. The sections and examples are in [skeleton.md](references/skeleton.md).
- **A Project:** context or rules for one team or one body of work, in a Project shared with that team. If `init-project-instructions` is installed, it can write them.
- **A skill or plugin:** a repeatable procedure, such as a contract first pass, a returns reply or an incident write-up, and any document index or lookup procedure: which number covers what, how to find the current revision. A skill loads only when the task calls for it, while the block costs every message. On Enterprise, a plugin can go to one group alone. Offer `skill-creator` to package it.
- **Members' own instructions:** personal taste in length, tone or format that the organization doesn't need to fix. Say so in the admin's announcement rather than in the block; `init-account-instructions` writes a member's.
- **An admin setting:** anything that must be enforced rather than encouraged. Examples are switching off a connector, artifact sharing, code execution, public projects or skill publishing. Instructions are prompt-level, so behavior can vary when instructions directly contradict each other, and they can't override Claude's safety behavior. Name the setting; don't write a line that pretends to enforce it.
- **Claude Code config:** coding conventions, tool permissions and repository rules. These belong in managed settings or a repository's `CLAUDE.md`. Claude Code's own docs don't mention organization instructions (searched 2026-11-10), so don't rely on the block there.
- **Nowhere:** what Claude already does by default, what claude.ai supplies (date, time zone), one-off announcements, and anything that will be stale within months.

Evidence rules:
- **Never invent a fact.** A contact, phone number, address, document number, URL, product rating, certification or approved claim goes in only as a source states it or the admin gives it. If one is unknown, ask. If it's still unknown at write time, leave the line out and list it under Missing facts, drafted with the gap bracketed so it drops in once the fact arrives. Never put a bracketed placeholder in the block.
- **References that outlive staff and revisions.** Name a contact by role, team or shared mailbox, never an individual, so the block survives a staffing change. Link a site root or portal page plus a document number, never a per-file URL, which breaks when a revision replaces the file.
- **Facts carry behavior.** Keep a fact only with the behavior it drives ("Our team works in healthcare claims processing; 'claims' means insurance claims, not legal claims"), never as a bare profile.
- **Write nothing a member shouldn't see.** Only Owners can open the setting, but the block travels with every member's messages, so treat it as readable by any member: it is no place for anything confidential from parts of the organization. That includes salary bands, investigation details, unannounced plans, individuals' contact details, partner or channel pricing, and supplier relationships under confidentiality.
- **No secrets.** No credentials, keys, account numbers or internal passwords, ever.
- **Scope every absolute.** Say when a rule applies ("in customer-facing drafts", "for installation questions"). Unscoped "always" and "never" rules collide and get over-applied across a whole organization.
- **Approved wording is quoted, not paraphrased.** Where marketing, legal or quality has approved wording for a claim, such as a certification, an origin statement or a warranty, quote it exactly and name the wording to avoid.
- **High-stakes questions get a referral.** For safety-critical products, legal, HR and regulatory questions, the block gives general information and names the documentation or team to go to, never a final ruling.
- **Dedupe.** Drop rewordings, Claude's defaults and lines that restate each other.

## Step 3: Interview

Ask only after gathering, so every item arrives pre-filled. Show the current wording or a sourced proposal, and let the admin answer keep, change or drop. Where nothing exists yet, offer two or three concrete example answers instead of an open question.

Run it in rounds, stopping to wait after each:
1. **Confirmations first.** List every item you'd keep as is or only reword in one numbered message, and accept enumerated replies such as "keep all except 3; 5) drop". Items the admin flags without a replacement become decisions.
2. **Decisions next**: gaps, conflicts and real rewrites, highest impact first. Use the question tool when available (up to 4 per round, recommended option first and marked "(Recommended)"); otherwise ask numbered questions.
3. **Missing facts.** Collect every fact the block needs and no source gave: contacts, document numbers, URLs. Ask for them in one numbered list.
4. **Close** with one open question: anything Claude should always or never do for everyone here?

Draw the question bank from [skeleton.md](references/skeleton.md), one section at a time, skipping any section the organization doesn't need. Never ask what context already settles. If nothing needs asking, go to Step 4.

## Step 4: Write

Structure:
- One identity paragraph first: who the organization is, what it makes or does, who its customers are, and what "members" means.
- Then short plain-text section headings, each followed by hyphen bullets. Include only sections that change behavior.
- Last line: `Last revised:` and today's date, in the date format the block itself sets for members, else `YYYY-MM-DD`; a stamp that breaks the block's own date rule reads as a contradiction.

Style:
- Imperative voice; specific and checkable ("Respond in formal English; no contractions" beats "Be professional").
- Add a short reason where a rule's purpose isn't obvious; reasons generalize better than bare commands.
- Plain emphasis: no caps or "CRITICAL", since every line already reaches everyone.
- Durable phrasing: no "currently", no in-progress items, no dates besides the stamp.
- Count characters, not words, stamp included. 3,000 is the field's hard limit as read 2026-11-10; re-read it on *Set organization instructions* before calling a block final; aim well under it, since every character rides on every message. When cutting, drop by the deletion test before compressing wording.

When revising: keep lines that still hold; rewrite or cut ones that are vague, redundant, contradictory, stale, unsourced, or better routed elsewhere.

Before responding, verify:
- the count is 3,000 or fewer
- no placeholders, invented facts or secrets
- no unresolved conflicts between lines
- every absolute is scoped
- nothing confidential to part of the organization
- the block works as a full replacement with zero edits

Scan the block, text carried over from the existing block included, for zero-width or other invisible Unicode characters (U+200B-U+200D, U+2060, U+FEFF) and remove them.

## Step 5: Respond

Deliver in the chat reply, not as a file, doc or artifact; the text goes straight into the setting. Keep everything above the block brief, in this order:
1. **Blockers**, only if any: each conflict with the AI-use policy or another controlled policy, and each document whose controlled copy is unconfirmed.
2. **Sources** (one line): the existing block found, pasted or confirmed empty; the sources read; the sources the admin named but you couldn't reach.
3. **Changes** (revisions only): main additions, removals and consolidations, plus the character count before and after. No line-by-line changelog.
4. **Routed elsewhere:** each item and its destination, setting or skill named.
5. **Missing facts:** each line left out for want of a fact, drafted with the gap bracketed, and the fact it needs. Re-emit the block once they're supplied.
6. **Assumptions:** anything inferred rather than stated, so the admin can veto it.
7. **Test it:** say that changes can take up to an hour to apply. Then give three to five prompts to try in a new conversation, each aimed at a line in the block: one that should trigger a referral, one that tempts an invented fact, one customer-facing draft.
8. **The block**, last: "Paste into **Organization instructions** in Organization settings > Organization and access (N characters):", then the complete block in a fenced block opened with four backticks plus `text`. No commentary inside.

On follow-up edits, re-emit the block in full with its new count; the admin pastes full replacements, never diffs.

In `audit` mode, open with Blockers as in Step 5, then Sources, then the findings, grouped as:
- contradicts a controlled policy, or cites a document whose controlled copy is unconfirmed (blockers, listed first)
- over the limit
- invented or unsourced facts
- conflicting
- vague or unscoped
- stale, or fragile: an individual named as a contact, a per-file URL, a superseded document revision
- confidential
- misrouted: one team's rule, a procedure that belongs in a skill, or a rule that needs an admin setting to enforce

Give each finding a one-line fix. End by offering the full rewrite.

## Constraints

- **No fabricated facts.** If a source or the admin didn't give it, it isn't in the block.
- **No placeholders in the block.** Missing facts are listed outside it.
- **3,000 characters is a hard stop.** A block over it can't be saved.
- **Don't promise enforcement.** A rule that must hold goes to an admin setting, named for the admin.
- **The admin saves it.** You draft; an Owner pastes and saves, and members see the change in new conversations, within the hour.
