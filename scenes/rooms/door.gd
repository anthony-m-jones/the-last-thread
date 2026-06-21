# =============================================================================
# door.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A room exit. It stays LOCKED until its room's puzzle is solved, then OPENS,
#   and when the player walks into an open door it loads the next room scene.
#
#   It's a self-contained reusable scene (door.tscn): drop it into any room,
#   then in the Inspector set "Next Room Path" to the .tscn you want it to lead
#   to. You don't touch code to place a door.
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - It finds its Room (room.gd, the scene root) and watches that room's
#     `puzzle_completed` signal to know when to unlock.
#   - On the player entering an unlocked door, it calls change_scene_to_file().
#
# GODOT CONCEPT — "Area2D" and its body_entered signal
#   An Area2D is an invisible region that DETECTS overlaps but doesn't physically
#   block anything. When a physics body (like the player's CharacterBody2D)
#   enters the area, Area2D emits the built-in `body_entered` signal, handing us
#   the body that entered. That's how the door notices the player arrived. (For
#   this to work the area and the body must share a collision layer/mask; the
#   defaults already match, so it just works.)
# =============================================================================
extends Area2D


# GODOT CONCEPT — "@export_file"
#   This makes the Inspector show a FILE PICKER (filtered to .tscn files) for
#   this value, instead of a plain text box. Pick the next room's scene file and
#   its path string is stored here. Leave it EMPTY and the door will just reload
#   the current scene — handy for testing a single room in isolation.
@export_file("*.tscn") var next_room_path: String = ""

# HOW THE PLAYER USES THE DOOR:
#   false (default) = WALK-THROUGH. Walking into the open door transitions
#                     immediately (the original behaviour — good for most exits).
#   true            = PRESS-TO-ENTER. Walking into the open door shows a
#                     "Press E to enter" prompt; the transition only happens when
#                     the player presses the interact key (E). Good for thresholds
#                     you want to feel deliberate, like stepping into the maze.
@export var require_press: bool = false

# The prompt text shown while standing in a press-to-enter door (only used when
# require_press is true). Editable per door — e.g. "Press E to enter the maze".
@export var prompt_text: String = "Press E to enter"


# GODOT CONCEPT — "@onready"
#   A normal `var x = get_node(...)` would run too early (before child nodes
#   exist) and fail. Putting @onready in front delays the assignment until this
#   node is "ready" (its children exist in the tree). So these two grab our child
#   visual + label safely. The $Name syntax is shorthand for get_node("Name").
@onready var _visual: ColorRect = $Visual
@onready var _label: Label = $Label
# Optional "Press E" prompt label. get_node_or_null so the door still works if the
# scene has no Prompt child; we create one on demand if needed (see _ready).
@onready var _prompt: Label = get_node_or_null("Prompt")


# Our own state: is this door currently open? Filled in _ready from the room's
# starting puzzle state, and flipped to true when the puzzle_completed signal
# fires.
var _is_unlocked: bool = false

# For press-to-enter doors: is the player currently standing in the doorway?
var _player_in_range: bool = false


# GODOT CONCEPT — "_ready()"
#   Godot calls _ready() once, right after this node and its children have
#   entered the scene tree. It's the standard place to look up other nodes and
#   connect signals — the setup that can't happen until the tree exists.
func _ready() -> void:
	var room: Room = _find_room()
	if room == null:
		# push_warning shows an orange message in the editor's Output. It means
		# this door isn't inside a Room-scripted scene, so it can never unlock.
		push_warning("Door is not inside a Room — it will stay locked.")
	else:
		# Start in whatever state the room is already in (lets you pre-tick
		# puzzle_complete in the Inspector and have the door start open).
		_is_unlocked = room.puzzle_complete
		# Subscribe to the room's announcement so we open the moment it's solved.
		# connect() ties the room's signal to our handler function below.
		room.puzzle_completed.connect(_on_room_puzzle_completed)

	# Listen for bodies entering AND leaving this area. We need "exited" too so a
	# press-to-enter prompt disappears when the player walks back out.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# For press-to-enter doors, make sure there's a prompt label to show. If the
	# scene didn't include one, create a simple label so it works out of the box.
	if require_press and _prompt == null:
		_prompt = Label.new()
		_prompt.name = "Prompt"
		add_child(_prompt)
		_prompt.position = Vector2(-40, -90)  # roughly above the doorway
	if _prompt != null:
		_prompt.text = prompt_text
		_prompt.visible = false   # only shown while the player is in range

	_refresh_visual()


