# QUALITY_GATE_REVIEW

Snapshot at minute 30: evidence_before.txt (first-version test run, 25 passed / 1 failed) and a screenshot of that output.

| Quality Gate area | Finding | Action taken | Evidence |
|---|---|---|---|
| Accuracy | `startAt: "1"` and `endAt: "2"` were accepted (201) and silently saved as 2001-01-01 and 2001-02-01, because Date.parse is lenient | Added an ISO 8601 format check in `isoTime` and redeployed | evidence_before.txt: "Non-ISO dates" expected 400, got 201 (FAIL). evidence.txt: the same test returns 400 (PASS) |
| Delivery Quality | The README told the reader to run the API on localhost, but the instructor requires a deployed URL | Replaced it with the Cloudflare deploy steps and the Base API URL | README.md lists https://campus-booking-api.6731503005.workers.dev/api |
| Reasoning / You Own It | My first overlap test returned 201 instead of 409. A placeholder id was left in my commands, so the PATCH never moved booking A and the two times did not overlap | Re-ran with the real booking id, then wrote run-tests.ps1 so ids are captured automatically | PATCH returned 200 and the same POST then returned 409; evidence.txt shows both the POST-overlap and PATCH-overlap cases returning 409 |

Final re-test: ran run-tests.ps1 after the fix; evidence.txt shows 26 passed, 0 failed.
