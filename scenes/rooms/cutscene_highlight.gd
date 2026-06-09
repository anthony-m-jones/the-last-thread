# =============================================================================
# cutscene_highlight.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   Brightens ONE node on cue during a cutscene — e.g. the distant glowing window
#   un-fades when the Weaver says "You watch that window." It listens for a
#   specific dialogue line (marked with a #tag) and, when that line appears, lifts
#   its target node back to full brightness while everything else stays dimmed,
#   then lets it fall back into the dim when the conversation ends.
#
# HOW THE TRIGGER WORKS — line #tags
#   Dialogue Manager lets you tag a line in the .dialogue file like:
#       Weaver: You watch that window. [#highlight_window]
#   Every shown line is announced via DialogueManager.got_dialogue(line), and the
#   line's tags are in `line.tags`. We watch for our `trigger_tag` and fire when
#   it shows up. (Tags are invisible to the player.)
#
# HOW THE BRIGHTEN WORKS
#   The Weaver's dim darkens individual leaf sprites and SKIPS anything in the
#   "cutscene_focus" group. So to spotlight our target we (1) add it to that group
#   so it won't be re-dimmed, and (2) tween its modulate back to full white. When
#   the conversation ends we remove it from the group and let the Weaver's
#   _restore_room handle the fade back (it remembered the target's original).
#
# SETUP (per highlight)
#   Add this node to a room, set `target_path` to the node to spotlight (e.g. the
#   Building/window sprite) and `trigger_tag` to the tag on the line. Reusable for
#   any "light this up on this line" beat.
# =============================================================================
extends Node


# The node to brighten (a Sprite2D, etc.). Pick it in the Inspector.
@export var target_path: NodePath

# The line tag that triggers the highlight (WITHOUT the # — e.g. "highlight_window"
# for a line tagged [#highlight_window]).
@export var trigger_tag: String = "highlight_window"

# How long the brighten fade takes, in seconds.
@export var highlight_fade_time: float = 0.5

# The brightness to lift the target to. White = full original brightness. You
# could push above 1.0 on some channels for an extra glow if desired.
@export var highlight_color: Color = Color(1, 1, 1, 1)


@onready var _target: CanvasItem = get_node_or_null(target_path) as CanvasItem

var _highlighting: bool = false


func _ready() -> void:
	if _target == null:
		push_warning("CutsceneHighlight: target_path doesn't point at a CanvasItem.")
		return
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# Each shown line: if it carries our trigger tag, light the target up.
func _on_got_dialogue(line) -> void:
	if _target == null or _highlighting:
		return
	if trigger_tag in line.tags:
		_begin_highlight()


func _begin_highlight() -> void:
	_highlighting = true
	# Join "cutscene_focus" so the Weaver's dim won't darken this node again.
	_target.add_to_group("cutscene_focus")
	# Lift it back to full brightness.
	var t: Tween = create_tween()
	t.tween_property(_target, "modulate", highlight_color, highlight_fade_time)


# Conversation ended: stop spotlighting. We drop the group membership; the
# Weaver's _restore_room tween (running on dialogue end) returns everything,
# including this node, to its original brightness.
func _on_dialogue_ended(_resource) -> void:
	if not _highlighting:
		return
	_highlighting = false
	if _target != null and is_instance_valid(_target):
		_target.remove_from_group("cutscene_focus")
