---
name: golang-troubleshooting
description: Diagnose Go failures methodically using focused reproduction, tests, race detection, and standard tooling.
license: MIT
---

# Go Troubleshooting

Start with a reliable reproduction and a failing regression test. Change one
hypothesis at a time, use `go test -race` for suspected concurrency faults, and
use profiles only after measuring a performance problem. Do not mask symptoms
with broad retries, recover blocks, or nil checks.
