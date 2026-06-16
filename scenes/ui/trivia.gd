# =============================================================================
# trivia.gd
# -----------------------------------------------------------------------------
# WHAT THIS FILE IS
#   The Room 3 trivia puzzle: it shows a question and one button per answer,
#   reading everything from a DATA FILE (data/trivia.json) so you can rewrite the
#   quiz without touching code. Wrong answers are NOT punishing — picking wrong
#   shows a gentle correction and lets the player try the same question again;
#   only a correct answer advances. When the last question is answered correctly,
#   the puzzle is solved.
#
# HOW THIS CONNECTS TO THE REST OF THE GAME
#   - It reads questions from data/trivia.json (the `trivia_data_path` @export).
#   - On success it does TWO things so it's flexible:
#       1. emits the `trivia_completed` signal (connect it to anything), and
#       2. if it sits inside a Room (room.gd), it calls that room's
#          mark_puzzle_complete() automatically — same parent-walk trick the
#          door and goal zone use. So just dropping it into a room "just works".
#
# GODOT CONCEPT — "Control nodes" and building UI from code
#   Buttons, Labels, containers are "Control" nodes (the UI family). We have a
#   fixed Label for the question and a VBoxContainer (stacks children vertically)
#   that we FILL with Button nodes at runtime — one per answer. Creating nodes in
#   code (Button.new(), add_child(...)) is how you build a list whose length you
#   don't know until you read the data.
# =============================================================================
extends CanvasLayer


# Custom signal announced once the whole quiz is solved (see room.gd for what a
# signal is). Anything can connect to react to "trivia done".
signal trivia_completed


# GODOT CONCEPT — "@export_file" (recap from door.gd)
#   Shows a file picker in the Inspector. Point it at the JSON data file. Kept as
#   an export so you could even have different quizzes per room by pointing
#   different trivia instances at different files.
@export_file("*.json") var trivia_data_path: String = "res://data/trivia.json"


# @onready grabs our child UI nodes once they exist (see door.gd for @onready).
# These node names must match the ones in trivia.tscn.
@onready var _question_label: Label = $Root/Panel/Layout/QuestionLabel
@onready var _answers_box: VBoxContainer = $Root/Panel/Layout/AnswersBox
@onready var _feedback_label: Label = $Root/Panel/Layout/FeedbackLabel
@onready var _progress_label: Label = $Root/Panel/Layout/ProgressLabel


# Loaded question data and where we are in it.
var _questions: Array = []          # the list parsed from JSON
var _current_index: int = 0         # which question we're on (0-based)
var _is_finished: bool = false      # guards against double-completion


func _ready() -> void:
	_load_questions()
	if _questions.is_empty():
		# Nothing to ask — fail safe by completing immediately so we never trap
		# the player behind a broken/empty quiz.
		push_warning("Trivia has no questions; auto-completing.")
		_finish()
		return
	_show_question(0)


