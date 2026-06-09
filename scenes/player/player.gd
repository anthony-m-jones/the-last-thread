# =============================================================================
# player.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The cat's movement brain. ONE script runs the whole character across ALL
#   three rooms. Each ability is gated behind a flag in the GameState autoload,
#   so the same controller simply gains moves as the game unlocks them:
#       Step 2:  run + jump            (gated by GameState.has_jump)
#       Step 3:  wall-jump + dash      (gated by GameState.has_wall_jump / has_dash)
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - It READS flags from the GameState autoload (GameState.has_jump, etc.) to
#     decide which moves are allowed. See autoloads/game_state.gd. The ability
#     cats flip those flags to true when their dialogue ends (Step 5/6).
#   - It reads the keyboard through named Input Map "actions" (move_left,
#     move_right, jump, dash) defined in Project Settings, never raw key codes.
#
# GODOT CONCEPT — "extends CharacterBody2D"
#   Every script extends some node type, which decides what built-in powers it
#   has. CharacterBody2D is Godot's purpose-built node for a player-controlled
#   2D body: it has a `velocity` property and a `move_and_slide()` function that
#   moves the body by that velocity while sliding nicely along floors/walls and
#   stopping on collisions. We don't do raw position math; we set a velocity and
#   let move_and_slide() do the moving. It also gives us is_on_floor(),
#   is_on_wall(), is_on_wall_only() and get_wall_normal(), which the wall-jump
#   code below relies on.
# =============================================================================
extends CharacterBody2D


# Emitted the instant the cat performs any jump (ground or wall). The maze's
# fireflies listen for this to "scatter and flare" when the player jumps near
# them. A signal keeps the player decoupled — it doesn't know fireflies exist.
signal jumped


# =============================================================================
# TUNABLE VALUES  (@export)
# -----------------------------------------------------------------------------
# GODOT CONCEPT — "@export"
#   Putting @export in front of a variable makes it show up in the Inspector
#   panel when you click the Player node in the editor. That means YOU can drag
#   sliders / type new numbers to change how the movement FEELS without editing
#   this script. Tuning feel is the whole point — play, tweak, repeat.
#
#   Units: positions are in PIXELS, time is in SECONDS. So a speed is
#   pixels-per-second and gravity is pixels-per-second-per-second.
#
#   The @export_group lines below are purely cosmetic: they sort these values
#   into collapsible sections in the Inspector so it's easier to find things.
# =============================================================================

@export_group("Horizontal movement")
# How fast the cat runs left/right, in pixels per second. Higher = faster.
@export var run_speed: float = 220.0
# How quickly the cat speeds up to run_speed when you press a direction.
# Bigger number = snappier starts. (Pixels per second, per second.)
@export var ground_acceleration: float = 2000.0
# How quickly the cat slows to a stop when you let go. Bigger = stops sooner.
@export var ground_friction: float = 2400.0
# In the air we usually want LESS control than on the ground, so the jump arc
# feels committed. This is the acceleration used while airborne.
@export var air_acceleration: float = 1200.0

@export_group("Gravity & jumping")
# Downward pull, in pixels per second per second. Bigger = the cat falls faster
# and the jump feels heavier/snappier. Smaller = floatier.
@export var gravity: float = 2000.0
# The upward "kick" applied the instant you jump. It is NEGATIVE because in 2D,
# Y increases DOWNWARD (up the screen is negative Y). Bigger negative = higher.
@export var jump_velocity: float = -560.0
# Safety cap so falling can't accelerate forever (matters for tall rooms).
@export var max_fall_speed: float = 900.0

@export_group("Jump feel helpers")
# COYOTE TIME: a tiny grace period AFTER walking off a ledge during which a jump
# still works. Named after Wile E. Coyote hanging in the air before he falls.
# Without it, pressing jump 1 frame too late feels cheated. 0.10 = 100 ms.
@export var coyote_time: float = 0.10
# JUMP BUFFER: if the player presses jump slightly BEFORE landing, we remember
# the press this long and fire it the moment they touch ground. Without it, an
# early press is silently eaten and the jump "doesn't come out." 0.10 = 100 ms.
@export var jump_buffer_time: float = 0.10
# VARIABLE JUMP HEIGHT: releasing jump while still rising cuts the upward speed,
# so tap = small hop, hold = full jump. cut_factor is how much upward speed
# remains on release (0.5 = keep half = cut the rise in half).
@export var variable_jump_height: bool = true
@export var jump_release_cut_factor: float = 0.5

