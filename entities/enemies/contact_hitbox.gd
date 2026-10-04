extends EnemyHitbox
class_name EnemyContactHitbox

## Always-on contact surface (green slime). Damage routing stays with
## PlayerHurtbox; this script only owns cadence. Re-entry is level-
## triggered: area_entered is edge-only and a shape toggled disabled and
## back does not re-fire the player's monitor while the bodies stand
## still, so cooldown expiry re-drives contact_hit while overlap
## persists — a grind ticks on cadence, not once per approach.

const RETRY_INTERVAL := 0.1

@export var rearm_cooldown := 0.9

var _rearm_clock := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _rearm_clock <= 0.0:
		return
	_rearm_clock -= delta
	if _rearm_clock <= 0.0 and not (owner as BaseEnemy).is_dead:
		_tick_still_overlapping()


func _on_area_entered(area: Area2D) -> void:
	if _rearm_clock > 0.0 or not area is PlayerHurtbox:
		return
	_rearm_clock = rearm_cooldown


func _tick_still_overlapping() -> void:
	var hurtbox: PlayerHurtbox = null
	for area in get_overlapping_areas():
		if area is PlayerHurtbox:
			hurtbox = area
			break
	if hurtbox == null:
		return
	if (hurtbox.get_owner().combat as PlayerCombat).is_hit:
		# I-frames ate the tick; retry shortly instead of stalling until
		# the next approach.
		_rearm_clock = RETRY_INTERVAL
		return
	hurtbox.contact_hit(self)
	_rearm_clock = rearm_cooldown