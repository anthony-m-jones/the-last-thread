@tool
# =============================================================================
# weaver.gd
# -----------------------------------------------------------------------------
# NOTE — "@tool": this line makes the script ALSO run inside the editor, purely
# so the `face_left` flip previews live the moment you tick it. Everything that
# only makes sense at runtime (connecting to DialogueManager, timers) is guarded
# behind `Engine.is_editor_hint()` in _ready so it never runs in the editor.
#
# WHAT THIS FILE IS
#   The Weaver's presence for ONE cutscene location: eight eyes + a long leg that
#   appear together ONLY while he is speaking, plus a "spotlight" effect that dims
#   the rest of the room so the player focuses on his floating eyes and leg.
#   The design doc keeps him "easier to bear in pieces" and always gentle.
#
# ONE WEAVER PER CUTSCENE (how to place him)
#   Position matters per cutscene, so you place a SEPARATE Weaver instance at each
#   spot and tell each one which conversation it belongs to via `weaver_titles`.
#   Example for Room 1: one Weaver near the entrance with weaver_titles = ["intro"],
#   and another near the maze exit with weaver_titles = ["complete"]. Each appears
#   only for its own conversation, at its own location.
#
# WHAT HAPPENS WHEN HIS CONVERSATION STARTS / ENDS
#   START (a title in weaver_titles is reached):
#     - eyes appear and begin their idle + random-blink loop
#     - the leg slides into the light
#     - the rest of the room dims (everything except the player and any Weaver)
#   END (the conversation closes):
#     - the leg slides back into shadow, the eyes fade out
#     - the room brightens back to normal
#
# WHY MATCH BY TITLE
#   A room's .dialogue file holds several conversations (Room 1 has the Weaver's
#   "intro"/"complete" AND Pip's "cat"). We only react to the Weaver's titles, so
#   talking to Pip never summons the eyes or dims the room.
#
# GODOT CONCEPTS used here
#   - autoload signals: we connect to the global DialogueManager's passed_title /
#     dialogue_ended to know when a conversation starts/ends.
#   - "groups": this node joins the "weaver" group so the dimming step knows to
#     keep all weavers bright (player.gd already joins "player").
#   - Tween: a little animator we create to smoothly fade modulate (brightness)
#     over time instead of snapping.
#   - modulate: every visual node has a `modulate` color that tints it; lowering
#     it toward black darkens that node. We darken the room's other nodes to dim.
# =============================================================================
extends Node2D


# Which conversation titles summon THIS Weaver. Usually one title per instance.
@export var weaver_titles: PackedStringArray = PackedStringArray(["intro"])

# FACING — flip the whole Weaver horizontally. The art is drawn with the leg
# sliding out to the RIGHT; tick this for a Weaver whose leg should slide out to
# the LEFT instead (and whose eyes mirror to match). It simply negates the root's
# horizontal scale, mirroring the eyes and leg together — both their art AND
# their offset positions — so the leg appears and slides from the opposite side.
# The setter applies it immediately, so you SEE the flip in the editor the moment
# you tick the box. Set per Weaver instance to taste.
@export var face_left: bool = false:
	set(value):
		face_left = value
		_apply_facing()

# Eye blink timing (seconds): wait a random time in this range between blinks so
# blinking looks natural, never clockwork.
@export var blink_interval_min: float = 2.5
@export var blink_interval_max: float = 6.0

# How dark the rest of the room gets during his cutscene (a multiply tint; lower =
# darker). 1,1,1 would be no change; this is a deep dusk that still shows shapes.
@export var dim_color: Color = Color(0.28, 0.26, 0.34, 1.0)

# How long the dim fade and the eye fade take, in seconds.
@export var fade_time: float = 0.4