@export_group("Wall-jump (Room 2)")
# WALL SLIDE: while pressed against a wall in the air and falling, we clamp the
# downward speed to this slow value so the cat "grips" and slides instead of
# plummeting. Pixels per second. Smaller = stickier wall.
@export var wall_slide_speed: float = 90.0
# WALL JUMP PUSH: how hard we shove the cat AWAY from the wall horizontally when
# they wall-jump. Pixels per second.
@export var wall_jump_push: float = 320.0
# The upward kick of a wall jump (negative = up). Often a touch weaker than a
# normal jump because you also get horizontal distance.
@export var wall_jump_velocity: float = -520.0
# CONTROL LOCKOUT: right after a wall jump we briefly ignore horizontal input so
# the push actually carries the cat off the wall (otherwise holding "toward the
# wall" would instantly cancel the shove). Seconds. Try 0.08–0.16.
@export var wall_jump_control_lockout: float = 0.12

@export_group("Dash (Room 3)")
# DASH SPEED: the burst velocity during a dash, in pixels per second. Should be
# clearly faster than run_speed so the dash reads as a dash.
@export var dash_speed: float = 620.0
# How long the dash burst lasts, in seconds. Short and punchy. Try 0.10–0.20.
@export var dash_duration: float = 0.15
# How long you must wait between dashes, measured FROM THE START of a dash, so
# this should be >= dash_duration. Prevents spamming. Seconds.
@export var dash_cooldown: float = 0.50


# =============================================================================
# INTERNAL STATE  (not exported — the game manages these, not you)
# -----------------------------------------------------------------------------
# Most of these are little countdown timers in SECONDS. Each physics frame we
# subtract `delta` (the time that frame took). A timer > 0 means "this thing is
# still active / still remembered." We clamp them at 0 (see _update_timers).
# =============================================================================

# Jump feel timers (Step 2).
var _coyote_timer: float = 0.0          # grace window after leaving the floor
var _jump_buffer_timer: float = 0.0     # remembered jump press

# Dash state (Step 3).
var _dash_timer: float = 0.0            # > 0 while a dash is actively happening
var _dash_cooldown_timer: float = 0.0   # > 0 while dash is on cooldown
var _dash_direction: float = 1.0        # which way the current dash points (-1/+1)

# Wall-jump state (Step 3).
var _wall_jump_lockout_timer: float = 0.0  # > 0 = ignore horizontal input

# FACING: which way the cat last moved (-1 = left, +1 = right). We need this so
# a dash with no direction held still shoots the way the cat is "looking."
var _facing: float = 1.0


# GODOT CONCEPT — "@onready" + "$NodePath"
#   @onready waits until this node's children exist, THEN grabs the
#   AnimatedSprite2D child (the cat's flipbook). $AnimatedSprite2D is shorthand
#   for get_node("AnimatedSprite2D"). We talk to it to play animations and to
#   flip the cat left/right. (See player.tscn for the node + its "idle" frames.)
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


# =============================================================================
# _ready()
# -----------------------------------------------------------------------------
# GODOT CONCEPT — "groups"
#   A group is just a TAG you can stick on a node so other code can find or
#   recognise it. Here we tag the player as "player". Doors and the goal zone
#   then check `body.is_in_group("player")` to react to the cat and ignore
#   everything else — without needing a direct reference to this exact node.
#   _ready() runs once when the node enters the tree (see door.gd for more).
# =============================================================================
# Set true while ANY conversation is on screen. While true, the player ignores
# input so the cat can't run around during a cutscene/dialogue. See the signal
# handlers below and the check at the top of _physics_process.
var _dialogue_active: bool = false


func _ready() -> void:
	add_to_group("player")

	# CONTROL LOCK DURING DIALOGUE
	# DialogueManager (the autoload) announces when any conversation starts and
	# ends. We listen to both and flip _dialogue_active, which freezes movement.
	# This is global, so it covers cutscene zones, cat talks, the trivia lead-in —
	# every conversation, in every room, automatically.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# Called when any conversation opens: lock controls.
func _on_dialogue_started(_resource) -> void:
	_dialogue_active = true

# Called when any conversation closes. We DON'T blindly hand control back here:
# a Weaver cutscene keeps dimming/un-fading the room for a while AFTER the last
# line clears, and the player should stay frozen until that visual is fully done.
# So input resumes only once BOTH the dialogue is over AND no cutscene visual is
# still active (see _is_controllable, checked in _physics_process).
func _on_dialogue_ended(_resource) -> void:
	_dialogue_active = false


