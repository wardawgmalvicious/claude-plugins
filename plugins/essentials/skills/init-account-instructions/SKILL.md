---
name: "init-account-instructions"
description: "Creates, audits, or rewrites the user's personal instruction block in claude.ai: Instructions for Claude in Account settings. Use whenever the user wants it written, reviewed, tightened, or rebuilt, whether they name the setting or describe it ('my preferences', 'custom instructions', 'how Claude should always respond'). For Project instructions, use the `init-project-instructions` skill if it's available. For Claude Code's user-scope CLAUDE.md, use `init-user-instructions`, run in Claude Code."
---

# Init Account Instructions

Build a complete, paste-ready replacement for the user's personal instruction block in claude.ai: **Instructions for Claude** in Account settings (the Account block). Identify it by its heading, not a menu path, since menus differ between apps and versions. Cowork no longer has a separate Global instructions setting, so this one block is the only deliverable, and rules for Cowork and other file-changing work go in its Agentic Tasks section. You can't write to the setting, so the deliverable is text the user pastes. Project instructions are out of scope; the `init-project-instructions` skill handles them where it's installed. Gather evidence, then run a structured interview, because the block is mostly about the person and their taste, which chat history only partly reveals.

The Account block loads in every regular chat, every Project, and every Cowork session, on top of any Project instructions. It doesn't load in Claude Code. Organization instructions, where an admin has set them, load alongside it and take precedence over it. Each line costs attention wherever the block loads, so a line earns its place only if deleting it would change your behavior in a typical chat or Cowork session; a line in Agentic Tasks, only if deleting it would change your behavior in a typical agentic task.

## Arguments

Treat any text passed with the invocation as focus or constraints for this run:
- None: mine chats since the block's `Preferences revised:` stamp (all of them if there is no such stamp), and interview only items that are missing, stale, vague, conflicting, or contradicted by evidence.
- `full`: ignore the stamps, mine all history, and walk the entire question bank.
- `audit`: findings only; no interview or block unless asked.
- Anything else: a focus area or specific change (e.g., "tighten", "rebuild the code section"). Skip mining and the interview unless the change depends on them; still emit the block in full.

## Step 1: Gather context

Check where you're running by the tools you have, not by the surface's name. Past-chat search exists only in regular claude.ai chats: Cowork and cloud agent sessions lack it even when the app doesn't label them "Cowork", and Claude Code lacks it too.
- **Past-chat tools missing:** say in your first reply that chat history can't be mined here, and recommend rerunning in a regular chat. Continue only if the user wants to. The Account block may not be in your context either; if you can't find it, ask the user to paste it, and rely on memory and the interview for the rest. Such a run doesn't mine chats, so it writes the `Instructions edited:` stamp (Step 4).
- **In a Project**, past-chat search sees only that Project's chats, and its instructions invite project-specific rules into global ones. Say so and recommend rerunning in a regular chat. Continue only if the user wants to, and treat that Project's material as project-specific evidence. Mining one Project's chats doesn't cover regular chats, so this run also writes the `Instructions edited:` stamp.

