# =============================================================================
# maze_exit.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   One exit opening in a maze room. The player walks into it (Area2D) to take it.
#   In a DOOR room you place several of these; exactly one is marked `is_correct`.
#   In a PLATFORM room you place a single one (is_correct = true) that just leads
#   onward.
#
# WHAT HAPPENS WHEN TAKEN (only DOOR-room exits score; platform exits just route)
#   - Correct exit (door room): MazeState.choose_correct() (+1 streak). If that
#     completes the maze, we leave to the greenhouse; otherwise we route onward.
#   - Wrong exit (door room): MazeState.choose_wrong() (streak UNCHANGED — "loop,
#     don't punish"), then route onward, just deeper/lost.
#   - Platform-room exit: routes onward, no scoring (it's a corridor).
#
# ROUTING: unless next_scene forces a target, we go to a RANDOM room of the
# OPPOSITE kind via MazeState (door room -> random platform; platform -> random
# door). Each room then randomizes its OWN spawn point and (door rooms) its own
# correct exit on load — so the maze feels different every pass. See maze_room.gd.
#
# WHY no reset on wrong (design): an invisible streak-reset reads as a bug. A
# wrong turn costs time/disorientation but never erases progress — the firefly
# hint (timer or jump) teaches the way.
# =============================================================================
extends Area2D


# Is this the correct way onward? For DOOR rooms this is assigned RANDOMLY each
# load by the room (maze_room.gd._assign_random_correct_exit via set_correct()),
# so you don't set it by hand. For a PLATFORM room's single exit, leave it true
# (a platform exit is always "the way onward").
@export var is_correct: bool = false

# OPTIONAL: a specific scene to load. Usually leave EMPTY — the exit then routes
# to a RANDOM room of the opposite kind via MazeState (a door room's exit → a
# random platform room; a platform room's exit → a random door room). Only set
# this to force a fixed destination for a special one-off exit.
@export_file("*.tscn") var next_scene: String = ""

# OPTIONAL firefly hint to flare when this exit is the correct one (drag the
# exit's FireflyCluster child here, or leave empty). Lets the room point the hint
# at whichever exit was randomly chosen correct.
@export var firefly_hint_path: NodePath = ^""

# If true, the player must press E to take this exit (a prompt shows in range).
# If false, walking into it takes it immediately. Door-room exits often feel
# better as press-to-enter so a wrong one isn't taken by accident while exploring.
@export var require_press: bool = false
@export var prompt_text: String = "Press E"


@onready var _prompt: Label = get_node_or_null("Prompt")

var _player_in_range: bool = false
var _taken: bool = false   # guard so an exit can't fire twice mid-transition
# An exit must "arm" before it can fire. This prevents the exit the player SPAWNS
# on top of from triggering instantly on room load (which would auto-advance the
# maze). It arms shortly after load; an exit the player is already standing in at
# spawn won't fire until they step out and back in (see _player_in_range logic).
var _armed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if require_press and _prompt == null:
		_prompt = Label.new()
		_prompt.name = "Prompt"
		add_child(_prompt)
		_prompt.position = Vector2(-30, -80)
	if _prompt != null:
		_prompt.text = prompt_text
		_prompt.visible = false
	# Arm after a short delay so spawning inside this exit doesn't trigger it.
	_arm_after_delay()


# Arm the exit a moment after the room loads. We also require the player to NOT
# already be overlapping when arming — if they spawned inside us, we wait until
# they leave (handled in _on_body_exited) so we never fire on the spawn overlap.
func _arm_after_delay() -> void:
	await get_tree().create_timer(0.25).timeout
	# Only arm now if the player isn't already standing in us. If they are, arming
	# is deferred to when they exit (so re-entering is a deliberate choice).
	if not _player_in_range:
		_armed = true


func _unhandled_input(event: InputEvent) -> void:
	if not require_press or not _player_in_range or _taken or not _armed:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_take()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	# Don't react at all until armed (prevents firing on the spawn overlap).
	if not _armed:
		return
	if require_press:
		if _prompt != null:
			_prompt.visible = true
	else:
		_take()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	if _prompt != null:
		_prompt.visible = false
	# If the player spawned inside us (so we never armed), arm now that they've
	# stepped out — re-entering is then a deliberate choice that triggers us.
	_armed = true


# Called by the room (maze_room.gd) to set whether THIS exit is the correct one
# this load. Enables this exit's firefly cluster ONLY when correct (so wrong
# doors' fireflies are fully off) — that way only the right door shimmers/flares.
func set_correct(value: bool) -> void:
	is_correct = value
	var hint: Node = get_node_or_null(firefly_hint_path)
	if hint != null and hint.has_method("set_enabled"):
		hint.set_enabled(value)


# Take this exit: record the choice, then route onward to a RANDOM room of the
# opposite kind (door <-> platform), unless next_scene forces a fixed target.
func _take() -> void:
	if _taken:
		return
	_taken = true

	var room: MazeRoom = _find_maze_room()

	# Only DOOR rooms count as a "choice" toward the streak. A platform room's
	# single exit is just a corridor onward — it routes but doesn't score.
	var in_door_room: bool = room != null and room.room_kind == MazeRoom.RoomKind.DOOR
	if in_door_room:
		if is_correct:
			MazeState.choose_correct()
			if MazeState.is_complete():
				_leave_maze()
				return
		else:
			MazeState.choose_wrong()

	# Decide the destination. If next_scene is set, use it (forced). Otherwise pick
	# a RANDOM room of the OPPOSITE kind: door room -> platform room, platform room
	# -> door room. That alternation is what makes the maze flow door/platform/...
	var target: String = next_scene
	if target.is_empty() and room != null:
		if room.room_kind == MazeRoom.RoomKind.DOOR:
			target = MazeState.random_platform_room()
		else:
			target = MazeState.random_door_room()

	if room != null and not target.is_empty():
		room.go_to_room(target)
	elif not target.is_empty():
		SceneTransition.change_scene_to_file(target)


# Maze finished — clear maze state and head to the greenhouse.
func _leave_maze() -> void:
	var target: String = MazeState.maze_exit_scene
	MazeState.leave_maze()
	SceneTransition.change_scene_to_file(target)


# Walk up to find the MazeRoom root (so we can use its go_to_room helper).
func _find_maze_room() -> MazeRoom:
	var node: Node = self
	while node != null:
		if node is MazeRoom:
			return node
		node = node.get_parent()
	return null
