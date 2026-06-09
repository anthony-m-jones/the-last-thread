# =============================================================================
# firefly_hint.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   Controls the BRIGHTNESS of a firefly cluster (a GPUParticles2D swarm). The
#   particles themselves do all the "many small lights drifting and each pulsing"
#   work; this script just decides how lit the whole swarm is right now:
#
#     - ambient: a faint constant shimmer (always visible, magical baseline)
#     - flare:   ONE brief brighten-then-settle "pulse" back to baseline —
#                triggered each time the player JUMPS nearby, and once when the
#                maze stuck-timer elapses. The fireflies never STAY lit: every
#                flare returns to the faint baseline, so a bright cluster always
#                means "you jumped near here just now."
#
#   Same trigger design as before: jump-near = active discovery, timer = humane
#   safety net. Only the VISUAL changed from a flat ColorRect to a particle swarm.
#
# HOW BRIGHTNESS IS APPLIED
#   We tween THIS node's `modulate`. modulate tints all child CanvasItems — so the
#   child GPUParticles2D (and any glow) brightens/dims together. baseline = faint,
#   flare = bright.
#
# REUSE
#   firefly_cluster.tscn bundles this script + the particles + the Reach area.
#   Drop it anywhere (platform rooms for ambient teaching; a door room's correct
#   exit for the hint). Later we'll programmatically point door clusters at the
#   correct exit.
# =============================================================================
extends Node2D


# --- Brightness levels (Color; the ALPHA is what mostly reads as brightness) ---
# Faint always-on shimmer. Keep alpha low so it's a hint of light, not a beacon.
@export var baseline_color: Color = Color(1, 1, 1, 0.25)
# Full brightness at the peak of a flare.
@export var flare_color: Color = Color(1, 1, 1, 1)

# --- Flare timing (seconds) — one "pulse" up and back down ---
@export var flare_rise: float = 0.25   # how fast it brightens
@export var flare_hold: float = 0.6    # how long it stays bright at the peak
@export var flare_fall: float = 1.2    # how slowly it eases back to baseline

@onready var _reach: Area2D = get_node_or_null("Reach")

# Has the maze stuck-timer already fired its one-time flare? (So it only auto-
# flares once, not every frame after the timer elapses.)
var _timer_flared: bool = false
var _player_near: bool = false

# Whether this cluster is active. In a maze DOOR room, the room enables ONLY the
# correct exit's cluster (via set_enabled) and disables the others, so only the
# right door shimmers/flares. Standalone clusters (platform rooms) leave this true
# and are unaffected.
var _enabled: bool = true


func _ready() -> void:
	# Start at the faint ambient shimmer.
	modulate = baseline_color

	if _reach != null:
		_reach.body_entered.connect(_on_body_entered)
		_reach.body_exited.connect(_on_body_exited)

	# Connect to the player's jump on the next idle frame (the player joins the
	# "player" group in its own _ready; child _ready order isn't guaranteed).
	_connect_player_jump.call_deferred()


# Connect to the player's `jumped` signal once everything is in the tree.
func _connect_player_jump() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_signal("jumped") and not p.jumped.is_connected(_on_player_jumped):
			p.jumped.connect(_on_player_jumped)


func _process(_delta: float) -> void:
	if not _enabled:
		return
	# When the cross-room stuck timer elapses, flare ONCE as a humane nudge.
	# (MazeState is the maze autoload; guard so this also works if a cluster is
	# used outside the maze — e.g. pure decoration — without erroring.)
	if not _timer_flared and _maze_hint_ready():
		_timer_flared = true
		flare()


# Enable/disable this cluster. Disabled = fully hidden and ignores all triggers
# (used to turn OFF the wrong doors' fireflies so only the correct one shimmers).
# Called by maze_exit.set_correct().
func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value


# True if the maze stuck-timer says it's time to hint. Isolated so a non-maze
# decorative cluster (no MazeState relevance) simply never auto-reveals.
func _maze_hint_ready() -> bool:
	if not Engine.has_singleton("MazeState") and not _has_maze_state():
		return false
	return MazeState.should_reveal_hint()

func _has_maze_state() -> bool:
	# MazeState is an autoload, reachable as a global; this guards the rare case
	# of the cluster running in a context without it.
	return get_node_or_null("/root/MazeState") != null


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false


# Player jumped: if near (and enabled), do a single flare. Repeatable — jump
# again, flare again — but it always falls back to baseline, never staying lit.
func _on_player_jumped() -> void:
	if _enabled and _player_near:
		flare()


# One firefly "pulse": brighten quickly, hold, then ease all the way back to the
# faint baseline. We KILL any in-progress flare first so a new jump restarts a
# clean single pulse instead of stacking tweens (which could leave it stuck
# bright). End state is always baseline — the fireflies never remain on.
var _flare_tween: Tween
func flare() -> void:
	if _flare_tween != null and _flare_tween.is_valid():
		_flare_tween.kill()
	_flare_tween = create_tween()
	_flare_tween.tween_property(self, "modulate", flare_color, flare_rise)
	_flare_tween.tween_interval(flare_hold)
	_flare_tween.tween_property(self, "modulate", baseline_color, flare_fall)