# -- APPEARANCE / DISAPPEARANCE TIMING (seconds) ------------------------------
# These let you stagger when the eyes and leg show up and leave, relative to the
# moment the cutscene starts (for appear) or ends (for disappear). All measured
# from that moment, so e.g. eyes_appear_delay = 0.4 makes the eyes wait until the
# room has finished dimming before fading in. Tweak in the Inspector to taste.
@export_group("Appearance timing")
# On cutscene START — delays before each part appears (so they can come in AFTER
# the room dims, and one after the other).
@export var eyes_appear_delay: float = 0.4   # wait for the dim, then eyes
@export var leg_appear_delay: float = 0.6    # leg a touch after the eyes
# How long the eyes take to FADE IN (the leg's "fade in" is its slide animation).
@export var eyes_fade_in_time: float = 0.3
# On cutscene END — delays before each part leaves. Make the eyes' delay >= the
# leg's so the eyes don't vanish before the leg has withdrawn.
@export var leg_disappear_delay: float = 0.0   # leg starts withdrawing first
@export var eyes_disappear_delay: float = 0.4  # eyes linger, then fade out
# How long to wait after dialogue ends before the ROOM starts brightening back.
# Set this long enough that the leg's slide-out finishes and the eyes have fully
# faded, so the world stays dark until the Weaver is completely gone. A good
# starting value is a bit more than eyes_disappear_delay + fade_time.
@export var room_restore_delay: float = 1.0

# Animation names inside the SpriteFrames (match the exported clips).
@export var eyes_idle_anim: StringName = &"idle"
@export var eyes_blink_anim: StringName = &"blink"
@export var leg_slide_anim: StringName = &"leg_slide"
# The leg's resting loop, played AFTER the slide-in finishes. On exit it's played
# in REVERSE so the leg withdraws into the shadow. Add an animation of this exact
# name to the Leg node's SpriteFrames in the editor. If it's missing, the leg
# gracefully falls back to retracting via leg_slide reversed.
@export var leg_idle_anim: StringName = &"leg_idle"
# NOTE: leg_slide and leg_idle line up automatically because both were exported
# from Spine together with "Maximum bounds" on — every animation shares one
# canvas size with the art in the same spot, so no per-clip offset is needed.


@onready var _eyes: AnimatedSprite2D = $Eyes
@onready var _leg: AnimatedSprite2D = $Leg
@onready var _blink_timer: Timer = $BlinkTimer


# Mirror the whole Weaver horizontally based on face_left. We flip the ROOT's
# scale.x (negative = mirrored), which flips the eyes and leg together — art and
# offsets — so the leg slides from the opposite side. Guarded so it's safe if the
# setter runs during scene load before the node is ready.
func _apply_facing() -> void:
	if not is_node_ready():
		return
	# Use the current magnitude so we don't fight any scale you set on the root.
	var magnitude: float = absf(scale.x)
	if magnitude == 0.0:
		magnitude = 1.0
	scale.x = -magnitude if face_left else magnitude


# True while THIS weaver's cutscene is active (guards against double-trigger and
# tells us whether we're the one who dimmed the room, so only we restore it).
var _active: bool = false

# Remembers the original modulate of every node we darkened, so we can restore
# them exactly. Keyed by the node, valued by its original Color.
var _dimmed_originals: Dictionary = {}

# True while we currently hold the global cutscene lock (so we release it exactly
# once, after the room has fully un-faded). See GameState.begin/end_cutscene_hold.
var _holding_cutscene: bool = false


func _ready() -> void:
	# Apply the facing flip now that children exist (covers both the editor
	# preview and loading a scene that already had face_left ticked).
	_apply_facing()

	# In the EDITOR we stop here — we only want the visual flip to preview. None
	# of the runtime wiring below (autoload signals, timers) should run in-editor.
	if Engine.is_editor_hint():
		return

	# Join the "weaver" group so the dimming step keeps all weavers bright.
	add_to_group("weaver")

	# Start fully hidden — eyes AND leg only appear when he speaks.
	_eyes.visible = false
	_leg.visible = false

	# Blink timer setup (only runs while the eyes are visible).
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_on_blink_timer_timeout)

	# React to blink/leg clips finishing.
	_eyes.animation_finished.connect(_on_eyes_animation_finished)
	_leg.animation_finished.connect(_on_leg_animation_finished)

	# Listen to the global dialogue system.
	DialogueManager.passed_title.connect(_on_passed_title)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# -----------------------------------------------------------------------------
