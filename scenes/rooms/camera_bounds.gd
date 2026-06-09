# =============================================================================
# camera_bounds.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   A drop-in "room edges" node. It tells the player's camera how far it's allowed
#   to scroll, so the view STOPS at the edges of the room instead of following the
#   cat into empty space past a wall or below the floor — the classic metroidvania
#   "this is the edge of the room" feel.
#
#   You place ONE CameraBounds in a room, type in (or drag — see below) where each
#   edge is, and tick which edges are active. It draws the limits live in the
#   editor so you can SEE them, and applies them to the camera automatically when
#   the game runs. No code or player-scene editing needed.
#
# HOW IT WORKS (the short version)
#   Godot's Camera2D has built-in limit_left/right/top/bottom properties. Once set,
#   the engine enforces them every frame — the camera simply can't show past them.
#   All this node does is (1) let you configure those four numbers nicely per room
#   and (2) copy them onto whatever camera is active when the room loads.
#
# GODOT CONCEPT — "@tool"
#   Normally a script only runs when the GAME runs. @tool makes it ALSO run inside
#   the editor. We use that purely to DRAW the limit lines on screen while you edit
#   the room, so you can position them by eye. The drawing does nothing in-game.
#
# GODOT CONCEPT — "class_name"
#   `class_name CameraBounds` registers this as a known type (like Room/Door did),
#   so it's easy to find and so the editor lists it.
# =============================================================================
@tool
class_name CameraBounds
extends Node2D


# Godot's Camera2D uses these huge numbers to mean "no limit this direction".
# When you DISABLE an edge below, we write these back so the camera is free again.
const _NO_LIMIT: int = 10000000


# =============================================================================
# CONFIGURATION  (@export — all editable in the Inspector)
# -----------------------------------------------------------------------------
# Each edge has a TOGGLE (use_*) and a POSITION (*_limit), in WORLD pixels.
#   - Toggle ON  + position  => the camera view stops at that world coordinate.
#   - Toggle OFF             => the camera can scroll freely that direction.
# Remember Y increases DOWNWARD: a SMALLER top value is higher up, a LARGER bottom
# value is lower down.
#
# The @export_group lines just tidy these into a section in the Inspector. Each
# setter calls queue_redraw() so the on-screen lines update the instant you change
# a value while editing.
# =============================================================================

@export_group("Left edge")
@export var use_left: bool = true:
	set(v): use_left = v; queue_redraw()
@export var left_limit: float = 0.0:
	set(v): left_limit = v; queue_redraw()

@export_group("Right edge")
@export var use_right: bool = true:
	set(v): use_right = v; queue_redraw()
@export var right_limit: float = 1400.0:
	set(v): right_limit = v; queue_redraw()

@export_group("Top edge")
# Top often stays OFF in a wide ground-level room (let the camera rise freely);
# turn it on for vertical rooms like the greenhouse.
@export var use_top: bool = false:
	set(v): use_top = v; queue_redraw()
@export var top_limit: float = -400.0:
	set(v): top_limit = v; queue_redraw()

@export_group("Bottom edge")
@export var use_bottom: bool = true:
	set(v): use_bottom = v; queue_redraw()
@export var bottom_limit: float = 660.0:
	set(v): bottom_limit = v; queue_redraw()

@export_group("Feel")
# When true, the camera EASES to a stop at a limit instead of clamping hard. Looks
# nicer with position smoothing; turn off for an instant hard stop.
@export var smooth_stop: bool = true

@export_group("Editor preview")
# Purely cosmetic: how far the drawn guide lines extend for edges that are turned
# OFF (those have no real position, so we just draw a faint reference line this far
# out). Doesn't affect the game at all.
@export var preview_extent: float = 2000.0