# True only when the player should accept input: no dialogue showing AND no
# cutscene visual (the Weaver's dim/un-fade) still in progress.
func _is_controllable() -> bool:
	if _dialogue_active:
		return false
	if GameState.is_cutscene_active():
		return false
	return true


# =============================================================================
# _physics_process(delta)
# -----------------------------------------------------------------------------
# GODOT CONCEPT — "_physics_process" vs "_process"
#   Godot calls _process() every rendered frame (rate varies with monitor/load)
#   and _physics_process() on a FIXED schedule (60/sec by default). All movement
#   and collision MUST go in _physics_process so physics is stable and
#   frame-rate independent. `delta` is the seconds since the last physics tick;
#   multiplying speeds by delta keeps motion identical at any frame rate.
#
#   We keep this function readable by handing each job to a small named helper.
#   IMPORTANT ordering note: a dash overrides everything else, so we check it
#   first and, if we're mid-dash, we skip the normal gravity/run/jump logic for
#   this frame.
# =============================================================================
func _physics_process(delta: float) -> void:
	# CONTROL LOCK: while a conversation is on screen OR a cutscene visual is still
	# fading (see _is_controllable), ignore all input. We still apply gravity and
	# slide so the cat settles naturally onto the ground (it shouldn't hover
	# mid-air during a cutscene) and we force the idle animation so it stands
	# calmly. Then we return early — no run/jump/dash this frame.
	if not _is_controllable():
		_apply_gravity(delta)
		velocity.x = 0.0
		_play_if_exists(&"idle")
		move_and_slide()
		return

	_update_timers(delta)
	_update_facing()

	# Try to BEGIN a dash this frame (does nothing unless dash is unlocked,
	# off cooldown, and the dash key was just pressed).
	_handle_dash_start()

	# If a dash is currently happening, it takes over: fixed-speed burst, no
	# gravity, no normal steering. Move and bail out early.
	if _is_dashing():
		_apply_dash_motion()
		_update_animation()
		move_and_slide()
		return

	# --- Normal (non-dashing) movement ---
	_apply_gravity(delta)

	# Skip horizontal steering during the brief post-wall-jump lockout so the
	# shove off the wall isn't immediately cancelled by the player's input.
	if _wall_jump_lockout_timer <= 0.0:
		_handle_horizontal_movement(delta)

	_handle_wall_slide()
	_handle_jump()
	_handle_variable_jump_height()
	_update_animation()

	# move_and_slide() reads our `velocity`, moves the body, resolves collisions,
	# and refreshes is_on_floor()/is_on_wall() for next frame.
	move_and_slide()


