# =============================================================================
# title_screen.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The game's title screen. It shows the painted title art (which already has
#   "The Last Thread" lettering baked in) plus a "Press [Enter] to begin" prompt,
#   a glowing thread line, and a tagline. Pressing Enter fades to the first room.
#
#   The fade is handled by the SceneTransition autoload, so this screen also eases
#   up from black on launch (SceneTransition does that automatically).
# =============================================================================
extends Control


# Where "Enter" takes the player. Set in the Inspector if the first room changes.
@export_file("*.tscn") var first_room_path: String = "res://scenes/rooms/room_01.tscn"


var _started: bool = false  # guards against starting twice mid-fade


func _ready() -> void:
	_start_idle_animations()


# Gentle looping shimmer so the screen feels alive. All via `modulate:a`
# (opacity), which is always safe to tween regardless of UI layout.
func _start_idle_animations() -> void:
	var tagline_tween: Tween = create_tween().set_loops()
	tagline_tween.tween_property($Prompt/Tagline, "modulate:a", 0.45, 1.4)
	tagline_tween.tween_property($Prompt/Tagline, "modulate:a", 1.0, 1.4)

	var thread_tween: Tween = create_tween().set_loops()
	thread_tween.tween_property($Prompt/Thread, "modulate:a", 0.35, 1.7)
	thread_tween.tween_property($Prompt/Thread, "modulate:a", 0.95, 1.7)

	var key_tween: Tween = create_tween().set_loops()
	key_tween.tween_property($Prompt/Line1/EnterKey, "modulate:a", 0.7, 1.3)
	key_tween.tween_property($Prompt/Line1/EnterKey, "modulate:a", 1.0, 1.3)


# Enter (or any "accept" input / the Enter key box click) begins the game.
func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event.is_action_pressed("ui_accept"):
		_start_game()


func _start_game() -> void:
	if _started:
		return
	_started = true
	# SceneTransition fades to black, loads the first room, then fades back in.
	SceneTransition.change_scene_to_file(first_room_path)
