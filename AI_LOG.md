# AI_LOG

AI tool used: Claude (chat), as a development assistant.

| # | Prompt (short) | What I used | What I changed / rejected | How I verified it myself |
|---|---|---|---|---|
| 1 | Asked for an API design and Hono + D1 implementation for the booking scenario | Route structure, schema, overlap query, validation approach | The first answer used a different contract (/resources, PUT, 422). After sharing the real brief and rubric it was rewritten to match (/equipment, PATCH, 400/404/409) | Deployed it and ran the curl tests from curl_test_guide.md; checked each status code |
| 2 | Asked how to run it on Windows after PowerShell errors (&&, script policy) | Set-ExecutionPolicy for the session, npx.cmd, separate commands | I mistakenly pasted a file-tree diagram as commands; ignored the errors | Commands ran and the install completed |
| 3 | Asked how to deploy to Cloudflare instead of localhost (instructor requirement) | wrangler login, d1 create, d1 execute --remote, wrangler deploy | Created a new D1 database (campus) instead of reusing studentdb | GET /api/equipment on the workers.dev URL returned the 3 seeded items |
| 4 | Pasted test output with unexpected 404 and 201 results | Explanation that my $ID placeholder was never replaced, so PATCH never ran | Re-ran the sequence with the real booking id | The overlap request then returned 409 |
| 5 | Asked how to pass the Quality Gate | A PowerShell test script (run-tests.ps1) and an ISO date check fix | I ran the script first and saw the real failure before fixing it | evidence_before.txt (25 pass, 1 fail) then evidence.txt (26 pass, 0 fail) |

## Decisions I can explain without AI
- Overlap rule: `existing.start < new.end AND existing.end > new.start`, and why touching times are allowed.
- Why check and write are one SQL statement (no race between two simultaneous requests).
- Why 400 vs 404 vs 409, and why an unknown equipmentId is 404.
- How `.bind()` parameter binding prevents SQL injection.
- Why PATCH merges fields and re-validates the whole booking.
- Why Date.parse was too lenient and what the ISO format check does.
