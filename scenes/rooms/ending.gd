# =============================================================================
# ending.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The ending scene's tiny controller. When the scene loads, it plays the final
#   conversation (Ella off-screen, the purring, the Weaver's last words) through
#   the DialogueManager. That's all it does.
# =============================================================================
extends Node2D


# The ending conversation. Set in the Inspector (ending.dialogue, title "ending").
@export var dialogue_file: DialogueResource
@export var dialogue_title: String = "ending"


func _ready() -> void:
	if dialogue_file == null:
		push_warning("Ending: no dialogue_file set.")
		return
	# call_deferred so the scene is fully in the tree before the balloon opens.
	_play.call_deferred()


func _play() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_file, dialogue_title)
