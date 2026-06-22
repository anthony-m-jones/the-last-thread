# =============================================================================
# controls_hud.gd  (autoloaded scene "ControlsHud")
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The bottom-left "Controls" legend. Move and Talk are always shown; the Jump,
#   Wall-jump, and Dash rows reveal themselves the moment that ability is
#   unlocked in GameState — so the player's growing move-set is mirrored on screen.
#
# WHY AN AUTOLOAD
#   It lives once, globally, and decides on its own when to be visible: it shows
#   only while a playable scene is active (there's a node in the "player" group)
#   and no cutscene/trivia is running. So it appears in every room and the maze
#   automatically, and hides itself on the title screen, credits, and during
#   conversations — with zero per-room setup.
#
# GODOT CONCEPT — recap
#   GameState (autoload) holds has_jump / has_wall_jump / has_dash. There's no
#   "ability unlocked" signal, so we simply check those flags each frame (cheap)
#   and fade a row in the first time its ability turns on.
# =============================================================================
extends CanvasLayer


@onready var _panel: Control = $Panel
@onready var _jump_row: Control = $Panel/VBox/JumpRow
@onready var _walljump_row: Control = $Panel/VBox/WallJumpRow
@onready var _dash_row: Control = $Panel/VBox/DashRow


func _ready() -> void:
	layer = 10  # above the world/room UI, below the SceneTransition fade (128)
	# Unlockable rows start hidden; Move and Talk (in the scene) are always shown.
	_jump_row.visible = false
	_walljump_row.visible = false
	_dash_row.visible = false
	_panel.visible = false


func _process(_delta: float) -> void:
	# Only show during actual gameplay: a player exists and we're not mid-cutscene.
	var playing: bool = get_tree().get_first_node_in_group("player") != null \
		and not GameState.is_cutscene_active()
	_panel.visible = playing
	if not playing:
		return

	_sync_row(_jump_row, GameState.has_jump)
	_sync_row(_walljump_row, GameState.has_wall_jump)
	_sync_row(_dash_row, GameState.has_dash)


# Show a row (fading it in the first time) when its ability is unlocked; hide it
# again if the ability is somehow cleared (e.g. a fresh playthrough).
func _sync_row(row: Control, unlocked: bool) -> void:
	if unlocked and not row.visible:
		row.visible = true
		row.modulate.a = 0.0
		create_tween().tween_property(row, "modulate:a", 1.0, 0.5)
	elif not unlocked and row.visible:
		row.visible = false
