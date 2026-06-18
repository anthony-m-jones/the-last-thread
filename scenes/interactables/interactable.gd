# =============================================================================
# interactable.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   ONE reusable scene that covers every "the player walks up and something
#   happens" thing in the game:
#       - ability-cats   (talk to them -> get an ability when the talk ends)
#       - story triggers  (walk into a zone -> a cutscene conversation plays)
#       - the trivia trigger (walk up, press interact -> the trivia opens)
#   You drop ONE interactable.tscn into a room and configure it entirely in the
#   Inspector — which conversation to play, and optionally which ability to grant
#   when that conversation finishes. No code editing per-cat.
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - It plays a conversation through the DialogueManager autoload (the Dialogue
#     Manager addon). Conversations live in .dialogue FILES (Step 6); this script
#     only triggers one by file + title and reacts when it ENDS.
#   - When the conversation ends, if an ability is selected, it flips the matching
#     flag on the GameState autoload (GameState.unlock_jump(), etc.). The player
#     reads those flags, so the new move turns on immediately.
#
# GODOT CONCEPT — "Area2D" (recap from door.gd)
#   An invisible region that detects bodies entering/leaving via the built-in
#   body_entered / body_exited signals. We use it to know when the cat is "in
#   reach" of the player.
# =============================================================================
extends Area2D


# GODOT CONCEPT — "enum"
#   An enum is a named list of choices. Declaring it makes the Inspector show a
#   nice DROPDOWN instead of asking you to remember magic numbers. Here it lists
#   which ability (if any) this interactable grants when its talk ends.
enum Ability {
	NONE,        # a plain story/cutscene trigger — grants nothing
	JUMP,        # the Room 1 cat
	WALL_JUMP,   # the Room 2 cat
	DASH,        # the Room 3 cat
}


# --- WHAT TO PLAY ----------------------------------------------------------
# GODOT CONCEPT — typed @export for a Resource
#   Typing this as `DialogueResource` makes the Inspector show a slot that only
#   accepts a compiled .dialogue file. Drag your .dialogue file here. (Those
#   files arrive in Step 6; leave this empty for now and see the note in
#   _start_conversation about the placeholder fallback.)
@export var dialogue_file: DialogueResource

# Which titled conversation inside that file to start (a .dialogue file can hold
# several, each marked with a "~ title" line). Empty = start from the top.
@export var dialogue_title: String = ""


# --- WHAT IT DOES WHEN THE TALK ENDS ---------------------------------------
# Pick the ability to unlock from the dropdown. Leave at NONE for story triggers.
@export var ability_to_unlock: Ability = Ability.NONE

# OPTIONAL: a trivia (or any UI) scene to OPEN when the conversation ends. This
# is how the SAME reusable interactable also works as the Room 3 "trivia
# trigger": set its dialogue to the spider's lead-in, leave ability at NONE, and
# drop trivia.tscn into this slot. When the talk ends we instance the scene and
# add it under the room so it draws over everything and can find the Room to mark
# the puzzle complete. Leave empty for normal cats / story zones.
@export var scene_to_open: PackedScene


# --- HOW IT'S TRIGGERED ----------------------------------------------------
# If true, the player must be in range AND press the "interact" key (E) — right
# for cats and the trivia pillar. If false, it fires automatically the moment
# the player walks in — right for room-entry cutscene zones.
@export var requires_button_press: bool = true

# If true, this interactable only ever works ONCE, then disables itself. Good for
# ability grants and one-shot cutscenes so they don't repeat. If false it can be
# used again and again.
@export var one_shot: bool = true


# --- OPTIONAL ON-SCREEN PROMPT --------------------------------------------
# A child Label we show ("Press E") while the player is in range. Optional: if
# the scene has no "Prompt" child this just stays null and is ignored.
@onready var _prompt: Label = get_node_or_null("Prompt")


# Internal state.
var _player_in_range: bool = false   # is the player currently overlapping us?
var _is_busy: bool = false           # true while a conversation is playing
var _has_fired: bool = false         # true once we've been used (for one_shot)


func _ready() -> void:
	# Subscribe to the built-in Area2D overlap signals.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_hide_prompt()


# GODOT CONCEPT — "_unhandled_input" vs polling
#   For a one-off key press like "interact", reacting to the input EVENT is
#   cleaner than checking every physics frame. Godot calls _unhandled_input()
#   when an input hasn't already been consumed by the UI. We only act on the
#   "interact" action, and only when it makes sense to.
func _unhandled_input(event: InputEvent) -> void:
	if not requires_button_press:
		return
	if not _can_trigger():
		return
	# event.is_action_pressed("interact") is true on the frame E goes down.
	if event.is_action_pressed("interact"):
		_start_conversation()
		# Mark the event handled so nothing else also reacts to this press.
		get_viewport().set_input_as_handled()


# -----------------------------------------------------------------------------
# Overlap handlers
# -----------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true

	if requires_button_press:
		# Show the "Press E" hint (if we have one) when in reach.
		if _can_trigger():
			_show_prompt()
	else:
		# Auto-trigger zone: fire as soon as the player steps in.
		if _can_trigger():
			_start_conversation()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	_hide_prompt()


# -----------------------------------------------------------------------------
# _can_trigger: a single place that answers "are we allowed to fire right now?"
# -----------------------------------------------------------------------------
func _can_trigger() -> bool:
	if _is_busy:
		return false                       # a conversation is already running
	if one_shot and _has_fired:
		return false                       # already used and we only fire once
	if requires_button_press and not _player_in_range:
		return false                       # E pressed but player isn't here
	return true


# -----------------------------------------------------------------------------
# _start_conversation: play the dialogue, then react when it ENDS.
# -----------------------------------------------------------------------------
# GODOT CONCEPT — "await"
#   `await SomeObject.some_signal` PAUSES this function right here and resumes it
#   the moment that signal fires — without freezing the game. We use it to wait
#   for DialogueManager's `dialogue_ended` signal, so the line right after the
#   await runs exactly when the conversation closes. That's how "grant the
#   ability when the talk ends" is expressed so simply.
func _start_conversation() -> void:
	_is_busy = true
	_hide_prompt()

	if dialogue_file != null:
		# Real path (works once Step 6's .dialogue files are assigned): open the
		# balloon and wait for the conversation to finish.
		DialogueManager.show_dialogue_balloon(dialogue_file, dialogue_title)
		await DialogueManager.dialogue_ended
	else:
		# PLACEHOLDER path (Step 5, before any .dialogue files exist). We have no
		# conversation to show yet, so we just log and continue. This lets you
		# test that interactables grant abilities NOW; in Step 6 you'll assign a
		# real dialogue_file and this branch won't run.
		print("[Interactable] (placeholder) No dialogue_file set on '", name,
			"'. Pretending the conversation just ended.")

	_on_conversation_finished()


# -----------------------------------------------------------------------------
# _on_conversation_finished: the payoff — grant the ability (if any).
# -----------------------------------------------------------------------------
func _on_conversation_finished() -> void:
	_is_busy = false
	_has_fired = true

	_grant_selected_ability()
	if ability_to_unlock != Ability.NONE:
		AudioManager.play_one_shot(&"sfx.world.unlock")
	elif scene_to_open != null:
		AudioManager.play_one_shot(&"sfx.world.transition")
	_open_scene_if_any()

	# For one-shot interactables, stop listening so it can never fire again.
	if one_shot:
		_disable_permanently()
	elif _player_in_range and requires_button_press:
		# Re-usable and player still here: show the prompt again.
		_show_prompt()


# Flips the right GameState flag based on the dropdown. Each branch calls the
# matching helper on the GameState autoload (which prints + sets the flag).
func _grant_selected_ability() -> void:
	match ability_to_unlock:
		Ability.JUMP:
			GameState.unlock_jump()
		Ability.WALL_JUMP:
			GameState.unlock_wall_jump()
		Ability.DASH:
			GameState.unlock_dash()
		Ability.NONE:
			pass   # story/cutscene trigger — nothing to grant


# If a scene_to_open was assigned (e.g. the trivia), instance it and add it to
# the room so it appears. We add it to the Room root (found by walking up the
# parents) when possible, so the opened scene's own _find_room() can reach the
# Room and mark the puzzle complete; otherwise we fall back to our own parent.
func _open_scene_if_any() -> void:
	if scene_to_open == null:
		return
	var opened: Node = scene_to_open.instantiate()
	var room: Node = _find_room()
	if room != null:
		room.add_child(opened)
	else:
		get_parent().add_child(opened)


# Walk up the parent chain to find the Room this interactable sits in (same
# helper pattern as door.gd / goal_zone.gd / trivia.gd).
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null


# Turns this interactable off for good (used by one_shot). We stop detecting
# overlaps so it becomes inert scenery.
func _disable_permanently() -> void:
	_hide_prompt()
	# monitoring=false stops the Area2D from detecting bodies at all.
	set_deferred("monitoring", false)


# -----------------------------------------------------------------------------
# Tiny prompt helpers (safe no-ops if there is no Prompt child).
# -----------------------------------------------------------------------------
func _show_prompt() -> void:
	if _prompt != null:
		_prompt.visible = true

func _hide_prompt() -> void:
	if _prompt != null:
		_prompt.visible = false
