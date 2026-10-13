extends RefCounted
class_name VolleyReport

## Outcome telemetry for one enemy volley: did any projectile reach the
## player's area? The attack state records one per volley and consults it
## through fire_gate_open; a whiffed volley closes that gate until the
## enemy repositions (moving after a proven-bad firing angle).

## Radius around the player that counts as arrived. Generous by design:
## near-miss dodges inside it still read as success, so only volleys that
## died en route or were fully outmaneuvered become whiffs.
var arrival_radius := 32.0
var arrived := false
## Projectiles still in flight for this volley. Zero means the volley has
## settled — every shot retired (freed or reflected away) — and turns a
## missing arrival into a verdict. A volley that spawned nothing is whiffed
## immediately: every muzzle was buried or sight-skipped.
var _pending := 0


func register() -> void:
	_pending += 1


func retire() -> void:
	_pending = maxi(0, _pending - 1)


func settle_arrived() -> void:
	arrived = true


## An in-flight volley has no verdict; only a settled volley without an
## arrival is a whiff.
func is_whiffed() -> bool:
	return not arrived and _pending <= 0
