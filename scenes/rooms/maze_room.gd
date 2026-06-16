# =============================================================================
# maze_room.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The root script for every maze room (both DOOR rooms and PLATFORM rooms). It
#   does the shared maze housekeeping, and now the RANDOMIZATION that makes the
#   reused rooms feel like a sprawling, disorienting labyrinth:
#
#     1. Ticks the cross-room "wander timer" (MazeState) for the stuck-hint.
#     2. On entry, drops the player at a RANDOM spawn point in this room — so even
#        re-entering the same room puts you somewhere unexpected.
#     3. If this is a DOOR room, randomly picks WHICH exit is "correct" each time
#        the room loads (so the way onward changes every visit) and reveals the
#        firefly hint on that exit.
#     4. Provides go_to_room(scene) used by exits to load the next room.
#
# DOOR vs PLATFORM is set by `room_kind` in the Inspector.
#   - PLATFORM rooms: a single exit that just leads onward (to a random door room).
#   - DOOR rooms: several exits; one randomly-chosen correct one leads onward (to a
#     random platform room) and counts as a correct choice; the rest are "wrong".
# =============================================================================
class_name MazeRoom
extends Node2D


enum RoomKind { PLATFORM, DOOR }

# What kind of maze room this is (set per room scene in the Inspector).
@export var room_kind: RoomKind = RoomKind.PLATFORM

# Where the player node lives in this room (so we can reposition it on spawn).
@export var player_path: NodePath = ^"Player"

# Spawn points; the player is dropped at a RANDOM one of these on load. Leave
# empty to just use the player's placed position.
@export var spawn_points: Array[NodePath] = []

# DOOR rooms only: the exits to choose between. One is randomly made "correct"
# each load. Order doesn't matter. (Ignored for PLATFORM rooms.)
@export var exits: Array[NodePath] = []


func _ready() -> void:
	AudioManager.play_ambience(&"amb.maze.loop")
	AudioManager.play_music(&"music.maze.loop")
	# Make sure maze state is initialised (resets only on first maze room).
	MazeState.ensure_started()
	_place_player_at_random_spawn()
	if room_kind == RoomKind.DOOR:
		_assign_random_correct_exit()


func _process(delta: float) -> void:
	# Accrue wander time across the whole maze (drives the firefly stuck-hint).
	MazeState.add_wander_time(delta)


# Drop the player at a RANDOM spawn point (your request: random spawn each entry).
func _place_player_at_random_spawn() -> void:
	if spawn_points.is_empty():
		return
	var player: Node2D = get_node_or_null(player_path)
	if player == null:
		return
	var index: int = randi() % spawn_points.size()
	var marker: Node2D = get_node_or_null(spawn_points[index])
	if marker != null:
		player.global_position = marker.global_position


# DOOR rooms: randomly choose which exit is correct this load, and tell each exit.
# We also flare/point the firefly hint at the correct one (the exit handles its
# own hint child; here we just set the is_correct flag the exit reads).
func _assign_random_correct_exit() -> void:
	if exits.is_empty():
		return
	var correct_index: int = randi() % exits.size()
	for i in exits.size():
		var exit_node: Node = get_node_or_null(exits[i])
		if exit_node != null:
			# set_correct() lets the exit update itself (flag + its firefly hint).
			if exit_node.has_method("set_correct"):
				exit_node.set_correct(i == correct_index)


# Called by a MazeExit to travel to the next maze room. change_scene_to_file must
# be DEFERRED (an exit triggers this from inside a physics callback; Godot forbids
# freeing collision nodes mid-physics).
func go_to_room(scene_path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene_path)
