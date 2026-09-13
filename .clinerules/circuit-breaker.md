# Circuit Breaker — Failure Containment

> **Purpose:** Stop runaway retries on a broken step and force an explicit handoff back to the user.

## Rule
- A **failed attempt** = a command/script run that errors, exits non-zero, or fails its own verification gate.
- After **3 consecutive failed attempts** on the same task step: STOP — no 4th attempt.
- Deliver an error report: attempts made (in order), exact failure output (trimmed, not re-run), current repo state (`git status` summary + HEAD), and proposed recovery options.
- Resume only after the user decides.

## Hygiene
- Dry-run / plan-only output before any bulk operation (mass renames, rewrites, generated edits).
- Verification scripts cap and dedupe their output — no multi-thousand-line dumps.
- After any failed bulk operation, quantify damage read-only before fixing or rolling back.

## Debug loops — reactive patching is the failure mode
- A "step" is the goal, not the run: consecutive run → read one symptom → patch → run cycles against the same failing gate count as attempts, even when each patch is different. Three such cycles on one gate = breaker tripped.
- After the 2nd failed attempt on a step, the next action must be a READ, not a patch: enumerate every path that can produce the symptom (all exit/queue_free sites, all scene-file signal connections, full stderr — not stdout only) and name the mechanism before touching code again.
- Bugs in the test/probe harness itself count as failed attempts; fix the instrument and capture the named cause in the same iteration.
- Attempt 3 must end in either a fix justified by a named mechanism (file, line, signal, or body identity) or the failure report. No 4th attempt, no "one more probe tweak".
