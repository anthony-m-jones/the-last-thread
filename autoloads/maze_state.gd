# =============================================================================
# maze_state.gd  (registered as the Autoload "MazeState")
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The maze's "global memory". The hedge maze is built from several small rooms
#   that the player moves BETWEEN by walking through exits — each pass is a real
#   scene change, which destroys the old room. So anything that must survive from
#   one maze room to the next (how many correct choices in a row, how long the
#   player has been wandering) lives HERE in an autoload, not on a room.
#
#   This is the same pattern as GameState (ability flags) — an autoload persists
#   across scene changes. See autoloads/game_state.gd for the fuller explanation
#   of what an autoload is.
#
# THE MAZE DESIGN THIS SUPPORTS
#   The maze alternates two kinds of rooms:
#     - DOOR rooms: several exits; only one is "correct" (marked by fireflies).
#         Correct exit  -> streak += 1, go to a platform room (deeper in).
#         Wrong exit     -> streak stays (we DON'T reset — "loop, don't punish");
#                           you just get sent to another maze room, more lost.
#       Get `exits_needed` correct choices in a row to leave the maze.
#     - PLATFORM rooms: a jumping interlude between door rooms, full of fireflies,
#         so the player reliably learns "jumping stirs the fireflies."
#
#   FIREFLY HINT on the correct door reveals itself two ways (see firefly code):
#     - after `hint_delay` seconds of total wandering (tracked HERE, across rooms)
#     - immediately if the player jumps near the correct exit
#
# HOW ROOMS USE THIS
#   - A door room calls choose_correct() / choose_wrong() when the player takes an
#     exit, then loads the next room (semi-random from a list).
#   - Fireflies ask should_reveal_hint() (true once the stuck timer elapses).
#   - is_complete() is true once the streak reaches exits_needed.
# =============================================================================
extends Node


# -----------------------------------------------------------------------------
# TUNABLES
# -----------------------------------------------------------------------------
# How many correct door choices IN A ROW (well — total, since we don't reset) are
# needed to escape the maze. Designer-tuneable.
@export var exits_needed: int = 5

# Seconds of total wandering before the correct exit's fireflies auto-reveal. This
# is the humane "stuck timer" — it counts across rooms (see add_wander_time), so
# it's "you've been lost a while", not "you've been in THIS room a while".
@export var hint_delay: float = 15.0

# Where to go when the maze is finished (the greenhouse). The exit door room reads
# this. Kept here so the whole maze has one place to set its destination.
@export var maze_exit_scene: String = "res://scenes/rooms/room_02.tscn"

# -----------------------------------------------------------------------------
# ROOM POOLS (for random routing)
# -----------------------------------------------------------------------------
# The maze picks the NEXT room at random from these pools. A platform room's exit
# goes to a random DOOR room; a door room's exit goes to a random PLATFORM room.
# Add your room variants here (e.g. maze_door_a/_b/_c, maze_platform_a/_b/_c) and
# the maze will shuffle between them so it feels like a sprawling labyrinth even
# though it's a handful of reused rooms.
@export var door_rooms: PackedStringArray = PackedStringArray([
	"res://scenes/rooms/maze_door_a.tscn",
	"res://scenes/rooms/maze_door_b.tscn",
])
@export var platform_rooms: PackedStringArray = PackedStringArray([
	"res://scenes/rooms/maze_platform_a.tscn",
])


# Returns a random door-room scene path (or "" if the pool is empty).
func random_door_room() -> String:
	if door_rooms.is_empty():
		return ""
	return door_rooms[randi() % door_rooms.size()]

# Returns a random platform-room scene path (or "" if the pool is empty).
func random_platform_room() -> String:
	if platform_rooms.is_empty():
		return ""
	return platform_rooms[randi() % platform_rooms.size()]


# -----------------------------------------------------------------------------
# RUNTIME STATE (persists across maze rooms)
# -----------------------------------------------------------------------------
# How many correct choices the player has made so far.
var streak: int = 0

# Total seconds spent wandering the maze (summed across rooms). Compared against
# hint_delay to decide when the firefly hint auto-reveals.
var wander_time: float = 0.0

# Whether the player has begun the maze (so entering the first room resets state).
var _started: bool = false

# Which spawn point the NEXT maze room should drop the player at. An exit sets
# this just before the scene change; the next room reads it in _ready. This is how
# "you come out somewhere unexpected" works across the reused rooms.
var pending_spawn_index: int = 0


# Call once when the player ENTERS the maze (from the garden), to reset state for
# a fresh attempt. Safe to call from each maze room's _ready via ensure_started().
func start_maze() -> void:
	streak = 0
	wander_time = 0.0
	_started = true

# Idempotent: a maze room calls this in _ready; it only resets the FIRST time, so
# moving between maze rooms doesn't wipe progress.
func ensure_started() -> void:
	if not _started:
		start_maze()

# Reset the "started" flag when leaving the maze entirely, so a future re-entry
# starts clean. Called by the exit logic.
func leave_maze() -> void:
	_started = false


# -----------------------------------------------------------------------------
# WANDER TIMER (drives the stuck-hint)
# -----------------------------------------------------------------------------
# A maze room calls this every frame with its delta so wandering time accrues
# across rooms. We keep the accumulation here rather than in any one room.
func add_wander_time(delta: float) -> void:
	wander_time += delta

# True once the player has wandered long enough that the correct exit should glow
# on its own (the humane safety net).
func should_reveal_hint() -> bool:
	return wander_time >= hint_delay


# -----------------------------------------------------------------------------
# CHOICES
# -----------------------------------------------------------------------------
# Player took the CORRECT exit: progress one step deeper. We also reset the
# wander timer a little so the next room's hint takes the full delay again
# (each room gets its own grace before auto-revealing).
func choose_correct() -> void:
	streak += 1
	wander_time = 0.0
	print("[MazeState] Correct choice. Streak ", streak, "/", exits_needed)

# Player took a WRONG exit: by design we do NOT reset the streak (that punished
# invisibly). They simply get sent onward, more lost. We keep the wander timer
# running so a repeatedly-lost player still gets the hint.
func choose_wrong() -> void:
	print("[MazeState] Wrong choice. Streak stays ", streak, "/", exits_needed)

# Has the player made enough correct choices to escape?
func is_complete() -> bool:
	return streak >= exits_needed