# -----------------------------------------------------------------------------
# _update_timers: tick every countdown each frame, clamped so none go negative.
# -----------------------------------------------------------------------------
func _update_timers(delta: float) -> void:
	# A note on the clamps (maxf): once a countdown reaches 0 it has done its job,
	# and "0" already reads as "expired/idle" everywhere we test it (timer > 0).
	# Letting it keep subtracting would just drift further negative forever. That
	# is harmless functionally — and NOT a real "overflow", since these are
	# 64-bit floats, not fixed-size integer buffers — but parking the value at 0
	# keeps it in its meaningful range (0 .. max), which reads clearly in the
	# debugger and preserves float precision. maxf(a, b) returns the larger of
	# two floats, so maxf(x - delta, 0.0) means "subtract delta, never below 0."

	# COYOTE: while on the floor, keep the timer "full" so the grace window is
	# fresh the instant we step off. Once airborne, count it down toward zero.
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	# JUMP BUFFER: the moment the player taps jump, remember it by filling the
	# buffer timer. Otherwise count it down so an old press eventually expires.
	# Input.is_action_just_pressed("jump") is true for the ONE frame the key goes
	# down (vs is_action_pressed, true the whole time it's held).
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	# DASH + WALL-JUMP timers: simple countdowns toward zero.
	_dash_timer = maxf(_dash_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_wall_jump_lockout_timer = maxf(_wall_jump_lockout_timer - delta, 0.0)


# -----------------------------------------------------------------------------
# _update_facing: remember which way the cat is moving, for direction-less dashes.
# -----------------------------------------------------------------------------
func _update_facing() -> void:
	var input_direction: float = Input.get_axis("move_left", "move_right")
	if input_direction < 0.0:
		_facing = -1.0
	elif input_direction > 0.0:
		_facing = 1.0
	# If input_direction is 0 we leave _facing unchanged (keep last facing).


# -----------------------------------------------------------------------------
# _update_animation: face the sprite the right way + play the matching clip.
# -----------------------------------------------------------------------------
# This is the ONLY place that talks to the cat's visuals. It does two jobs:
#   1. FLIP: face the sprite left/right based on _facing. AnimatedSprite2D has a
#      built-in `flip_h` (mirror horizontally). Our art faces RIGHT by default,
#      so flip_h = true when facing left.
#   2. PICK A CLIP: choose an animation NAME from the movement state, then play
#      it — but ONLY if that animation actually exists yet. Right now only "idle"
#      exists, so everything safely falls back to "idle". As you export "run",
#      "jump_rise", etc. into the SpriteFrames, they light up automatically with
#      no code change. That's what _resolve_animation + the has_animation guard
#      below are for.
func _update_animation() -> void:
	if _sprite == null:
		return

	# 1) Face the right way (skip when facing is exactly 0, which shouldn't happen
	#    since _facing only ever holds -1 or +1, but it's a cheap safety net).
	if _facing < 0.0:
		_sprite.flip_h = true
	elif _facing > 0.0:
		_sprite.flip_h = false

	# 2) Decide which animation the current movement state wants, then play the
	#    best one we actually have.
	var wanted: StringName = _resolve_animation()
	_play_if_exists(wanted)


# Returns the animation NAME that best matches what the cat is doing right now.
# These names are the ones from the art-pipeline plan; you don't have to make
# them all at once — missing ones fall back to "idle" via _play_if_exists.
func _resolve_animation() -> StringName:
	if _is_dashing():
		return &"dash"

	if not is_on_floor():
		# Airborne: clinging to a wall, rising, or falling.
		if GameState.has_wall_jump and is_on_wall_only() and velocity.y > 0.0:
			return &"wall_slide"
		if velocity.y < 0.0:
			return &"jump_rise"
		return &"fall"

	# On the ground: running if we're moving sideways with intent, else idle.
	if absf(velocity.x) > 5.0:
		return &"run"
	return &"idle"


# Plays `anim_name` if the SpriteFrames has it; otherwise falls back to "idle".
# Calling play() with the clip that's already playing is a no-op, so it's safe to
# call every physics frame. This guard is what lets us reference future
# animations now without crashing before they're made.
func _play_if_exists(anim_name: StringName) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null:
		return
	if frames.has_animation(anim_name):
		_sprite.play(anim_name)
	elif frames.has_animation(&"idle"):
		_sprite.play(&"idle")


# -----------------------------------------------------------------------------
# _apply_gravity: pull the cat downward every frame while airborne.
# -----------------------------------------------------------------------------
func _apply_gravity(delta: float) -> void:
	# is_on_floor() is a built-in CharacterBody2D check, true when standing on
	# something. It reflects the LAST move_and_slide(), so we read it here.
	if not is_on_floor():
		# velocity is a Vector2 (x = horizontal, y = vertical). Add gravity to y.
		velocity.y += gravity * delta
		# Clamp so we never exceed terminal velocity.
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed


# -----------------------------------------------------------------------------
# _handle_horizontal_movement: run left/right with accel & friction.
# -----------------------------------------------------------------------------
func _handle_horizontal_movement(delta: float) -> void:
	# Input.get_axis returns -1 (left only), +1 (right only), or 0 (neither or
	# both). It does the "which direction" math for us from our two actions.
	var input_direction: float = Input.get_axis("move_left", "move_right")

	# Pick how strongly we can change speed: less control in the air.
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration

	if input_direction != 0.0:
		# Player is holding a direction: ease velocity toward the target speed.
		# move_toward(current, target, step) walks `current` toward `target` by
		# at most `step` — smooth and never overshoots.
		var target_speed: float = input_direction * run_speed
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		# No input: ease velocity toward 0 using friction (ground stops harder).
		var stopping: float = ground_friction if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, 0.0, stopping * delta)


# -----------------------------------------------------------------------------
# _handle_wall_slide: clamp falling speed while gripping a wall in the air.
# -----------------------------------------------------------------------------
# GODOT CONCEPT — is_on_wall_only()
#   is_on_wall() is true whenever a wall is touched; is_on_wall_only() is true
#   only when touching a wall AND NOT the floor. We want the slide only when
#   airborne against a wall, so we use is_on_wall_only().
func _handle_wall_slide() -> void:
	if not GameState.has_wall_jump:
		return

	# Only slow the fall when we're actually descending (velocity.y > 0). If the
	# cat is still rising we leave it alone so jumps near walls feel normal.
	if is_on_wall_only() and velocity.y > 0.0:
		if velocity.y > wall_slide_speed:
			velocity.y = wall_slide_speed