# Cutscene start / end
# -----------------------------------------------------------------------------

# A conversation reached a title. If it's one of ours, begin the appearance.
func _on_passed_title(title: String) -> void:
	if _active:
		return
	if title in weaver_titles:
		_begin_cutscene()

# A conversation ended. If we were the active weaver, withdraw + un-dim.
func _on_dialogue_ended(_resource) -> void:
	if _active:
		_end_cutscene()


# Begin: dim the room immediately, then bring in the eyes and leg after their
# configured delays. We use _delayed() (a small await-on-timer helper) so each
# part can be staggered without blocking. Each step re-checks `_active` so a fast
# end-before-appear can't make a part pop in after the cutscene already closed.
func _begin_cutscene() -> void:
	_active = true

	# Freeze the player for the WHOLE cutscene visual — not just the dialogue. We
	# raise a global "cutscene hold" now (as we start dimming) and only release it
	# once the room has fully un-faded (see _restore_room_if_idle). This keeps the
	# cat locked through the post-dialogue fade-back instead of the instant the
	# last line clears. _holding_cutscene tracks that WE raised it, so we release
	# exactly once.
	if not _holding_cutscene:
		_holding_cutscene = true
		GameState.begin_cutscene_hold()

	# Dim the rest of the room for focus — happens first, at time 0.
	_dim_room()

	# Eyes appear after eyes_appear_delay (e.g. once the dim has landed).
	_delayed(eyes_appear_delay, _show_eyes)
	# Leg appears after leg_appear_delay.
	_delayed(leg_appear_delay, _show_leg)


# Show the eyes: fade them in and start idle + blinking. Guarded so it does
# nothing if the cutscene ended during the delay.
func _show_eyes() -> void:
	if not _active:
		return
	_eyes.visible = true
	_eyes.modulate = Color(1, 1, 1, 0)  # start transparent, then fade in
	if _eyes.sprite_frames != null and _eyes.sprite_frames.has_animation(eyes_idle_anim):
		_eyes.play(eyes_idle_anim)
	var t: Tween = create_tween()
	t.tween_property(_eyes, "modulate:a", 1.0, eyes_fade_in_time)
	_schedule_next_blink()


# Plays a leg clip forward or in reverse. All leg playback routes through here so
# there's one place to manage it. (Clips align automatically thanks to the Spine
# "Maximum bounds" export — see the note by leg_idle_anim.)
func _play_leg(anim: StringName, backwards: bool) -> void:
	if backwards:
		_leg.play_backwards(anim)
	else:
		_leg.play(anim)


# Show the leg: slide it IN (play the slide forward).
func _show_leg() -> void:
	if not _active:
		return
	_leg.visible = true
	if _leg.sprite_frames != null and _leg.sprite_frames.has_animation(leg_slide_anim):
		_play_leg(leg_slide_anim, false)


# End: brighten the room, then withdraw the leg and fade the eyes after their
# configured delays. Guarded with `not _active` so a new cutscene starting during
# the delay cancels these leftover hide steps.
func _end_cutscene() -> void:
	_active = false

	# Stop blinking right away.
	_blink_timer.stop()

	# Withdraw the leg, then fade the eyes, each after its delay.
	_delayed(leg_disappear_delay, _hide_leg)
	_delayed(eyes_disappear_delay, _hide_eyes)

	# Brighten the room back to normal AFTER room_restore_delay — long enough for
	# the leg to finish sliding out and the eyes to fully fade, so the world stays
	# dark until the Weaver is completely gone.
	_delayed(room_restore_delay, _restore_room_if_idle)


