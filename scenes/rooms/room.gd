# =============================================================================
# room.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The script that sits on the ROOT node of every room scene. It owns one piece
#   of per-room state: whether that room's puzzle has been solved yet
#   (`puzzle_complete`). Doors in the room watch this flag to decide if they're
#   locked or open.
#
#   This is deliberately tiny and generic. Each of the three real rooms reuses
#   this exact script (or extends it); what DIFFERS between rooms — the maze, the
#   climb, the trivia — is what eventually calls mark_puzzle_complete(). The room
#   itself doesn't care HOW the puzzle was solved, only THAT it was.
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - door.gd watches our `puzzle_completed` signal and unlocks when it fires.
#   - goal_zone.gd (a placeholder "finish line" in the template) calls our
#     mark_puzzle_complete() when the player steps on it. In the real rooms,
#     the maze / climb / trivia will call mark_puzzle_complete() instead.
#
# GODOT CONCEPT — "class_name"
#   `class_name Room` registers this script as a brand-new type called "Room"
#   that the whole project knows about. That lets other scripts say
#   `var r: Room = ...` and get autocomplete + type checking, and lets us test
#   `if some_node is Room:`. (door.gd and goal_zone.gd both use this.)
# =============================================================================
class_name Room
extends Node2D


# GODOT CONCEPT — "signal"
#   A signal is an announcement a node can "emit" when something happens. Other
#   nodes can "connect" a function to it and that function runs whenever the
#   signal fires. It's how nodes talk WITHOUT having to know about each other in
#   detail: the room just shouts "puzzle done!" and whoever cares (the doors)
#   reacts. This is the backbone of decoupled Godot code.
#
#   We declare our own custom signal here. We emit it in mark_puzzle_complete().
signal puzzle_completed


# Whether this room's puzzle is solved. It's @export so that, while building and
# testing, you can simply TICK it on in the Inspector to see the door open
# without actually solving anything. In normal play it starts false and gets
# flipped by mark_puzzle_complete().
@export var puzzle_complete: bool = false

# Audio cues for this room (set in the Inspector or leave empty to skip)
@export var ambience_cue: StringName = &""
@export var music_cue: StringName = &""


func _ready() -> void:
	# Start room audio if configured
	if not ambience_cue.is_empty():
		AudioManager.play_ambience(ambience_cue)
	if not music_cue.is_empty():
		AudioManager.play_music(music_cue)
	
	# Add debug ambience volume slider if in editor or debug mode
	if Engine.is_editor_hint() or OS.is_debug_build():
		_add_debug_volume_slider()


func _add_debug_volume_slider() -> void:
	# Avoid adding multiple sliders if this room reloads
	if has_node("DebugAudioBuses"):
		return
	
	var debug_scene: PackedScene = load("res://scenes/ui/debug_audio_buses.tscn")
	if debug_scene:
		var debug_ui: Node = debug_scene.instantiate()
		add_child(debug_ui)
		print("[Room] Added debug audio buses panel")
	else:
		print("[Room] WARNING: Could not load debug audio buses scene")


# -----------------------------------------------------------------------------
# mark_puzzle_complete: the ONE way the puzzle gets marked solved at runtime.
# -----------------------------------------------------------------------------
# Whatever finishes the room's challenge (the goal zone now; the maze/climb/
# trivia later) calls this. We guard against running twice so the signal only
# ever fires once per room.
func mark_puzzle_complete() -> void:
	if puzzle_complete:
		return  # already done — do nothing (and don't emit a second time)
	puzzle_complete = true
	print("[Room] Puzzle complete: ", name)
	# `emit()` fires the signal, running every connected function (e.g. each
	# door's unlock handler).
	puzzle_completed.emit()