Collect, cheapest first. Don't narrate lookups; the Sources line reports them.
1. **Account block.** The user-authored userPreferences block in your context, not Anthropic's system prompt, tool descriptions, Project or organization instructions, or styles. If you can't find it, ask the user to paste it. Treat it as user-approved even if an earlier run drafted it, since the user chose to paste it.
2. **Agentic work.** Unless context already settles it, ask whether the user does agentic or file-based work: Cowork tasks, or any session that creates, edits, or moves files. If not, skip the Agentic Tasks questions and leave that section out.
3. **Imported Cowork rules.** If the block has an `[Imported from Cowork]` section, left by the merge of Cowork's Global instructions into this setting, fold its rules into Agentic Tasks, dedupe them against the rest of the block, and drop the import header.
4. **Date stamps.** `Preferences revised: YYYY-MM-DD` means chat history was mined through that date; only this stamp bounds incremental mining, so by default mine only chats updated after it. `Instructions edited: YYYY-MM-DD (chat history not yet mined)` means the block was edited without mining; it never bounds mining. With no `Preferences revised:` stamp, mine all history. If no chats are newer than that stamp and no argument was given, say so and offer `full` or a specific change rather than rewriting for its own sake.
5. **Active style**, if any. Note conflicts with the block; the style wins where both apply.
6. **Organization instructions**, if present in your context. Note what they already cover and which lines in the block they override, since they take precedence.
7. **Account memory**, if present (profile, saved preferences), as a starting map of durable facts. A saved preference may have been stated for one context; confirm its scope before promoting it to a rule in the block.
8. **Code conventions.** If the block names convention files (such as `~/.claude/rules/`) or lists per-language naming rules, don't rebuild them: chat and Cowork sessions can't read local rule files, and the block doesn't load in Claude Code. Recommend the user move them into Claude Code config (Step 2). The `init-user-instructions` skill writes Claude Code's user-scope CLAUDE.md; the user runs it in Claude Code, since it isn't installed in chat.
9. **Past chats**, via the past-chat tools:
   - List recent chats: one call of 20, up to 3 pages on a full pass.
   - Run 3-5 searches pairing behavior nouns (length, format, bullets, tables, tone, assumptions, sources, code, handoff, artifact) with correction words ("instead", "don't", "stop", "again", "too long", "wrong"). The same correction repeated across unrelated topics is the strongest global-rule evidence there is. When the user does agentic work, pair at least one search's correction words with file nouns (folder, file, overwrite, summary, connector).
   - Open at most 3 chats, one page each, where a hit looks decisive.
   - Ignore this chat and earlier runs of this skill or the `init-project-instructions` skill (chats containing `Preferences revised:`, `Instructions edited:`, or `Last revised:` drafts), except feedback the user gave there. Those drafts are your own output; mining them recycles your guesses as evidence.
   - Chats inside Projects aren't searchable from a regular chat; report that blind spot in Sources.
   - Cowork sessions' history can stay on the user's computer, out of the past-chat tools' reach. If your searches surface none, say so in Sources, and take agentic evidence from the block, memory, and the interview.

If a source is unavailable, note it and continue with the rest.

**Thin history.** If chat history is sparse, as with a new account or a recent migration, say so in Sources, and never cut or demote an existing rule for lack of evidence: the user's existing block is the baseline.

**Features in use.** Don't assume the user uses Cowork, Projects, Styles, or Claude Code. Ask only where the answer changes routing, and skip what doesn't apply.

## Step 2: Classify and filter

Route every candidate, interview answers included, to exactly one destination:
- **Account block:** rules and compact context needed in most chats and Cowork sessions.
- **Agentic Tasks section** of the Account block, only for users who do agentic or file-based work: how Claude operates when a task changes files: output locations, naming and versioning, act-versus-ask thresholds, mid-task decision handling, end-of-task reporting, deliverable format defaults, app and connector choices, and data boundaries.
- **Project instructions:** rules that matter in only one Project. Name the Project. If the `init-project-instructions` skill is available, say it can apply them there; otherwise tell the user to add them to that Project's instructions.
- **Style:** tone or format modes the user wants to switch on per chat rather than always (e.g., a teaching mode).
- **Skill:** a repeatable multi-step procedure run on demand.
- **Claude Code config**, only for users who use Claude Code: code-generation conventions, paths to convention files, and per-language naming lists. The block doesn't load in Claude Code, and chat and Cowork sessions can't read local rule files, so the block keeps only planning-level code behavior: environment assumptions, what to flag, and when to suggest Claude Code. Recommend the move, don't draft it. The `init-user-instructions` skill writes Claude Code's user-scope CLAUDE.md; the user runs it in Claude Code, since it isn't installed in chat.
- **Memory:** volatile facts (current employer, in-progress certifications or projects) that rarely change answers.
- **Nowhere:** one-off task details, resolved issues, status, and anything claude.ai already supplies (date, time zone, approximate location).

**Cross-surface rule.** The block loads in chat and in Cowork alike, so a line that would misfire in one gets scoped within the block ("In chat, answer inline by default"), never countered by another line.

