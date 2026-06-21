# =============================================================================
# game_state.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   This is the project's single "global memory". In Godot, a script like this
#   that is registered as an "Autoload" (see below) becomes a SINGLETON: exactly
#   one copy of it is created when the game starts, it is never destroyed, and
#   every other script can reach it by name. We named ours "GameState", so any
#   script anywhere can write `GameState.has_jump = true` or read
#   `if GameState.has_dash:` without needing a reference to this object.
#
# WHAT AN "AUTOLOAD" / "SINGLETON" IS
#   Normally a script only exists while the Node it is attached to exists. When
#   you change rooms, Godot destroys the old room (and the player inside it) and
#   builds the new one from scratch. That means anything stored on the player is
#   LOST on a room change. An Autoload lives OUTSIDE the current scene, so it
#   survives every room change. That is exactly why ability unlocks live here.
#
#   You register an Autoload in: Project > Project Settings > Globals > Autoload.
#   We have already done that in project.godot (the [autoload] section). The name
#   we gave it there ("GameState") is the name you type in code.
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - player.gd READS these flags every physics frame to decide which moves are
#     currently allowed (e.g. wall-jump only works if has_wall_jump is true).
#   - interactable.gd (the ability-cats) WRITES these flags to true when a
#     conversation with that cat finishes.
#   Because this object survives room changes, an ability unlocked in Room 1 is
#   still unlocked in Room 2 and Room 3 automatically. No save/load needed for
#   the prototype.
#
# WHY "extends Node"
#   Every script must say what kind of object it extends. Autoloads are plain
#   Nodes (they do not need to be seen or to collide), so we extend the base
#   Node type. Godot creates one Node, runs this script on it, and keeps it alive
#   for the whole game.
# =============================================================================
extends Node


# -----------------------------------------------------------------------------
# ABILITY FLAGS
# -----------------------------------------------------------------------------
# `var` declares a variable. The `: bool` part is the TYPE (true/false) and
# `= false` is the starting value. All three start false. The cat in each room
# flips the matching one to true when its dialogue ends. The player checks these
# before allowing each move.
var has_jump: bool = false          # Unlocked by the cat in Room 1.
var has_wall_jump: bool = false     # Unlocked by the cat in Room 2.
var has_dash: bool = false          # Unlocked by the cat in Room 3.


# -----------------------------------------------------------------------------
# DEBUG / TESTING HELPER
# -----------------------------------------------------------------------------
# When this is true, _ready() turns on all three abilities at startup. Handy for
# tuning movement without first talking to the cats.
#
# >>> Keep this FALSE for the real game flow. <<<
# The three rooms gate progress on abilities, so leaving it true would let the
# cat start with every move and break the metroidvania progression. Flip it to
# true any time you just want to playtest movement in isolation, then back.
@export var debug_unlock_everything: bool = false


# `_ready()` is a built-in Godot callback (the leading underscore marks engine
# callbacks). Godot calls it automatically ONCE, right after this Node enters the
# scene tree — for an Autoload that means once at game startup. We use it only to
# apply the debug toggle above.
func _ready() -> void:
	if debug_unlock_everything:
		unlock_all_for_testing()


# -----------------------------------------------------------------------------
# CUTSCENE VISUAL HOLD
# -----------------------------------------------------------------------------
# A "cutscene" is more than just the dialogue text — the Weaver also dims the
# room, shows his eyes/leg, and (after the talk ends) takes time to fade
# everything back. The PLAYER should stay frozen until that whole visual is
# finished, not just until the last line clears.
#
# So this is a simple COUNTER (not a bool) of how many cutscene visuals are
# currently in progress. The Weaver raises it when it starts dimming and lowers
# it once the room has fully un-faded. A counter (rather than a true/false) is
# safe if two cutscene effects ever overlap — the lock only lifts when ALL of
# them have finished. player.gd checks is_cutscene_active() and stays locked
# while it's true.
var _cutscene_holds: int = 0

# Call when a cutscene visual BEGINS (e.g. the Weaver starts dimming the room).
func begin_cutscene_hold() -> void:
	_cutscene_holds += 1

# Call when a cutscene visual has FULLY finished (room done fading back).
func end_cutscene_hold() -> void:
	_cutscene_holds = maxi(_cutscene_holds - 1, 0)  # clamp so it can't go negative

# True while any cutscene visual is still playing/fading. The player uses this to
# stay frozen until the scene is completely back to normal.
func is_cutscene_active() -> bool:
	return _cutscene_holds > 0


# -----------------------------------------------------------------------------
# SMALL, NAMED HELPERS
# -----------------------------------------------------------------------------
# These let other scripts change state by NAME instead of poking the variables
# directly. It reads more clearly at the call site (`GameState.unlock_jump()`)
# and gives us one obvious place to add things later (a sound, a UI popup).

# Unlocks the jump ability. Called by the Room 1 cat's interactable.
func unlock_jump() -> void:
	has_jump = true
	print("[GameState] Jump unlocked.")  # print() writes to the Output panel.
	AudioManager.play_one_shot(&"sfx.world.unlock")

# Unlocks the wall-jump ability. Called by the Room 2 cat.
func unlock_wall_jump() -> void:
	has_wall_jump = true
	print("[GameState] Wall-jump unlocked.")
	AudioManager.play_one_shot(&"sfx.world.unlock")

# Unlocks the dash ability. Called by the Room 3 cat.
func unlock_dash() -> void:
	has_dash = true
	print("[GameState] Dash unlocked.")
	AudioManager.play_one_shot(&"sfx.world.unlock")


# Convenience for testing only (see debug_unlock_everything above). Turns on
# every ability at once so you can stress-test movement in any room.
func unlock_all_for_testing() -> void:
	has_jump = true
	has_wall_jump = true
	has_dash = true
	print("[GameState] DEBUG: all abilities unlocked.")