# -----------------------------------------------------------------------------
# _load_questions: read + parse the JSON data file into _questions.
# -----------------------------------------------------------------------------
# GODOT CONCEPT — reading a file + parsing JSON
#   FileAccess.open(...) opens a file; get_as_text() reads it all as a string.
#   JSON.parse_string(text) turns that text into Godot data (Dictionaries and
#   Arrays). We pull the "questions" array out of the top-level object.
func _load_questions() -> void:
	if not FileAccess.file_exists(trivia_data_path):
		push_error("Trivia data file not found: " + trivia_data_path)
		return

	var file: FileAccess = FileAccess.open(trivia_data_path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()

	# parse_string returns `null` if the JSON is malformed (e.g. a stray comma).
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed.has("questions"):
		push_error("Trivia JSON is invalid or missing a 'questions' list.")
		return

	_questions = parsed["questions"]


# -----------------------------------------------------------------------------
# _show_question: display question N and build a button for each answer.
# -----------------------------------------------------------------------------
func _show_question(index: int) -> void:
	_current_index = index
	var question_data: Dictionary = _questions[index]

	# Set the prompt text and a little "Question 2 of 3" progress line.
	_question_label.text = str(question_data.get("question", ""))
	_progress_label.text = "Question %d of %d" % [index + 1, _questions.size()]
	_feedback_label.text = ""   # clear any leftover correction from before

	_rebuild_answer_buttons(question_data.get("answers", []))


# Clears old answer buttons and makes one fresh Button per answer string.
func _rebuild_answer_buttons(answers: Array) -> void:
	# Remove any buttons left over from the previous question. queue_free()
	# schedules a node for safe deletion at the end of the frame.
	for child in _answers_box.get_children():
		child.queue_free()

	# Make a new button for each answer.
	for answer_index in answers.size():
		var button: Button = Button.new()
		button.text = str(answers[answer_index])

		# GODOT CONCEPT — "connect with bind"
		#   Button emits `pressed` with NO arguments. We want to know WHICH answer
		#   was clicked, so we bind the answer's index: .bind(answer_index) tacks
		#   that value on so our handler receives it. Each button thus reports its
		#   own index when pressed.
		button.pressed.connect(_on_answer_pressed.bind(answer_index))

		_answers_box.add_child(button)


# -----------------------------------------------------------------------------
# _on_answer_pressed: the heart of the gentle-retry rule.
# -----------------------------------------------------------------------------
func _on_answer_pressed(answer_index: int) -> void:
	var question_data: Dictionary = _questions[_current_index]
	var correct_index: int = int(question_data.get("correct_index", 0))

	if answer_index == correct_index:
		_handle_correct_answer(question_data)
	else:
		_handle_wrong_answer(question_data)


# Right answer: show the Weaver's warm confirmation ("reply") for a moment, then
# advance (or finish). The doc wants every correct answer to land as "a brick of
# who she is," so we pause briefly on the reply instead of jumping instantly.
func _handle_correct_answer(question_data: Dictionary) -> void:
	# Show the Weaver's reply line and grey out the buttons so it can't be
	# double-clicked during the pause.
	var reply: String = str(question_data.get("reply", ""))
	_feedback_label.text = reply
	AudioManager.play_one_shot(&"sfx.ui.trivia.correct", "UI")
	for child in _answers_box.get_children():
		child.disabled = true

	# GODOT CONCEPT — "await get_tree().create_timer(...).timeout"
	#   This pauses THIS function for a real-time delay without freezing the game,
	#   then resumes on the next line. We use it to let the reply linger ~1.4s.
	await get_tree().create_timer(1.4).timeout

	var is_last_question: bool = _current_index >= _questions.size() - 1
	if is_last_question:
		_finish()
	else:
		_show_question(_current_index + 1)


# Wrong answer: show the gentle correction and let the player try the SAME
# question again. We do NOT advance and we do NOT penalize — the buttons stay,
# so they just pick again.
func _handle_wrong_answer(question_data: Dictionary) -> void:
	var correction: String = str(question_data.get("correction", "Try again."))
	_feedback_label.text = correction
	AudioManager.play_one_shot(&"sfx.ui.trivia.wrong", "UI")


# -----------------------------------------------------------------------------
# _finish: the quiz is solved.
# -----------------------------------------------------------------------------
func _finish() -> void:
	if _is_finished:
		return            # only ever complete once
	_is_finished = true

	_question_label.text = "Solved!"
	_progress_label.text = ""
	_feedback_label.text = ""
	for child in _answers_box.get_children():
		child.queue_free()

	print("[Trivia] Completed.")
	AudioManager.play_one_shot(&"sfx.ui.trivia.complete", "UI")

	# 1) Tell anyone listening via the signal.
	trivia_completed.emit()

	# 2) If we're inside a Room, mark its puzzle complete automatically.
	var room: Room = _find_room()
	if room != null:
		room.mark_puzzle_complete()

	# Hide the trivia UI so the player is back in the room. (We hide rather than
	# free so the signal connection above isn't torn down mid-call.)
	hide()


# Walk up the parent chain to find the Room this trivia belongs to (same helper
# pattern as door.gd / goal_zone.gd).
func _find_room() -> Room:
	var node: Node = self
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
