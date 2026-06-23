# =============================================================================
# pip.gd  —  Pip the kitten NPC.
# -----------------------------------------------------------------------------
# Extends npc.gd with two bouncing behaviours:
#
#   1. IDLE BOUNCE — Pip hops every few seconds while the player is far away.
#      The moment the player comes within face_distance the idle bouncing stops
#      so Pip can hold still and make eye contact.
#
#   2. BOING — When the dialogue line tagged [#boing] fires, Pip does one tall
#      jump. This hooks into DialogueManager.got_dialogue the same way
#      cutscene_highlight.gd does, so the jump fires exactly when that line
#      appears in the balloon.
#
# GODOT CONCEPT — "extends" with a path
#   Normally you extend a class_name (e.g. `extends Node2D`). When a script
#   doesn't declare a class_name you can still extend it by path. Here we
#   inherit ALL of npc.gd's exports, @onready vars, and functions, then add
#   Pip-specific behaviour on top. `super._ready()` and `super._process()` call
#   the parent version so we don't accidentally drop the face-player logic.
# =============================================================================
extends "res://scenes/interactables/npc.gd"


# How many pixels up the sprite travels during a background idle hop.
@export var bounce_height: float = 8.0

# How many pixels up the sprite travels on the scripted boing.
@export var boing_height: float = 16.0

# Total time (seconds) for one bounce arc (up + back down).
@export var bounce_duration: float = 0.25

# Seconds between idle bounces.
@export var bounce_interval: float = 2.5


# Y-position of the sprite at rest — captured in _ready, used as the baseline
# so every bounce returns to exactly the right ground level.
var _rest_y: float = 0.0

# The active tween driving the current bounce (if any).
var _bounce_tween: Tween = null

# Countdown to the next idle hop. Pre-loaded to a short delay so Pip hops
# naturally soon after the room appears rather than waiting the full interval.
var _bounce_timer: float = 1.0

# True while a conversation is running — suppresses the idle bounce so Pip
# stays still and focused while talking.
var _in_dialogue: bool = false


func _ready() -> void:
	super._ready()
	# Capture the sprite's ground-level Y so tweens always return to it.
	if _sprite != null:
		_rest_y = _sprite.position.y

	# Same pattern as cutscene_highlight.gd: watch every shown line for our tag.
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _process(delta: float) -> void:
	super._process(delta)   # keeps the face-player logic from npc.gd working

	if _sprite == null:
		return

	# Is the player close enough that Pip should stop fidgeting?
	var player: Node2D = _find_player()
	var player_close: bool = false
	if player != null:
		player_close = global_position.distance_to(player.global_position) < face_distance

	# Idle bounce — only when the player is far away and no dialogue is active.
	if not player_close and not _in_dialogue:
		_bounce_timer -= delta
		if _bounce_timer <= 0.0:
			_bounce_timer = bounce_interval
			_idle_bounce()


# ---------------------------------------------------------------------------
# Bounce helpers
# ---------------------------------------------------------------------------

# A gentle background hop. Skipped if one is already in flight so they don't
# stack into a continuous float.
func _idle_bounce() -> void:
	if _bounce_tween != null and _bounce_tween.is_running():
		return
	_start_bounce(bounce_height)


# A tall emphatic jump — always fires, interrupting any bounce already running.
func _do_boing() -> void:
	if _bounce_tween != null:
		_bounce_tween.kill()
	# Reset to rest first so the boing always starts from the ground.
	_sprite.position.y = _rest_y
	_start_bounce(boing_height)


# Shared tween: quick rise (ease-out), slower fall (ease-in) for a springy feel.
func _start_bounce(height: float) -> void:
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(_sprite, "position:y", _rest_y - height, bounce_duration * 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(_sprite, "position:y", _rest_y, bounce_duration * 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# ---------------------------------------------------------------------------
# Dialogue hooks (same pattern as cutscene_highlight.gd)
# ---------------------------------------------------------------------------

func _on_got_dialogue(line) -> void:
	_in_dialogue = true
	# Fire the boing jump when the [#boing]-tagged line appears.
	if "boing" in line.tags:
		_do_boing()


func _on_dialogue_ended(_resource) -> void:
	_in_dialogue = false
