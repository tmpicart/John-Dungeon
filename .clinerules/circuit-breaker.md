# Circuit Breaker — Failure Containment

> **Purpose:** Stop runaway retries on a broken step and force an explicit handoff back to the user.

## Rule
- A **failed attempt** = a command/script run that errors, exits non-zero, or fails its own verification gate. Bugs in the test/probe harness count; fix the instrument and capture the named cause in the same iteration.
- A "step" is the goal, not the run: symptom → patch → rerun cycles against one failing gate count as attempts even when each patch differs.
- After the 2nd failed attempt: the next action is a READ, not a patch — enumerate every path that can produce the symptom (all exit/`queue_free` sites, scene-file signal connections, full stderr) and name the mechanism before touching code again.
- After **3 failed attempts** on a step: STOP — no 4th attempt. Attempt 3 must end in a fix citing a named mechanism (file, line, signal, or body identity) or in the failure report: attempts made (in order), trimmed failure output (not re-run), repo state (`git status` summary + HEAD), and recovery options. Resume only after the user decides.

## Hygiene
- Dry-run / plan-only output before bulk operations; verification scripts cap and dedupe their output.
- After a failed bulk operation, quantify damage read-only before fixing or rolling back.
