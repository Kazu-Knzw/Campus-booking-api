# API Contract

Base URL: `https://campus-booking-api.6731503005.workers.dev/api`

## Endpoints
| Method | Path | Success | Errors |
|---|---|---:|---|
| GET | /equipment | 200 | |
| GET | /bookings (optional `?equipmentId=`) | 200 | |
| GET | /bookings/:id | 200 | 404 |
| POST | /bookings | 201 | 400, 404, 409 |
| PATCH | /bookings/:id | 200 | 400, 404, 409 |
| DELETE | /bookings/:id | 204 (no body) | 404 |

## Booking payload (POST needs all fields; PATCH accepts any subset)
```json
{ "equipmentId": "eq-1", "borrowerName": "Somchai Jaidee",
  "startAt": "2026-10-20T09:00:00.000Z", "endAt": "2026-10-20T11:00:00.000Z",
  "purpose": "Class presentation" }
```
Responses also include `id` (UUID) and `createdAt`.

## Error format
Every error is JSON: `{ "error": "message" }`

## Why 400, 404, 409
- **400 Bad Request:** the request itself is invalid: malformed JSON, missing or wrong-type field, a date that is not ISO 8601, `startAt` not before `endAt`, or an empty PATCH.
- **404 Not Found:** something the request points to does not exist: the booking id in the URL, the `equipmentId` in the body, or an unknown route.
- **409 Conflict:** the request is valid, but it clashes with existing data: the equipment is already booked for an overlapping time.
- **500:** unexpected failure; generic message, details only in server logs.

## Overlap rule
Two bookings for the same equipment overlap when `existing.startAt < new.endAt AND existing.endAt > new.startAt`.
Back-to-back bookings (one ends at 11:00, the next starts at 11:00) are allowed.
The check and the write are one SQL statement (`INSERT ... WHERE NOT EXISTS` for create, `UPDATE ... WHERE NOT EXISTS` for update), so two simultaneous requests cannot both succeed. On update, the booking being edited is excluded from the check so it never conflicts with itself.

## Assumptions
1. POST requires all five fields. PATCH merges the given fields into the existing booking, then validates the whole result.
2. An unknown `equipmentId` returns 404, because equipment is a resource that was not found.
3. Dates must be ISO 8601 with a time and a timezone (for example `2026-10-20T09:00:00.000Z`). They are normalized to UTC, so text comparison equals time comparison.
4. DELETE is a hard delete; the time slot becomes free immediately.
5. No authentication, as the brief does not require it.

## Schema / ERD
```
equipment 1 ----< bookings
equipment: id PK (text), name, location
bookings:  id PK (uuid), equipment_id FK -> equipment.id, borrower_name,
           start_at, end_at, purpose, created_at
           CHECK (start_at < end_at); INDEX (equipment_id, start_at, end_at)
```
