# =============================================================================
# credits.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The end-of-game credits screen. Room 3's tapestry finale transitions here once
#   the finished tapestry has been revealed. It's just a black screen with text
#   that gently fades in.
#
# HOW TO EDIT IT (no code needed)
#   Select the Credits root node in credits.tscn and edit these in the Inspector:
#   Title Text, Credits Text (multi-line), Closing Text, Fade In Time. The labels
#   update from those values when the scene runs.
# =============================================================================
extends Control


# The big title at the top.
@export var title_text: String = "The Last Thread"

# The main credits block (multi-line — press Enter for new lines in the Inspector).
@export_multiline var credits_text: String = "For Ella.

A game made with love.

Story & Design — Anthony
Art — generated with ChatGPT, rigged in Spine2D
Audio — Doug (sound engine, voice acting generation)
Built in Godot 4
Dialogue — Dialogue Manager by Nathan Hoad

Thank you for playing."

# The line at the very bottom.
@export var closing_text: String = "The End"

# How long the text takes to fade in (seconds).
@export var fade_in_time: float = 3.0


@onready var _box: Control = $Center/Box
@onready var _title: Label = $Center/Box/Title
@onready var _credits: Label = $Center/Box/Credits
@onready var _closing: Label = $Center/Box/Closing


func _ready() -> void:
	# Push the editable text into the labels.
	_title.text = title_text
	_credits.text = credits_text
	_closing.text = closing_text

	# Fade the whole text block up from nothing over the black background.
	_box.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(_box, "modulate:a", 1.0, fade_in_time)


# Quiet quit on Esc (or any "cancel" input) once the player's had their moment.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
