# =============================================================================
# tapestry_finale.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The little cinematic that plays AFTER the Room 3 trivia is solved and the
#   Weaver's "complete" dialogue finishes. Instead of just handing control back,
#   we:
#       1. keep the player held still,
#       2. pan the camera UP to the silk tapestry,
#       3. crossfade the revealed (unfinished) tapestry into the FINISHED one
#          (Tobers woven in at last),
#       4. linger a moment,
#       5. pan back to the player and return control.
#
# HOW IT FITS THE EXISTING PIECES
#   - reveal_on_complete.gd already does the FIRST reveal (covered -> revealed)
#     the instant the puzzle is solved, so the revealed tapestry is showing while
#     the Weaver talks. THIS script does the SECOND beat (revealed -> complete)
#     once that dialogue ends.
#   - It reuses GameState's cutscene-hold counter (the same lock the Weaver and
#     the trivia use) so the player can't run off during the pan. We grab the
#     lock the moment the dialogue ends — before the Weaver's own hold expires —
#     so control never flickers back to the player mid-cinematic.
#
# GODOT CONCEPT — recap
#   `modulate:a` = a sprite's opacity (0..1); a Tween animates it for a crossfade.
#   A Camera2D's `global_position` is the CENTRE of what it shows; the player's
#   camera is a child of the player, so we pan by tweening the camera's own
#   `position` and tween it back when we're done.
# =============================================================================
extends Node


# The two tapestry sprites to crossfade in step 3 (revealed -> finished).
@export var revealed_path: NodePath
@export var complete_path: NodePath
# The node the camera should centre on while panning (point this at the tapestry).
@export var camera_target_path: NodePath

@export_group("Timing (seconds)")
@export var pan_up_time: float = 1.6          # how long the pan up takes
@export var hold_before_transform: float = 0.6  # beat before the tapestry changes
@export var transform_time: float = 2.0       # the revealed -> finished crossfade
@export var hold_after_transform: float = 1.8  # let the finished image land
@export var pan_back_time: float = 1.4        # pan back down to the player

@export_group("Framing")
# Nudge the framed view (e.g. Vector2(0, -40) to sit a little higher on the art).
@export var camera_offset: Vector2 = Vector2.ZERO


var _armed: bool = false    # true once the puzzle is solved (ignore earlier dialogue)
var _played: bool = false   # the cinematic runs only once


func _ready() -> void:
	# The finished tapestry waits invisible (but present) until the transform.
	var comp: CanvasItem = _canvas_item(complete_path)
	if comp != null:
		comp.show()
		comp.modulate.a = 0.0

	var room: Room = _find_room()
	if room == null:
		push_warning("TapestryFinale is not inside a Room — it will never fire.")
		return
	room.puzzle_completed.connect(_on_puzzle_completed)
	# We watch for dialogue endings, but only act on the FIRST one after the
	# puzzle is solved (that's the Weaver's "complete" beat).
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_puzzle_completed() -> void:
	_armed = true


func _on_dialogue_ended(_resource: Resource) -> void:
	if not _armed or _played:
		return
	_played = true
	_run_finale()


# The cinematic itself. `await` lets each step finish before the next begins.
func _run_finale() -> void:
	# Hold the player NOW, before the Weaver's own cutscene-hold expires, so there
	# is no frame where control slips back. Released at the very end.
	GameState.begin_cutscene_hold()

	var cam: Camera2D = get_viewport().get_camera_2d()
	var cam_home: Vector2 = Vector2.ZERO  # the camera's resting local position

	# --- Step 1: pan UP to the tapestry ---
	if cam != null:
		cam_home = cam.position
		var target: Node2D = _node2d(camera_target_path)
		if target != null:
			# Shift the camera by the world-space delta needed to centre on the
			# tapestry. (Camera limits from CameraBounds still clamp the view.)
			var delta: Vector2 = (target.global_position + camera_offset) - cam.global_position
			var pan: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			pan.tween_property(cam, "position", cam.position + delta, pan_up_time)
			await pan.finished

	if hold_before_transform > 0.0:
		await get_tree().create_timer(hold_before_transform).timeout

	# --- Step 2: crossfade revealed -> finished ---
	var rev: CanvasItem = _canvas_item(revealed_path)
	var comp: CanvasItem = _canvas_item(complete_path)
	var fade: Tween = create_tween().set_parallel(true)
	if comp != null:
		fade.tween_property(comp, "modulate:a", 1.0, transform_time)
	if rev != null:
		fade.tween_property(rev, "modulate:a", 0.0, transform_time)
	await fade.finished

	if hold_after_transform > 0.0:
		await get_tree().create_timer(hold_after_transform).timeout

	# --- Step 3: pan back down to the player ---
	if cam != null:
		var back: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		back.tween_property(cam, "position", cam_home, pan_back_time)
		await back.finished

	# Hand control back to the player so they can reach the exit door.
	GameState.end_cutscene_hold()


# --- small helpers (same patterns as reveal_on_complete.gd) ---

func _canvas_item(path: NodePath) -> CanvasItem:
	if path.is_empty():
		return null
	var node: Node = get_node_or_null(path)
	return node if node is CanvasItem else null


func _node2d(path: NodePath) -> Node2D:
	if path.is_empty():
		return null
	var node: Node = get_node_or_null(path)
	return node if node is Node2D else null


func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