# -----------------------------------------------------------------------------
# _handle_jump: fire a ground/coyote jump OR a wall jump, whichever applies.
# -----------------------------------------------------------------------------
# A jump is "wanted" whenever the jump buffer is still warm (recent press). We
# then pick which KIND of jump to do, in priority order:
#   1. Ground/coyote jump — if jump is unlocked and we're on (or just left) the
#      floor. This is the Step 2 behaviour, untouched.
#   2. Wall jump — if wall-jump is unlocked and we're clinging to a wall midair.
func _handle_jump() -> void:
	var wants_to_jump: bool = _jump_buffer_timer > 0.0
	if not wants_to_jump:
		return

	if GameState.has_jump and _coyote_timer > 0.0:
		_do_ground_jump()
	elif GameState.has_wall_jump and is_on_wall_only():
		_do_wall_jump()


# Performs a normal upward jump and spends the timers so we get exactly one jump.
func _do_ground_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	jumped.emit()


# Performs a wall jump: push away from the wall and up.
# GODOT CONCEPT — a "normal" / get_wall_normal()
#   A surface's NORMAL is a unit vector pointing straight out of that surface.
#   get_wall_normal() returns the wall's normal, which points FROM the wall
#   toward the cat (i.e. away from the wall). So moving the cat along the normal
#   pushes it off the wall. For a wall on the cat's right, the normal points
#   left (x = -1); for a wall on the left, it points right (x = +1).
func _do_wall_jump() -> void:
	var wall_normal: Vector2 = get_wall_normal()

	# Horizontal shove directly away from the wall, and a fixed upward kick.
	velocity.x = wall_normal.x * wall_jump_push
	velocity.y = wall_jump_velocity

	# Briefly ignore steering so the shove carries (see _physics_process).
	_wall_jump_lockout_timer = wall_jump_control_lockout

	# Face away from the wall, so a follow-up dash goes the sensible direction.
	if wall_normal.x != 0.0:
		_facing = signf(wall_normal.x)

	# Spend the buffer so one press = one wall jump.
	_jump_buffer_timer = 0.0
	jumped.emit()


# -----------------------------------------------------------------------------
# _handle_variable_jump_height: short hop vs full jump.
# -----------------------------------------------------------------------------
# If the player lets go of jump while still moving UP (velocity.y < 0), trim the
# remaining upward speed so the hop is shorter. Holding = a taller jump. This
# applies to both ground and wall jumps (both set a negative velocity.y).
func _handle_variable_jump_height() -> void:
	if not variable_jump_height:
		return

	var released_jump_early: bool = Input.is_action_just_released("jump")
	var still_rising: bool = velocity.y < 0.0

	if released_jump_early and still_rising:
		velocity.y *= jump_release_cut_factor


# -----------------------------------------------------------------------------
# _handle_dash_start: begin a dash if it's unlocked, off cooldown, and pressed.
# -----------------------------------------------------------------------------
# APPROACH (why a timer, not a Timer node):
#   We model the dash with two simple float countdowns rather than a Timer node.
#   _dash_timer > 0 means "a dash is happening right now"; _dash_cooldown_timer
#   > 0 means "too soon to dash again." Plain numbers in _physics_process keep
#   all the movement timing in one place and frame-rate-correct, and are easier
#   to read than juggling Timer nodes and their timeout signals.
func _handle_dash_start() -> void:
	if not GameState.has_dash:
		return
	# is_action_just_pressed = true only on the single frame the key goes down.
	if not Input.is_action_just_pressed("dash"):
		return
	# Don't restart a dash that's already running, and respect the cooldown.
	if _is_dashing() or _dash_cooldown_timer > 0.0:
		return

	# Direction: dash the way the player is holding; if not holding, the way the
	# cat is currently facing.
	var input_direction: float = Input.get_axis("move_left", "move_right")
	_dash_direction = signf(input_direction) if input_direction != 0.0 else _facing

	# Arm the dash. Cooldown is measured from the START of the dash (that's why
	# dash_cooldown should be >= dash_duration; see its @export comment).
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown


# Returns true while a dash burst is in progress.
func _is_dashing() -> bool:
	return _dash_timer > 0.0


# Drives the body during a dash: full-speed horizontal burst, gravity ignored.
func _apply_dash_motion() -> void:
	velocity.x = _dash_direction * dash_speed
	velocity.y = 0.0   # ignore gravity for the duration of the dash
