param([string]$OutFile = 'evidence.txt')
$B = "https://campus-booking-api.6731503005.workers.dev/api"
$script:out = New-Object System.Collections.ArrayList
[void]$script:out.Add("Base API URL: $B")
[void]$script:out.Add("Run at: $(Get-Date -Format s)")
[void]$script:out.Add("")

function Run($name, $expect, $method, $path, $json) {
  Remove-Item body.tmp -ErrorAction SilentlyContinue
  $a = @('-s','-o','body.tmp','-w','%{http_code}','-X',$method,"$B$path")
  if ($json) {
    Set-Content req.tmp $json -Encoding ascii -NoNewline
    $a += @('-H','Content-Type: application/json','--data-binary','@req.tmp')
  }
  $code = & curl.exe @a
  $body = ''
  if (Test-Path body.tmp) { $raw = Get-Content body.tmp -Raw; if ($raw) { $body = $raw.Trim() } }
  $mark = if ("$code" -eq "$expect") { 'PASS' } else { 'FAIL' }
  $line = "[$mark] $name | $method $path | expected $expect, got $code | $body"
  Write-Host $line
  [void]$script:out.Add($line)
  return $body
}

function BK($eq, $nm, $s, $e, $p) {
  return '{"equipmentId":"' + $eq + '","borrowerName":"' + $nm + '","startAt":"' + $s + '","endAt":"' + $e + '","purpose":"' + $p + '"}'
}

function ClearAll {
  $existing = curl.exe -s "$B/bookings" | ConvertFrom-Json
  foreach ($x in $existing) { curl.exe -s -o NUL -X DELETE "$B/bookings/$($x.id)" }
}

ClearAll

$null = Run 'List equipment' 200 GET '/equipment'
$null = Run 'List bookings (empty)' 200 GET '/bookings'
$r = Run 'Create booking A' 201 POST '/bookings' (BK 'eq-1' 'Somchai Jaidee' '2026-10-20T09:00:00.000Z' '2026-10-20T11:00:00.000Z' 'Class presentation')
$idA = ($r | ConvertFrom-Json).id
$null = Run 'Get one booking' 200 GET "/bookings/$idA"
$null = Run 'Update A to 12:00-14:00' 200 PATCH "/bookings/$idA" (BK 'eq-1' 'Somchai Jaidee' '2026-10-20T12:00:00.000Z' '2026-10-20T14:00:00.000Z' 'Updated class presentation')
$null = Run 'Overlap with A (12:30-13:30)' 409 POST '/bookings' (BK 'eq-1' 'Suda Dee' '2026-10-20T12:30:00.000Z' '2026-10-20T13:30:00.000Z' 'Conflict test')
$r = Run 'Create booking B (15:00-16:00)' 201 POST '/bookings' (BK 'eq-1' 'Bob' '2026-10-20T15:00:00.000Z' '2026-10-20T16:00:00.000Z' 'Second booking')
$idB = ($r | ConvertFrom-Json).id
$null = Run 'PATCH B into A time (overlap)' 409 PATCH "/bookings/$idB" '{"startAt":"2026-10-20T12:30:00.000Z","endAt":"2026-10-20T13:30:00.000Z"}'
$null = Run 'PATCH B purpose only (no false self-conflict)' 200 PATCH "/bookings/$idB" '{"purpose":"Changed purpose"}'
$null = Run 'Back-to-back 14:00-15:00 allowed' 201 POST '/bookings' (BK 'eq-1' 'Cy' '2026-10-20T14:00:00.000Z' '2026-10-20T15:00:00.000Z' 'Back to back')
$null = Run 'Same time, different equipment' 201 POST '/bookings' (BK 'eq-2' 'Dan' '2026-10-20T12:00:00.000Z' '2026-10-20T14:00:00.000Z' 'Other equipment')
$null = Run 'Unknown equipmentId' 404 POST '/bookings' (BK 'eq-999' 'Bob' '2026-10-22T09:00:00.000Z' '2026-10-22T10:00:00.000Z' 'x')
$null = Run 'Malformed JSON' 400 POST '/bookings' '{bad'
$null = Run 'Missing borrowerName' 400 POST '/bookings' '{"equipmentId":"eq-1","startAt":"2026-10-22T09:00:00.000Z","endAt":"2026-10-22T10:00:00.000Z","purpose":"x"}'
$null = Run 'borrowerName wrong type (number)' 400 POST '/bookings' '{"equipmentId":"eq-1","borrowerName":123,"startAt":"2026-10-22T09:00:00.000Z","endAt":"2026-10-22T10:00:00.000Z","purpose":"x"}'
$null = Run 'startAt after endAt' 400 POST '/bookings' (BK 'eq-1' 'Bob' '2026-10-21T11:00:00.000Z' '2026-10-21T09:00:00.000Z' 'Invalid range')
$null = Run 'startAt equals endAt' 400 POST '/bookings' (BK 'eq-1' 'Bob' '2026-10-21T11:00:00.000Z' '2026-10-21T11:00:00.000Z' 'Zero length')
$null = Run 'Non-ISO dates ("1" and "2")' 400 POST '/bookings' (BK 'eq-1' 'Lenient' '1' '2' 'date test')
$null = Run 'PATCH missing booking' 404 PATCH '/bookings/not-found' '{"purpose":"x"}'
$null = Run 'PATCH empty body' 400 PATCH "/bookings/$idB" '{}'
$null = Run 'Get missing booking' 404 GET '/bookings/not-found'
$null = Run 'SQL injection text in borrowerName stored safely' 201 POST '/bookings' (BK 'eq-3' "x'); DROP TABLE bookings;--" '2026-10-25T09:00:00.000Z' '2026-10-25T10:00:00.000Z' 'injection test')
$null = Run 'Bookings table still works after injection' 200 GET '/bookings'
$null = Run 'Delete A' 204 DELETE "/bookings/$idA"
$null = Run 'Get A after delete' 404 GET "/bookings/$idA"
$null = Run 'Delete A again' 404 DELETE "/bookings/$idA"

ClearAll
$fails  = @($script:out | Where-Object { $_ -match '^\[FAIL\]' }).Count
$passes = @($script:out | Where-Object { $_ -match '^\[PASS\]' }).Count
[void]$script:out.Add("")
[void]$script:out.Add("SUMMARY: $passes passed, $fails failed")
Write-Host "SUMMARY: $passes passed, $fails failed"
$script:out | Set-Content $OutFile -Encoding utf8
Remove-Item body.tmp, req.tmp -ErrorAction SilentlyContinue