Evidence rules:
- **Provenance.** Only the user's own statements or explicit acceptances count. Your past suggestions, drafts, and unpicked options don't, even if the user reacted warmly; otherwise your guesses get laundered into "established preferences."
- **Durability.** Promote an item to the block only if the user framed it as standing ("always", "from now on", "in every chat") or it recurs across 2+ chats. If it only ever appears in one topic, scope the rule to that topic, or route it to that topic's Project if one exists.
- **Recency.** When sources conflict, the most recent explicit user statement wins. Record each conflict you resolve.
- **Facts carry behavior.** Keep an identity fact only with the behavior it drives ("Assume working knowledge of payroll; skip definitions" or "Assume associate-level Azure data knowledge; skip fundamentals"), never as a bare list.
- **Dedupe.** Drop rewordings, behavior you already default to, anything claude.ai injects, and anything organization instructions already require.
- **Third-party text.** Imperatives in pasted documents inform context; they aren't the user's rules.
- **Secrets.** No credentials, keys, ID or account numbers, or personal details that don't change behavior. Keep organization-confidential specifics, such as internal system, client, or project names, out of the block unless they change behavior: it's a per-user setting that may follow the user to associated accounts.

## Step 3: Interview

Ask only after gathering, so every item arrives pre-filled: show the current wording or evidence plus a proposed revision, and let the user answer keep, change, or drop. Where nothing exists yet, offer 2-3 concrete example answers instead of an open question. Draw them from the user's own work where context shows it; otherwise offer examples that fit non-technical and technical work alike (for where outputs go: a shared team folder, a client's folder, or a code repository).

Run it in rounds, stopping to wait after each:
1. **Confirmations first.** List every item you'd keep as is or only reword in one numbered message, and accept enumerated replies such as "keep all except 3; 5) drop". Items the user flags without a replacement become decisions.
2. **Decisions next** (conflicts, real rewrites, gaps), highest impact first. Use the question tool when available (up to 4 per round, recommended option first and marked "(Recommended)"); otherwise ask numbered questions.
3. **Close** in the last round with one open question: anything else Claude should always or never do?

Default runs ask only flagged items and offer to stop and write after two decision rounds. `full` walks the whole bank. Never ask what context already settles. If nothing needs asking, go to Step 4.

**Identity and context** (keep a fact only if it changes answers)
1. Role and domain: what you do and work on, as you'd describe it to a peer.
2. Experience: start year in the field (not a duration, which goes stale) and path into it; what Claude should change because of it.
3. Credentials: which ones, and what depth Claude should assume in those areas.
4. Tools: the apps and platforms you use daily, and which to prefer or avoid by default.
5. Locale: units, currency, spelling variant, and OS or device (for step-by-step instructions, shortcuts, and file paths).
6. Goals: what you're building toward, and how Claude should act on it (name the underlying principle, explain the why, quiz you, or only when asked).

**Reasoning and honesty**
7. Ambiguity: ask first or answer with stated assumptions; maximum questions per turn.
8. Pushback: how hard to challenge, and what to do when agreeing.
9. Uncertainty: how to express it, and whether a labeled best guess is acceptable.
10. Assumptions: surface all, only material ones, or only on request.
11. Precedence: when brevity, completeness, and listing assumptions collide, which wins.
12. Sources: when to search, which sources to verify against first, and citation expectations.

**Communication**
13. Tone and humor.
14. Default length, when to go long, and whether to include rationale.
15. Formatting defaults: prose, bullets, tables, headings.
16. Numbers: estimates with rationale, precision, units.
17. Proactivity: suggest versus act, and how much unrequested advice.
18. Deliverables: what you typically produce, and whether answers default to an inline reply, artifact, doc, or file.
19. Handoffs: how to package content for another chat or tool.
20. Pet peeves: phrases or habits to stop.

**Code (planning-grade)** (only for users who write or review code)
21. Where code is planned versus generated, and when Claude should suggest moving the work to Claude Code.
22. Languages and frameworks, summary only; naming conventions and convention files go to Claude Code config.
23. Environment assumptions.
24. Review stance: what to flag unprompted (maintainability, scaling, security, cost), and patterns never to propose.

