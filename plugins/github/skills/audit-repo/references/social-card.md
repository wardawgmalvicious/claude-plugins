# The social card

GitHub serves a repo's social preview as the Open Graph image wherever
a link to it unfurls: Slack, Teams, a browser's tab preview, a social
post. It shows nowhere on the repo page, so the only way to see one is
to unfurl a link. No API uploads it: no GraphQL mutation names an image,
and `UpdateRepositoryInput` has no field for one (2026-09-23, re-probed
2026-10-01 and 2026-10-24). So the card is made by
`render-card.py`, by the path `SKILL.md` names, and uploaded by
hand. The script's own help has its modes and exit codes.

## One template, many repos

`assets/card-template.html` is the house design: a dark grid, the
owner small above a monospace name with one accented character, a
tagline, chips, and a footer. The user chose one template with three
content angles over a design per repo on 2026-10-24, so a user's repos
share one look and a render costs one template. The angles differ in
words only.

The spec is a JSON object with every key:

| Key | Holds |
| --- | --- |
| `owner` | the account or organization |
| `name` | the repo's name |
| `accent` | one character of the name, its first occurrence coloured; `""` for none |
| `tagline` | a sentence or two; `**words**` are set bold |
| `chips` | a list of short labels, such as top-level folders |
| `foot_left` | the licence the repo's licence file names, or another short fact where there is none yet |
| `foot_right` | one short line |

Every value is HTML-escaped on the way in. A name past 18 characters is
set smaller in proportion, down to 56px. A non-breaking space, ` `
in the JSON, keeps a two-word name on one line: the first card drafted
for one repo broke "Power BI" across two (2026-10-24).

## Design limits

GitHub's page, read 2026-10-24: "a PNG, JPG, or GIF file under 1 MB",
"at least 640 by 320 pixels (1280 by 640 pixels for best display)", and
"Your image can only be shared from a public repository", which is why a
private repo's missing card is context, not a warning.

- **1280x640**, GitHub's recommended size, and **at most 1 MB**, its
  upload limit. The script fails a PNG that misses either: a wrong
  window size or display scale yields a correct-looking image at the
  wrong size with no error.
- **Everything inside a 40pt border.** Consumers crop the card to their
  own aspect ratios, and the edges go first; the template insets its
  content 100px across and 76 to 84px down.
- **Read at half size.** Most unfurls show the card at half these
  dimensions or smaller, so the name is 96px and the smallest text 19px.
  A tagline past three lines, or a name the script had to shrink far,
  reads poorly there: shorten the words, not the type.
- **No logos.** Neither GitHub's mark nor a product's: on a promotional
  card that is a trademark question, and the card reads without them.
- **No counts.** A card names folders or kinds of thing, never how many
  skills or files exist: a number drifts, and a committed image is the
  worst place to keep one current.

## Rendering

Headless Edge at its x86 path,
`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`, the only
`msedge.exe` on the user's machine (2026-10-24), with a throwaway
profile directory so the render stays off the running browser. Any
Chromium `--screenshot` renders the same page; the fonts, Segoe UI and
Cascadia Code, are Windows built-ins with declared fallbacks, so a
render elsewhere substitutes a typeface rather than breaking.

## After the upload

The audit then reads `usesCustomOpenGraphImage` as true, and prints
`openGraphImageUrl`. Whether the bytes there match the committed PNG,
which would catch a stale upload, depends on whether GitHub re-encodes
an upload: not tried yet, so the script does not compare them.
