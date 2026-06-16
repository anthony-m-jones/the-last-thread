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
@export var ambience_cue: StringName = &""
@export var music_cue: StringName = &""


func _ready() -> void:
	_apply_room_audio()


func _apply_room_audio() -> void:
	var selected_ambience: StringName = ambience_cue
	var selected_music: StringName = music_cue

	if selected_ambience == &"" or selected_music == &"":
		var auto_audio: Dictionary = _auto_audio_cues_for_scene()
		if selected_ambience == &"":
			selected_ambience = auto_audio.get("ambience", &"")
		if selected_music == &"":
			selected_music = auto_audio.get("music", &"")

	if selected_ambience != &"":
		AudioManager.play_ambience(selected_ambience)
	if selected_music != &"":
		AudioManager.play_music(selected_music)


func _auto_audio_cues_for_scene() -> Dictionary:
	var scene_path: String = ""
	if get_tree().current_scene != null:
		scene_path = String(get_tree().current_scene.scene_file_path).to_lower()

	if scene_path.contains("room_01"):
		return {"ambience": &"amb.room01.loop", "music": &"music.room01.loop"}
	if scene_path.contains("room_02"):
		return {"ambience": &"amb.room02.loop", "music": &"music.room02.loop"}
	if scene_path.contains("room_03"):
		return {"ambience": &"amb.room03.loop", "music": &"music.room03.loop"}

	return {}


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
