extends Node

const CUES_PATH: String = "res://data/audio_cues.json"
const FALLBACK_BUS: String = "Master"
const DIALOGUE_DUCK_DB: float = -12.0
const DIALOGUE_FADE_TIME: float = 0.2

var _cue_map: Dictionary = {}
var _duration_map: Dictionary = {}
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _one_shot_root: Node
var _voice_player: AudioStreamPlayer
var _current_music_cue: StringName = &""
var _current_ambience_cue: StringName = &""
var _active_one_shots: Dictionary = {}  # cue_id -> AudioStreamPlayer
var _music_pre_duck_volume: float = 0.0
var _ambience_pre_duck_volume: float = 0.0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = _resolve_bus("Music")
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = _resolve_bus("Ambience")
	add_child(_ambience_player)
	
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = _resolve_bus("Dialogue")
	add_child(_voice_player)

	_one_shot_root = Node.new()
	_one_shot_root.name = "OneShots"
	add_child(_one_shot_root)

	# Ensure all audio buses exist
	_ensure_bus("Music")
	_ensure_bus("Ambience")
	_ensure_bus("SFX")
	_ensure_bus("Dialogue")
	_ensure_bus("UI")
	
	# Set default bus volumes
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_index, -24.0)
	
	var ambience_bus_index: int = AudioServer.get_bus_index("Ambience")
	AudioServer.set_bus_volume_db(ambience_bus_index, -24.0)

	reload_cues()


func reload_cues() -> void:
	_cue_map.clear()
	_duration_map.clear()

	if not FileAccess.file_exists(CUES_PATH):
		push_warning("[AudioManager] Cue registry not found: %s" % CUES_PATH)
		return

	var file: FileAccess = FileAccess.open(CUES_PATH, FileAccess.READ)
	if file == null:
		push_warning("[AudioManager] Could not open cue registry: %s" % CUES_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[AudioManager] Cue registry JSON is not a dictionary.")
		return

	var cues: Variant = parsed.get("cues", {})
	if typeof(cues) != TYPE_DICTIONARY:
		push_warning("[AudioManager] Cue registry is missing a dictionary 'cues' object.")
		return

	for key in cues.keys():
		var cue_data: Variant = cues[key]
		
		# Support both simple string (path only) and object (path + metadata)
		var path_value: String = ""
		var duration: float = 0.0
		
		if typeof(cue_data) == TYPE_STRING:
			path_value = String(cue_data)
		elif typeof(cue_data) == TYPE_DICTIONARY:
			path_value = String(cue_data.get("path", ""))
			var duration_value: Variant = cue_data.get("duration", 0.0)
			if typeof(duration_value) in [TYPE_FLOAT, TYPE_INT]:
				duration = float(duration_value)
		
		if not path_value.is_empty():
			_cue_map[String(key)] = path_value
			if duration > 0.0:
				_duration_map[String(key)] = duration

	print("[AudioManager] Loaded cues: %d" % _cue_map.size())


func has_cue(cue_id: StringName) -> bool:
	return _cue_map.has(String(cue_id))


func play_music(cue_id: StringName, volume_db: float = 0.0, force_restart: bool = false) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false

	if not force_restart and _current_music_cue == cue_id and _music_player.playing:
		return true

	# Disconnect any previous finished signal
	if _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.disconnect(_on_music_finished)

	_music_player.bus = _resolve_bus("Music")
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	
	# Enable looping on the stream if supported
	_enable_stream_looping(stream)
	
	# Connect finished signal for manual looping fallback
	_music_player.finished.connect(_on_music_finished)
	
	_music_player.play()
	_current_music_cue = cue_id
	return true


func stop_music() -> void:
	_music_player.stop()
	_current_music_cue = &""


func play_ambience(cue_id: StringName, volume_db: float = 0.0, force_restart: bool = false) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false

	if not force_restart and _current_ambience_cue == cue_id and _ambience_player.playing:
		return true

	# Disconnect any previous finished signal
	if _ambience_player.finished.is_connected(_on_ambience_finished):
		_ambience_player.finished.disconnect(_on_ambience_finished)

	_ambience_player.bus = _resolve_bus("Ambience")
	_ambience_player.stop()
	_ambience_player.stream = stream
	_ambience_player.volume_db = volume_db
	
	# Enable looping on the stream if supported
	_enable_stream_looping(stream)
	
	# Connect finished signal for manual looping fallback
	_ambience_player.finished.connect(_on_ambience_finished)
	
	_ambience_player.play()
	_current_ambience_cue = cue_id
	return true


func stop_ambience() -> void:
	_ambience_player.stop()
	_current_ambience_cue = &""


func set_ambience_bus_volume(volume_db: float) -> void:
	var ambience_bus_index: int = AudioServer.get_bus_index("Ambience")
	if ambience_bus_index >= 0:
		AudioServer.set_bus_volume_db(ambience_bus_index, volume_db)


func play_one_shot(
	cue_id: StringName,
	bus_name: String = "SFX",
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false

	var cue_id_str: String = String(cue_id)
	
	# Stop any existing one-shot for this cue
	if _active_one_shots.has(cue_id_str):
		var existing_player: AudioStreamPlayer = _active_one_shots[cue_id_str]
		if is_instance_valid(existing_player):
			existing_player.stop()
			existing_player.queue_free()
		_active_one_shots.erase(cue_id_str)

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = _resolve_bus(bus_name)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	_one_shot_root.add_child(player)
	
	# Track this one-shot
	_active_one_shots[cue_id_str] = player
	
	# Handle cleanup when finished
	player.finished.connect(func() -> void:
		_active_one_shots.erase(cue_id_str)
		if is_instance_valid(player):
			player.queue_free()
	)
	
	# Auto-stop after specified duration if one is configured
	if _duration_map.has(cue_id_str):
		var duration: float = _duration_map[cue_id_str]
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			if is_instance_valid(player) and player.playing:
				player.stop()
		)
	
	player.play()
	return true


func play_voice(cue_id: StringName, volume_db: float = 0.0) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false
	
	_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.volume_db = volume_db
	_voice_player.play()
	return true


func stop_voice() -> void:
	_voice_player.stop()


func get_voice_finished_signal() -> Signal:
	return _voice_player.finished


func duck_for_dialogue() -> void:
	# Save current volumes and reduce music and ambience
	_music_pre_duck_volume = _music_player.volume_db
	_ambience_pre_duck_volume = _ambience_player.volume_db
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_music_player, "volume_db", _music_pre_duck_volume + DIALOGUE_DUCK_DB, DIALOGUE_FADE_TIME)
	tween.tween_property(_ambience_player, "volume_db", _ambience_pre_duck_volume + DIALOGUE_DUCK_DB, DIALOGUE_FADE_TIME)