# Restore the room only if no new cutscene started during the delay. (If one did,
# _begin_cutscene already re-dimmed, and we must not brighten over it.)
func _restore_room_if_idle() -> void:
	if _active:
		return
	_restore_room()
	# The room is now fading back over fade_time. Release the player only AFTER
	# that fade fully completes, so input resumes on a clean, fully-lit scene.
	_delayed(fade_time, _release_cutscene_hold)


# Lifts our global cutscene hold (once), unless a new cutscene re-started in the
# meantime (in which case _begin_cutscene already owns a fresh hold and _active
# is true, so we leave it locked).
func _release_cutscene_hold() -> void:
	if _active:
		return
	if _holding_cutscene:
		_holding_cutscene = false
		GameState.end_cutscene_hold()


# Withdraw the leg into shadow. The retraction is leg_slide played in REVERSE —
# that's the clip with the actual in/out MOTION. (leg_idle is only an in-place
# rest loop; reversing it wouldn't move the leg anywhere.) play_backwards starts
# from the slide's LAST frame — the fully-extended pose, which matches where the
# leg_idle rest sits — and runs to frame 0, the in-shadow pose. Only acts if still
# inactive (no new cutscene started during the disappear delay).
func _hide_leg() -> void:
	if _active:
		return
	if _leg.sprite_frames == null:
		_leg.visible = false
		return

	if _leg.sprite_frames.has_animation(leg_slide_anim):
		_play_leg(leg_slide_anim, true)
		# Hide after one full reverse pass. We use a duration timer rather than the
		# animation_finished signal so it's robust even if the leg was looping
		# leg_idle a moment ago.
		_delayed(_anim_duration(leg_slide_anim), _hide_leg_now)
	elif _leg.sprite_frames.has_animation(leg_idle_anim):
		# Fallback only if there's no slide clip at all.
		_play_leg(leg_idle_anim, true)
		_delayed(_anim_duration(leg_idle_anim), _hide_leg_now)
	else:
		_leg.visible = false


# Hide the leg now, unless a new cutscene started during the retract.
func _hide_leg_now() -> void:
	if _active:
		return
	_leg.visible = false


# Total play time of an animation in seconds = sum of per-frame durations / speed.
# Used so a looping reverse can still be ended after exactly one pass.
func _anim_duration(anim: StringName) -> float:
	var sf: SpriteFrames = _leg.sprite_frames
	if sf == null or not sf.has_animation(anim):
		return 0.0
	var speed: float = sf.get_animation_speed(anim)
	if speed <= 0.0:
		return 0.0
	var total: float = 0.0
	for i in sf.get_frame_count(anim):
		total += sf.get_frame_duration(anim, i)
	return total / speed


# Fade the eyes out, then hide them. Guarded the same way.
func _hide_eyes() -> void:
	if _active:
		return
	var t: Tween = create_tween()
	t.tween_property(_eyes, "modulate:a", 0.0, fade_time)
	t.tween_callback(func(): _eyes.visible = false)


# Small helper: run `callback` after `delay` seconds without blocking. A delay of
# 0 still defers one tiny timer tick, which is fine. Uses a scene-tree timer so it
# works regardless of this node's own processing.
func _delayed(delay: float, callback: Callable) -> void:
	if delay <= 0.0:
		callback.call()
		return
	await get_tree().create_timer(delay).timeout
	callback.call()


# -----------------------------------------------------------------------------
# EYES — blink loop (only active during a cutscene)
# -----------------------------------------------------------------------------
func _schedule_next_blink() -> void:
	_blink_timer.wait_time = randf_range(blink_interval_min, blink_interval_max)
	_blink_timer.start()

func _on_blink_timer_timeout() -> void:
	if not _active:
		return
	if _eyes.sprite_frames != null and _eyes.sprite_frames.has_animation(eyes_blink_anim):
		_eyes.play(eyes_blink_anim)
	else:
		_schedule_next_blink()

