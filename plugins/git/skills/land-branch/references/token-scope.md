# A confirmed identity, an under-scoped token

Behind step 2's capability paragraph: why a 403 or a 404 after step 2
matched is a scope answer rather than an identity one, and the runs
that showed it.

## Per resource, not read versus write

`get_me` proves which account a token acts as and nothing about what it
may do. On one token in one run (2026-09-16) `create_pull_request`
succeeded while `pull_request_read` method `get_check_runs` returned 403
*"Resource not accessible by personal access token"*, so a write having
worked says nothing about the next read. Step 8's `gh pr checks` row is
that fallback; without it the CI row is unrunnable.

## On a private repo the same gap is a 404

GitHub answers 404 rather than confirm a private repo exists, and a
fine-grained token reaches only its resource owner's repos, or a
selection, and public ones alone while an organization's approval is
pending (docs.github.com, re-read 2026-09-29). A 404 reads as identity
first, but step 2's match has settled that, so take the 403's fallback.
The same tool reading a public repo confirms it.
Seen on a client's private repo, 2026-09-27, where the confirmed `gh`
then opened the PR.