func restore_from_dialogue() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_music_player, "volume_db", _music_pre_duck_volume, DIALOGUE_FADE_TIME)
	tween.tween_property(_ambience_player, "volume_db", _ambience_pre_duck_volume, DIALOGUE_FADE_TIME)


func _load_stream_for_cue(cue_id: String) -> AudioStream:
	if not _cue_map.has(cue_id):
		push_warning("[AudioManager] Missing cue id: %s" % cue_id)
		return null

	var stream_path: String = _cue_map[cue_id]
	var stream: Resource = load(stream_path)
	if stream == null or not (stream is AudioStream):
		push_warning("[AudioManager] Invalid stream at path: %s" % stream_path)
		return null

	return stream


func _enable_stream_looping(stream: AudioStream) -> void:
	# Try to enable looping on supported stream types
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop = true


func _on_music_finished() -> void:
	# Restart music if still the active cue (handles streams that don't support loop property)
	if _current_music_cue != &"" and is_instance_valid(_music_player) and _music_player.stream:
		_music_player.play()


func _on_ambience_finished() -> void:
	# Restart ambience if still the active cue (handles streams that don't support loop property)
	if _current_ambience_cue != &"" and is_instance_valid(_ambience_player) and _ambience_player.stream:
		_ambience_player.play()


func _resolve_bus(bus_name: String) -> String:
	if AudioServer.get_bus_index(bus_name) == -1:
		if AudioServer.get_bus_index(FALLBACK_BUS) == -1:
			return "Master"
		return FALLBACK_BUS
	return bus_name


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var bus_index: int = AudioServer.bus_count
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, bus_name)
