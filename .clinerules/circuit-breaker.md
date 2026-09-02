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
