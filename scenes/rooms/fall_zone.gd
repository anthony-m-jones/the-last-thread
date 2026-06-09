# =============================================================================
# fall_zone.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A safety net. It's an Area2D you stretch across the bottom of a pit. If the
#   player falls into the pit and touches this zone, we gently put them back at a
#   respawn point instead of letting them fall forever. This keeps the Room 3
#   dash-gap from being frustrating: miss the dash, and you simply land back on
#   solid ground to try again.
#
# WHY THIS DOESN'T BREAK THE ABILITY GATE
#   The pit it guards is an EMPTY gap (no walls), so wall-jump can't help you
#   climb across it — only a dash carries you over. Falling in just returns you
#   to the start side. So the dash remains required to reach the far side.
#
# HOW TO USE IT
#   Place this Area2D below a pit (give it a wide CollisionShape2D). Set the
#   "Respawn Position" export to where the player should reappear (somewhere safe
#   on the near side of the pit).
# =============================================================================
extends Area2D


# Where to drop the player when they fall in. This is in GLOBAL coordinates
# (world position). Set it in the Inspector to a safe spot on the floor.
@export var respawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# React to bodies entering this zone (see door.gd for the Area2D explanation).
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Only rescue the player.
	if not body.is_in_group("player"):
		return

	# Move the player to the respawn point and stop their motion so they don't
	# arrive still falling fast. `global_position` is the world-space position;
	# zeroing `velocity` resets the CharacterBody2D's movement.
	body.global_position = respawn_position
	body.velocity = Vector2.ZERO
	print("[FallZone] Player fell; respawned at ", respawn_position)