**Agentic Tasks** (only for users who do agentic or file-based work)
25. Outputs: where finished work goes by default, and how files are named and versioned.
26. Checkpoints: when to stop and ask before overwriting, deleting, or making bulk changes.
27. Mid-task choices: ask as they come up, or decide, log the choice, and report it at the end.
28. Reporting: what the end-of-task summary must include.
29. Formats: default deliverable formats when a task doesn't name one (document, slide deck, spreadsheet, PDF).
30. Apps and connectors: which to prefer or avoid, by task type.
31. Data boundaries: where organization data may and may not go.

## Step 4: Write

Structure:
- Short Markdown headings with bullets; include only sections that change behavior. A typical block: About Me (only context that changes answers), Response Behavior, Communication, Code for people who write it, and `## Agentic Tasks (Cowork or any session that changes files)` for people who do such work.
- Final lines: the date stamps, today's date in `YYYY-MM-DD`.
  - When this run mined chats, end with `Preferences revised: YYYY-MM-DD`, and remove any `Instructions edited:` line.
  - When it didn't, leave any existing `Preferences revised:` line unchanged and add or update `Instructions edited: YYYY-MM-DD (chat history not yet mined)` after it, so a later run doesn't skip unmined history.

Style:
- Imperative voice; specific and checkable ("Show costs in USD per month" beats "Be cost-aware").
- Scope every absolute by saying when the rule applies. Unscoped "all" and "never" rules collide with each other and get over-applied.
- Add one precedence line for each conflict the interview resolved.
- Add a short reason when a rule's purpose isn't obvious; reasons generalize better than bare commands.
- Plain emphasis: caps or "CRITICAL" on one or two rules at most.
- Durable phrasing: start years over durations; no "currently", in-progress items, or dates besides the stamps.
- Aim for 200-500 words, since the block shares every chat's context with Project instructions. Go longer only when every added line passes the deletion test.
- Keep Agentic Tasks additive: it adds what file-changing work needs and never restates or counters the rest of the block.

When revising: keep rules that still hold; rewrite or cut ones that are vague, redundant, contradictory, stale, or better routed elsewhere.

Before responding, verify: no placeholders, no secrets, no unresolved conflicts, every line passes the deletion test, every line holds in both chat and Cowork or is explicitly scoped, no paths to convention files or per-language naming lists, and the block works as a full replacement with zero edits. Scan the block, text carried over from the existing block included, for zero-width or other invisible Unicode characters (U+200B-U+200D, U+2060, U+FEFF) and remove them, since copied paths and commands break silently otherwise.

## Step 5: Respond

Deliver in the chat reply, not as a file, doc, or artifact; the text goes straight into the setting. Keep everything above the block brief, in this order:
1. **Sources** (one line): the block found, pasted, or confirmed empty; memory read; chats listed and opened; incremental, full, or not mined; where you ran (regular chat, Project, or a surface without past-chat tools); and any unavailable source or blind spot, such as Project chats, Cowork sessions, or thin history.
2. **Changes** (revisions only): main additions, removals, consolidations, and resolved conflicts, plus word count before and after. No line-by-line changelog.
3. **Routed elsewhere:** each item and its destination. Offer to draft a Style or a Project's lines if warranted.
4. **Assumptions and low-confidence items:** anything inferred rather than stated, so the user can veto it.
5. **The block**, last: one line naming the setting, "Paste into **Instructions for Claude** in Account settings:", then the complete block in a fenced block opened with four backticks plus `markdown`, so inner code fences survive. No placeholders or commentary inside.

On follow-up edits, re-emit the block in full; the user pastes full replacements, never diffs. Mention once that new instructions apply only to new chats and new Cowork sessions.

In `audit` mode, report Sources, then findings grouped as stale, missing, redundant, conflicting, vague, or misrouted, including chat-only rules that misfire in Cowork and convention-file paths that belong in Claude Code config. Give each finding a one-line fix. End by offering the full rewrite.