# =============================================================================
# RUNTIME — apply the limits to the camera when the game starts.
# =============================================================================
func _ready() -> void:
	# Inside the editor we only want to DRAW, never to touch a camera. Bail early.
	if Engine.is_editor_hint():
		return
	# Apply on the next idle frame: by then the room (and the player's camera) is
	# fully in the tree and the camera is "current", so we can find it reliably.
	call_deferred("apply_to_camera")


# Public so you could also call it again later (e.g. after moving walls at
# runtime). Finds the active 2D camera and copies our limits onto it.
func apply_to_camera() -> void:
	var camera: Camera2D = _find_camera()
	if camera == null:
		push_warning("CameraBounds: no Camera2D found to apply limits to.")
		return

	# For each edge: write our value if enabled, or the "free" sentinel if not.
	camera.limit_left = int(left_limit) if use_left else -_NO_LIMIT
	camera.limit_right = int(right_limit) if use_right else _NO_LIMIT
	camera.limit_top = int(top_limit) if use_top else -_NO_LIMIT
	camera.limit_bottom = int(bottom_limit) if use_bottom else _NO_LIMIT
	camera.limit_smoothed = smooth_stop


# Finds the camera to limit. Primary: the viewport's ACTIVE Camera2D (whatever is
# currently rendering — robust no matter where the camera lives). Fallback: search
# under the node tagged "player" for a Camera2D, in case the active one isn't set
# yet.
func _find_camera() -> Camera2D:
	var active: Camera2D = get_viewport().get_camera_2d()
	if active != null:
		return active
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		var cam: Camera2D = _first_camera_in(p)
		if cam != null:
			return cam
	return null


# Helper: depth-first search a node's descendants for the first Camera2D.
func _first_camera_in(node: Node) -> Camera2D:
	if node is Camera2D:
		return node
	for child in node.get_children():
		var found: Camera2D = _first_camera_in(child)
		if found != null:
			return found
	return null


# =============================================================================
# EDITOR DRAWING — show the limits as lines while you edit the room.
# -----------------------------------------------------------------------------
# _draw() is a built-in callback where you paint with draw_* calls. Coordinates
# here are LOCAL to this node, so keep this node at position (0,0) in the room and
# the numbers above read as plain world coordinates. We draw a bright solid line
# for each ACTIVE edge and a faint dashed line for each disabled edge, plus a soft
# fill of the enclosed "camera can roam here" box.
# =============================================================================
func _draw() -> void:
	if not Engine.is_editor_hint():
		return  # don't draw during the actual game

	var active_color := Color(0.3, 0.9, 1.0, 0.9)   # cyan = active limit
	var off_color := Color(1.0, 1.0, 1.0, 0.15)      # faint = disabled edge

	# Work out the rectangle to outline. For disabled edges we substitute a far-out
	# value just so the lines have somewhere to go on screen.
	var l := left_limit if use_left else -preview_extent
	var r := right_limit if use_right else preview_extent
	var t := top_limit if use_top else -preview_extent
	var b := bottom_limit if use_bottom else preview_extent

	# Soft fill of the roam area.
	draw_rect(Rect2(Vector2(l, t), Vector2(r - l, b - t)), Color(0.3, 0.9, 1.0, 0.05), true)

	# Each edge: bright if active, faint dashed if off.
	_draw_edge(Vector2(l, t), Vector2(l, b), use_left, active_color, off_color)   # left
	_draw_edge(Vector2(r, t), Vector2(r, b), use_right, active_color, off_color)  # right
	_draw_edge(Vector2(l, t), Vector2(r, t), use_top, active_color, off_color)    # top
	_draw_edge(Vector2(l, b), Vector2(r, b), use_bottom, active_color, off_color) # bottom


# Draws one edge line: solid bright when enabled, faint dashed when disabled.
func _draw_edge(from: Vector2, to: Vector2, enabled: bool, on_col: Color, off_col: Color) -> void:
	if enabled:
		draw_line(from, to, on_col, 3.0)
	else:
		draw_dashed_line(from, to, off_col, 1.0, 16.0)
