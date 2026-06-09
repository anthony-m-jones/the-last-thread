# =============================================================================
# reveal_on_complete.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A tiny "swap one picture for another when this room's puzzle is solved" node.
#   It's built for the Room 3 silk-tapestry REVEAL: at first you see the draped,
#   COVERED tapestry; when the trivia is solved the silk "falls away" and the
#   REVEALED tapestry crossfades in. Purely cosmetic — it changes no game state.
#
# WHY THIS EXISTS
#   The room already announces "puzzle solved!" via room.gd's `puzzle_completed`
#   signal (the same signal that opens the door and plays the Weaver's closing
#   lines). This node just listens for that and crossfades two sprites, so the
#   reveal lands at the exact moment the Weaver says "let me show you what we
#   wove." It mirrors dialogue_on_complete.gd, but for art instead of dialogue.
#
# HOW TO USE IT
#   - Put two overlapping Sprite2Ds in the room at the same spot: the covered
#     tapestry and the revealed tapestry.
#   - Add a Node with this script and point `covered_path` / `revealed_path` at
#     them in the Inspector.
#   - At startup the revealed one is hidden (alpha 0); on completion they cross-
#     fade over `fade_time` seconds.
#
# GODOT CONCEPT — recap
#   `modulate` is a CanvasItem's tint+opacity; `modulate:a` is just its alpha
#   (0 = invisible, 1 = solid). A Tween animates that value smoothly over time.
# =============================================================================
extends Node


# The two overlapping pictures. covered = what you see before; revealed = what
# fades in after the puzzle is solved. Set both in the Inspector.
@export var covered_path: NodePath
@export var revealed_path: NodePath

# How long the crossfade takes, in seconds. Slow + gentle suits the moment.
@export var fade_time: float = 1.5


func _ready() -> void:
	# Hide the revealed picture until the big moment (start fully transparent but
	# present, so the crossfade has something to fade IN).
	var revealed: CanvasItem = _get_canvas_item(revealed_path)
	if revealed != null:
		revealed.show()
		revealed.modulate.a = 0.0

	var room: Room = _find_room()
	if room == null:
		push_warning("RevealOnComplete is not inside a Room — it will never fire.")
		return
	room.puzzle_completed.connect(_on_puzzle_completed)


# Runs once, when the room's puzzle is marked complete (trivia solved).
func _on_puzzle_completed() -> void:
	var covered: CanvasItem = _get_canvas_item(covered_path)
	var revealed: CanvasItem = _get_canvas_item(revealed_path)

	# One tween running both fades at the same time (set_parallel) so the silk
	# fades out exactly as the portrait fades in.
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	if revealed != null:
		tween.tween_property(revealed, "modulate:a", 1.0, fade_time)
	if covered != null:
		tween.tween_property(covered, "modulate:a", 0.0, fade_time)


# Safely fetch a node at a path and only return it if it's something we can fade
# (a CanvasItem = any 2D visual like Sprite2D). Returns null otherwise.
func _get_canvas_item(path: NodePath) -> CanvasItem:
	if path.is_empty():
		return null
	var node: Node = get_node_or_null(path)
	if node is CanvasItem:
		return node
	return null


# Walk up the parent chain to find the Room this node sits in (same helper
# pattern as door.gd / dialogue_on_complete.gd / trivia.gd).
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
