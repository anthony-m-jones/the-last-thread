# =============================================================================
# scene_transition.gd  (autoload singleton "SceneTransition")
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A global fade-to-black between scenes. It owns one full-screen black panel
#   that lives ABOVE everything (its own high CanvasLayer), and persists across
#   scene changes because autoloads are never destroyed.
#
#   Use it instead of get_tree().change_scene_to_file(...):
#       SceneTransition.change_scene_to_file("res://scenes/rooms/room_02.tscn")
#   and it will: fade to black -> swap the scene -> fade back in. It also fades
#   IN once when the game first launches, so you never see a hard cut.
#
# WHY AN AUTOLOAD (recap)
#   An autoload is a node Godot loads once at startup and keeps alive for the
#   whole game, outside any single scene. That's exactly what a transition
#   overlay needs — it has to survive the very scene swap it's animating.
#
# GODOT CONCEPT — recap
#   A CanvasLayer draws in screen space on top of the world; `layer` sets the
#   draw order (higher = more in front). `modulate:a` is opacity (0 = invisible,
#   1 = solid). A Tween animates that for the fade.
# =============================================================================
extends CanvasLayer


# How long each half of the transition takes, in seconds (fade out and fade in).
@export var fade_time: float = 0.4


# The black panel we fade. Created in code so this needs no .tscn.
var _rect: ColorRect
# True while a transition is mid-flight, so two doors can't fire it at once.
var _busy: bool = false


func _ready() -> void:
	# Draw above ALL game UI (dialogue balloon, HUD, credits...). Keep running even
	# if the tree is ever paused.
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 1)              # solid black; we fade its opacity
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat clicks
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # cover screen
	_rect.modulate.a = 1.0                        # start black...
	add_child(_rect)

	# ...then fade in, so the first scene of the game eases up from black.
	_fade_to(0.0)


# -----------------------------------------------------------------------------
# change_scene_to_file: fade out, swap to `path`, fade back in.
# -----------------------------------------------------------------------------
# Safe to call from a physics callback (a door/exit trigger): the actual scene
# swap happens AFTER the fade-out await, i.e. on idle time, so we never free
# collision nodes mid-physics (no call_deferred needed).
func change_scene_to_file(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)                      # to black
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame           # let the new scene spin up
	await get_tree().process_frame
	await _fade_to(0.0)                      # back in
	_busy = false


# Reload the current scene with the same fade (used by a door with no target set).
func reload_current_scene() -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


# Tween the black panel's opacity to `target_alpha` (0 = clear, 1 = black).
func _fade_to(target_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", target_alpha, fade_time)
	await tween.finished