# GODOT CONCEPT — "_unhandled_input"
#   Godot calls this for input that nothing else has consumed. For a one-off key
#   press (E to enter) this is cleaner than checking every physics frame. We only
#   act for press-to-enter doors that are open with the player standing in them.
func _unhandled_input(event: InputEvent) -> void:
	if not require_press:
		return
	if not (_is_unlocked and _player_in_range):
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_go_to_next_room()


# -----------------------------------------------------------------------------
# _find_room: walk UP the parent chain until we hit a node that is a Room.
# -----------------------------------------------------------------------------
# We climb parents (self -> parent -> grandparent ...) and return the first one
# that is a Room. This is robust no matter how deeply the door is nested in the
# room's scene tree.
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null


# -----------------------------------------------------------------------------
# Signal handlers
# -----------------------------------------------------------------------------

# Runs when the room emits puzzle_completed. Open up. Also refresh the prompt in
# case the player is already standing in this door at the moment it unlocks.
func _on_room_puzzle_completed() -> void:
	_is_unlocked = true
	_refresh_visual()
	_update_prompt()
	AudioManager.play_one_shot(&"sfx.world.door_unlock")
	print("[Door] Unlocked: ", name)

# Runs when ANY body enters the area. We only care about the player.
func _on_body_entered(body: Node2D) -> void:
	# is_in_group("player") is true only for the player (player.gd adds itself to
	# that group). This avoids reacting to other bodies.
	if not body.is_in_group("player"):
		return
	_player_in_range = true

	if require_press:
		# Press-to-enter: don't transition yet — just show the prompt (if open).
		# The actual transition happens in _unhandled_input when E is pressed.
		_update_prompt()
	elif _is_unlocked:
		# Walk-through (default): transition immediately on contact.
		_go_to_next_room()

# Runs when a body leaves the area — hide the prompt when the player walks out.
func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	_update_prompt()


# Shows the "Press E" prompt only for a press-to-enter door that's open with the
# player standing in it; hides it otherwise.
func _update_prompt() -> void:
	if _prompt == null:
		return
	_prompt.visible = require_press and _is_unlocked and _player_in_range


# -----------------------------------------------------------------------------
# _go_to_next_room: the actual scene change.
# -----------------------------------------------------------------------------
func _go_to_next_room() -> void:
	AudioManager.play_one_shot(&"sfx.world.transition")
	# WHY ABILITIES CARRY OVER: changing scenes destroys this room and the player
	# inside it and builds the next room fresh. But the GameState autoload lives
	# OUTSIDE the current scene, so it is NOT destroyed — every unlocked ability
	# (has_jump / has_wall_jump / has_dash) is still set in the new room. That's
	# the whole reason ability flags live in GameState and not on the player.
	if next_room_path.is_empty():
		# No destination set: just reload this same room (useful while testing).
		SceneTransition.reload_current_scene()
	else:
		# SceneTransition fades to black, swaps the scene, then fades back in.
		# (Abilities still carry over because GameState lives outside the scene.)
		SceneTransition.change_scene_to_file(next_room_path)


# -----------------------------------------------------------------------------
# _refresh_visual: recolor the placeholder so you can SEE locked vs open.
# -----------------------------------------------------------------------------
# Pure gray-box feedback. Replace the ColorRect with a real door sprite later;
# this just tints red (locked) / green (open) and updates the label text.
func _refresh_visual() -> void:
	if _is_unlocked:
		_visual.color = Color(0.25, 0.6, 0.3)   # green = open
		_label.text = "DOOR (open)"
	else:
		_visual.color = Color(0.6, 0.2, 0.2)     # red = locked
		_label.text = "DOOR (locked)"
