# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
AI rework restart prep (2026-09-13): the enemy/missile AI attempt was rolled back
pre-commit. **`memory-bank/ai-rework-log.md` is the spec for the fresh start.**
Next build task after the AI restart: R-40 room-block standard, then R-41 slice.

## Just Landed
- `docs(rules)` research policy, standalone-voice commits, debug-loop breaker
- `docs(memory)` engine facts block in techContext.md; ai-rework-log.md added
- All AI-related working-tree changes reverted to HEAD (enemies, projectiles,
  NavBaker, probes, test_room/ui edits); working tree clean at push point

## Working Agreements
- AI restart: read `ai-rework-log.md` first; resurrect NavBaker + both probes
  (probe-green before rollback), then missile homing + pass-by leniency,
  necromancer without LOS gating, archer with LOS + plain approach. No vantage ring.
- Pickups: `scatter()` = validated landing; no physics bodies; never `await`
  timers on freed instances
- Wall-decor rule: alignment-sensitive decor = entity (rotate/flip); filler decor = tile
- Circuit breaker: 3 attempts per gate; read-before-patch; named mechanisms
- Research rule: validate engine APIs against the class reference before use

## Known Limits (accepted)
- `Environment` container not y-sorted: chests/props sort vs player as one block; fix deliberately in R-40/R-41
- Stale editor script cache strips unknown exports on save - restart editor after agent disk edits

## Verification Gates
- gdlint on touched files; baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- `--headless --import` before headless runs; boots `--quit-after 5`
- Headless engine runs need `Start-Process -Wait -PassThru` (PowerShell)
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. AI restart per `ai-rework-log.md` (NavBaker + probes, then missile/enemy behavior)
2. R-40 room-block standard: patterns + descent room-type conventions
3. R-41 tier-1 vertical slice; E-1 lesser skelly (blocked on user sheet pick)

## Open Decisions
- Wand input binding + potion carry model: settle at S-5/S-6 implementation
- Depth room-mix shape + director numbers: provisional until playtest
- Public release: replace unknown-origin assets (HUD art, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use
