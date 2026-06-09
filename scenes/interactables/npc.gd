# =============================================================================
# npc.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The shared "brain" for every non-player character's VISUAL (Pip, Patch,
#   Marigold, the spiders...). It plays the NPC's idle animation and — optionally —
#   flips the sprite to face the player when they come near, so cats look at the
#   cat they're talking to. That's all it does; it is purely cosmetic.
#
# WHY IT'S SEPARATE FROM THE INTERACTABLE
#   interactable.gd handles the DIALOGUE / ability trigger (the reach area, the
#   "Press E" prompt, playing the conversation). It's also reused for story zones
#   and the trivia pillar, which have NO character art. So the NPC's looks live in
#   their OWN small node, and you simply drop this NPC as a child of the
#   interactable — they stay aligned automatically and each keeps one job.
#
# HOW TO MAKE A NEW NPC (reusable!)
#   Every NPC is a scene whose root uses THIS script and has an AnimatedSprite2D
#   child holding that character's frames. pip.tscn is the first one. To add
#   another cat: duplicate pip.tscn, rename it, and swap the AnimatedSprite2D's
#   SpriteFrames for the new character's frames. No code changes ever.
#
# GODOT CONCEPT — recap
#   AnimatedSprite2D = the flipbook player (same as the cat). flip_h mirrors it
#   left/right. We find the player via the "player" group (set in player.gd).
# =============================================================================
extends Node2D


# Which way a non-following NPC faces. Used only when face_player is OFF.
#   DEFAULT = the art's natural facing (right, for our cats).
#   FLIPPED = mirrored (faces left).
enum StaticFacing { DEFAULT, FLIPPED }


# The animation to loop while idle. Matches the animation name in the
# AnimatedSprite2D's SpriteFrames (we use "idle" everywhere).
@export var idle_animation: StringName = &"idle"

# If true, the NPC turns to face the player when they're within face_distance
# (lively for conversations). If FALSE, the NPC holds a fixed orientation set by
# static_facing below and never turns — good for a cat who's looking away, like
# Patch watching the rain.
@export var face_player: bool = true

# Used ONLY when face_player is off: which way this NPC statically faces.
# Set to FLIPPED to make the NPC face the opposite of its art's default.
@export var static_facing: StaticFacing = StaticFacing.DEFAULT

# How close (in pixels) the player must be before the NPC turns to face them.
@export var face_distance: float = 220.0

# If your art faces LEFT by default instead of right, tick this so the facing
# math is mirrored. (Our cat art faces right; set per-NPC as needed.)
@export var art_faces_left: bool = false


# @onready grabs our AnimatedSprite2D child once it exists. The child MUST be
# named "AnimatedSprite2D" (it is, in npc.tscn / pip.tscn).
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Start the idle loop if the frames have it.
	if _sprite != null and _sprite.sprite_frames != null:
		if _sprite.sprite_frames.has_animation(idle_animation):
			_sprite.play(idle_animation)

	# If this NPC doesn't track the player, lock in its fixed facing now and
	# leave it there forever (_process won't touch it). This is how Patch ends
	# up facing left, away from the player, watching the rain.
	if not face_player:
		_apply_static_facing()


# Sets flip_h once for a non-following NPC, based on static_facing and which way
# the art naturally points. FLIPPED means "the opposite of the art's default."
func _apply_static_facing() -> void:
	if _sprite == null:
		return
	var want_flipped: bool = static_facing == StaticFacing.FLIPPED
	# art_faces_left flips what "default" vs "flipped" means, so FLIPPED always
	# reads as "face the other way" no matter which way the source art points.
	if art_faces_left:
		_sprite.flip_h = not want_flipped
	else:
		_sprite.flip_h = want_flipped


# _process runs every rendered frame — fine for cheap cosmetic work like facing
# (no physics here, so we don't need _physics_process).
func _process(_delta: float) -> void:
	if face_player and _sprite != null:
		_update_facing()


# Turn to face the player if they're close enough; otherwise leave facing as-is.
func _update_facing() -> void:
	var player: Node2D = _find_player()
	if player == null:
		return

	var dx: float = player.global_position.x - global_position.x
	if absf(dx) > face_distance:
		return  # player too far — don't swivel

	# dx > 0 means the player is to our RIGHT. With right-facing art, we DON'T
	# flip when facing right. art_faces_left inverts that.
	var player_is_right: bool = dx > 0.0
	if art_faces_left:
		_sprite.flip_h = player_is_right
	else:
		_sprite.flip_h = not player_is_right


# Finds the player via the "player" group (player.gd does add_to_group("player")).
func _find_player() -> Node2D:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0]
