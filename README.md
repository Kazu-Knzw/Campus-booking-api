# Campus Equipment Booking API

REST API for reserving shared equipment (projectors, cameras, rooms) without overlapping bookings.

- **Stack:** TypeScript, Hono, Cloudflare Workers, Cloudflare D1 (SQLite)
- **Base API URL (used for all testing):** `https://campus-booking-api.6731503005.workers.dev/api`

## Files
- `src/index.ts` - routes, validation, overlap check
- `schema.sql` - tables, constraints, seed equipment
- `wrangler.toml` - Worker and D1 binding (`DB`)
- `API_CONTRACT.md` - endpoints, status codes, assumptions, ERD
- `run-tests.ps1` - runs 26 test cases against the deployed API
- `evidence_before.txt` - first-version test run (25 passed, 1 failed)
- `evidence.txt` - final test run (26 passed, 0 failed)
- `AI_LOG.md`, `QUALITY_GATE_REVIEW.md`

## Run / deploy (Windows PowerShell)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
npm install
npx.cmd wrangler login
npx.cmd wrangler d1 create campus          # copy database_id into wrangler.toml
npx.cmd wrangler d1 execute campus --remote --file=schema.sql
npx.cmd wrangler deploy                    # prints the workers.dev URL
```
Note: `schema.sql` starts with DROP TABLE, so re-running it resets all data.

## Quick test
```powershell
$B = "https://campus-booking-api.6731503005.workers.dev/api"
curl.exe -i "$B/equipment"
curl.exe -i "$B/bookings"
```

## Run all tests
```powershell
.\run-tests.ps1 -OutFile evidence.txt
```
Covers create, read, update, delete, 400, 404, 409, back-to-back bookings, PATCH overlap, and SQL-injection text. It prints PASS/FAIL per case and saves the results with the Base API URL on the first line.

## Security notes
- Every SQL statement uses `prepare().bind()`; request data is never concatenated into SQL.
- Only the five booking fields (equipmentId, borrowerName, startAt, endAt, purpose) are read from the request body.
- Every error is JSON `{ "error": "..." }`; unexpected errors return a generic 500 message.
- No authentication or CORS: the brief does not require them (no browser client).