func _on_eyes_animation_finished() -> void:
	# When a blink finishes, return to idle and queue the next blink.
	if _eyes.animation == eyes_blink_anim and _active:
		_eyes.play(eyes_idle_anim)
		_schedule_next_blink()


# -----------------------------------------------------------------------------
# LEG — when the slide-IN finishes, settle into the resting leg_idle loop.
# -----------------------------------------------------------------------------
# This handler's ONLY job is the entrance hand-off: slide-in done → start the rest
# loop. The EXIT/hide is owned by _hide_leg's duration timer (so it works whether
# or not leg_idle was looping), so we deliberately do nothing here when inactive.
func _on_leg_animation_finished() -> void:
	if not _active:
		return
	var finished: StringName = _leg.animation
	var has_leg_idle: bool = _leg.sprite_frames != null and _leg.sprite_frames.has_animation(leg_idle_anim)
	if finished == leg_slide_anim and has_leg_idle:
		_play_leg(leg_idle_anim, false)


# -----------------------------------------------------------------------------
# ROOM DIMMING — darken the scenery, except the player, weavers, and focus nodes
# -----------------------------------------------------------------------------
# We darken individual LEAF sprites (a sprite with no visual children) rather than
# whole containers. Why: modulate cascades to children, so tinting a container
# like "Midground" would dim everything inside it as one block — and we couldn't
# then re-brighten just ONE thing inside (like the distant window). Tinting each
# leaf sprite lets the cutscene highlighter exempt/brighten a single node.
#
# Skipped entirely (kept bright): anything in the "player", "weaver", or
# "cutscene_focus" groups (and their subtrees), plus the room's CanvasModulate.
func _dim_room() -> void:
	var room: Node = _find_room()
	if room == null:
		return

	_dimmed_originals.clear()
	var leaves: Array[CanvasItem] = []
	_collect_dimmable_leaves(room, leaves)
	for item in leaves:
		_dimmed_originals[item] = item.modulate   # remember original brightness
		var t: Tween = create_tween()
		t.tween_property(item, "modulate", dim_color, fade_time)


# Walks the tree under `node`, collecting visual LEAF nodes to dim. Skips exempt
# subtrees so the player / weavers / focus nodes (and their children) stay lit.
func _collect_dimmable_leaves(node: Node, into: Array[CanvasItem]) -> void:
	for child in node.get_children():
		# Skip exempt subtrees entirely (don't dim them or anything beneath them).
		if child.is_in_group("player") or child.is_in_group("weaver") or child.is_in_group("cutscene_focus"):
			continue
		if child is CanvasModulate:
			continue
		# Skip ALL UI layers. A CanvasLayer draws in screen space (HUD, the room's
		# on-screen Hint, and — importantly — the dialogue balloon, which the
		# DialogueManager adds as a CanvasLayer child of the room). We must never
		# dim those, or the conversation text itself fades out with the scenery.
		if child is CanvasLayer:
			continue

		# Does this child have any visual children? If so it's a container — recurse
		# into it but don't tint the container itself (avoids double-tinting).
		if _has_canvasitem_child(child):
			_collect_dimmable_leaves(child, into)
		elif child is CanvasItem:
			into.append(child)            # a leaf sprite — dim this
		else:
			_collect_dimmable_leaves(child, into)  # plain Node — keep searching


# True if `node` has at least one direct child that is a CanvasItem (visual).
func _has_canvasitem_child(node: Node) -> bool:
	for child in node.get_children():
		if child is CanvasItem:
			return true
	return false


# Restore every leaf we dimmed back to its original brightness.
func _restore_room() -> void:
	for item in _dimmed_originals.keys():
		if is_instance_valid(item):
			var original: Color = _dimmed_originals[item]
			var t: Tween = create_tween()
			t.tween_property(item, "modulate", original, fade_time)
	_dimmed_originals.clear()


# Walk up the parent chain to find the Room (class_name Room).
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
