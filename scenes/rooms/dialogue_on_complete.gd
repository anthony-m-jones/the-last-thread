# =============================================================================
# dialogue_on_complete.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A tiny "play a conversation when this room's puzzle is solved" node. Drop it
#   into a room, point it at a .dialogue file + title, and when the room emits its
#   `puzzle_completed` signal (maze done / climb done / trivia done) this plays
#   that conversation. It's how the Weaver's CLOSING BEAT in each room — and the
#   Room 3 tapestry reveal — get triggered.
#
# WHY THIS EXISTS
#   The ability cats (interactable.gd) play dialogue when you TALK to them. But
#   the Weaver's "you did it" lines should fire when the PUZZLE finishes, which is
#   a different trigger. room.gd already announces that via its `puzzle_completed`
#   signal; this node just listens for it and plays a conversation. Reusable in
#   every room.
#
# HOW IT CONNECTS
#   - Finds its Room (room.gd) by walking up parents (same trick as door.gd).
#   - Connects to that room's `puzzle_completed` signal.
#   - Plays the conversation through the DialogueManager autoload.
# =============================================================================
extends Node


# The .dialogue file and the titled conversation inside it to play when the
# puzzle is solved. Set both in the Inspector.
@export var dialogue_file: DialogueResource
@export var dialogue_title: String = "complete"


func _ready() -> void:
	var room: Room = _find_room()
	if room == null:
		push_warning("DialogueOnComplete is not inside a Room — it will never fire.")
		return
	# Subscribe to the room's "puzzle solved!" announcement.
	room.puzzle_completed.connect(_on_puzzle_completed)


# Runs once, when the room's puzzle is marked complete.
func _on_puzzle_completed() -> void:
	if dialogue_file == null:
		# No conversation assigned yet (placeholder phase) — just note it.
		print("[DialogueOnComplete] Puzzle done, but no dialogue_file set.")
		return
	# Play the Weaver's closing beat. We don't await it here — the room is already
	# solved and the door already open, so the player can read it and move on.
	DialogueManager.show_dialogue_balloon(dialogue_file, dialogue_title)


# Walk up the parent chain to find the Room this node sits in (same helper
# pattern as door.gd / goal_zone.gd / trivia.gd).
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
