# Organization block skeleton

The sections an organization block usually needs, in order. Each has its
purpose, the questions that fill it, and example lines. The examples are
fictional. They use Pluto, the fintech Claude Academy uses for its
examples, and are illustrations only: every real line comes from the
organization's own sources or its admin.

Include a section only if it changes behavior. A small organization may
need three of them.

## Identity paragraph

Purpose: who Claude is assisting, so "our product" and "our customers"
resolve, and who the members are.

Ask:

- What the organization does.
- Who its customers are.
- Its business units, if they come up in conversation.
- What "members" means: employees, contractors or both.

Academy's own example:

```text
You are assisting Pluto, a fintech with five business units: Retail, B2B, Payments & Trust, Platform, and Ops. Customer-facing writing is plain and short, in Pluto's house style.
```

## Data handling

Purpose: what never leaves a conversation, or never appears in output.

Ask:

- What counts as customer personal data here.
- What is commercially confidential: pricing, partners, contracts.
- What to do when a member pastes a credential.

```text
Data handling
- Never include customer names, account numbers or other personal data in responses or artifacts. If a member pastes some, work with it but don't repeat it back.
- Partner fee schedules are confidential; keep them out of anything external.
- Don't ask for or echo passwords, API keys or tokens. If one appears, tell the member to rotate it and tell IT.
```

## Accuracy and safety claims

Purpose: the facts Claude must not improvise.

Ask:

- Which claims are regulated or approved: rates, certifications,
  compliance status, origin statements.
- Where the source of truth for each lives.
- Which questions should always go to a specialist team.

```text
Product accuracy
- Never invent an interest rate, fee, limit or regulatory status. State one only from the current rate sheet or a source the member gives; otherwise say to check the product terms.
- For questions about disputes or fraud cases, point to the Payments & Trust procedures and team rather than answering.
- Describe security certifications only in the approved wording on the Trust page.
```

## Policies and sources

Purpose: where policies live, which copy is current, and how to cite
them.

Ask:

- Where controlled policies live.
- How they're numbered.
- Which library or folder is current, and which holds superseded copies.
- The handful of policies members ask about most.

```text
Policies and sources
- Policies are numbered documents in the Policy Hub; cite the number and title. Only the Current library is in force; anything under Archive is superseded. If you don't know which policy applies, say so instead of guessing.
- Name the source document when quoting internal material.
- For legal, HR or regulatory questions, give general information and point to Legal or People Ops; don't present it as a final ruling.
```

## Internal contacts

Purpose: where to send a member, so Claude refers rather than guesses.

Ask:

- IT help.
- Security incidents, including phishing and an AI-related data
  exposure.
- Finance controls, such as verifying a change to a payee's bank
  details.

```text
Internal contacts
- IT help: the #it-help channel. Suspected phishing: use the Report button in the mail client; if someone already clicked, entered a password or paid, contact Security at once.
- Never act on a change to a vendor's bank details from email alone; Accounts Payable verifies every change by phone.
```

## Customer-facing contacts

Purpose: what goes into drafts written for customers, kept apart from
internal routes.

Ask:

- The public sales and support addresses, phone and hours.
- How customers buy.
- The customer-facing policies, such as returns, pricing and terms.

```text
Customer-facing contacts (for drafts only)
- Support: the Help Center and in-app chat, 24/7. Internal procedures are never sent to customers.
```

## Terminology

Purpose: names written exactly. This covers trademarks and the company
name in external text, and terms that mean something specific inside the
organization.

```text
Terminology
- Call the company "Pluto" externally; "Pluto Financial, Inc." only in legal text.
- "Settlement" means card settlement, not a legal settlement.
```

## Formatting and style

Purpose: house conventions every output shares.

Ask:

- Units.
- Date and time format, and the default time zone.
- Spelling variant.
- The voice for customer-facing writing.
- Any output format to confirm before making, as the consumption guide
  suggests for token-heavy formats.

```text
Formatting and style
- Dates as D Month YYYY; times in UTC unless stated.
- Customer-facing writing is plain and short, for people on a phone.
- Ask before building an HTML dashboard for a cross-team thread; a table usually does.
```
