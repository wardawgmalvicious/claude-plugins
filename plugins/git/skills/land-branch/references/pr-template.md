# A repo's own pull request template

Both of step 5's routes pass a body, so GitHub prefills nothing, and a
repo's template goes unused unless the session reads it
(`gh pr create --help`, 2026-11-02). Look for one:

```bash
git ls-files | grep -iE '^(\.github/|docs/)?pull_request_template(\.[^/]+)?$'
```

**On a hit, Read it**, `.github/` first, then the root, then `docs/`, the
order GitHub's docs give. Write the body under its headings in its order,
following its comments, then delete the comments and any heading that does
not apply. Whatever step 5's list owes still goes in, under the closest
heading or a new one: a template that never heard of a concurrent-session
commit does not excuse disclosing one.

**With no hit, step 5's list is the shape.** That includes a repo holding a
`PULL_REQUEST_TEMPLATE/` folder alone, which the grep does not match, since
GitHub's docs have that folder chosen with `?template=`, not filled by
default.
