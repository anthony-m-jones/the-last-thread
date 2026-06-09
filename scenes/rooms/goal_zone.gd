# =============================================================================
# goal_zone.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A PLACEHOLDER "finish line" for the room template. When the player steps on
#   it, it tells the room "the puzzle is done", which unlocks the door. It exists
#   purely so the template demonstrates the full loop — solve -> door opens ->
#   walk through -> next room — without a real puzzle built yet.
#
#   In the real rooms you will DELETE this and instead call
#   room.mark_puzzle_complete() from the actual maze / climb / trivia logic.
#
# It's an Area2D, same idea as the door: it detects the player entering via the
# built-in body_entered signal (see door.gd for the fuller explanation of
# Area2D and signals).
# =============================================================================
extends Area2D


# Grab our child visual so we can grey it out once used. @onready waits until
# children exist (see door.gd for what @onready means).
@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Only the player counts.
	if not body.is_in_group("player"):
		return

	# Walk up to find the Room this zone belongs to and mark its puzzle solved.
	var room: Room = _find_room()
	if room != null:
		room.mark_puzzle_complete()
		# Visual feedback that this pad has been triggered.
		_visual.color = Color(0.3, 0.5, 0.3, 0.5)


# Same parent-walk helper as the door uses, to locate the Room root.
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
