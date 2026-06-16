extends Node

const CUES_PATH: String = "res://data/audio_cues.json"
const FALLBACK_BUS: String = "Master"

var _cue_map: Dictionary = {}
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _one_shot_root: Node
var _current_music_cue: StringName = &""
var _current_ambience_cue: StringName = &""


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = _resolve_bus("Music")
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = _resolve_bus("Ambience")
	add_child(_ambience_player)

	_one_shot_root = Node.new()
	_one_shot_root.name = "OneShots"
	add_child(_one_shot_root)

	reload_cues()


func reload_cues() -> void:
	_cue_map.clear()

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
		var path_value: Variant = cues[key]
		if typeof(path_value) == TYPE_STRING and not String(path_value).is_empty():
			_cue_map[String(key)] = String(path_value)

	print("[AudioManager] Loaded cues: %d" % _cue_map.size())


func has_cue(cue_id: StringName) -> bool:
	return _cue_map.has(String(cue_id))


func play_music(cue_id: StringName, volume_db: float = 0.0, force_restart: bool = false) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false

	if not force_restart and _current_music_cue == cue_id and _music_player.playing:
		return true

	_music_player.bus = _resolve_bus("Music")
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
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

	_ambience_player.bus = _resolve_bus("Ambience")
	_ambience_player.stop()
	_ambience_player.stream = stream
	_ambience_player.volume_db = volume_db
	_ambience_player.play()
	_current_ambience_cue = cue_id
	return true


func stop_ambience() -> void:
	_ambience_player.stop()
	_current_ambience_cue = &""


func play_one_shot(
	cue_id: StringName,
	bus_name: String = "SFX",
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> bool:
	var stream: AudioStream = _load_stream_for_cue(String(cue_id))
	if stream == null:
		return false

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = _resolve_bus(bus_name)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	_one_shot_root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return true


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


func _resolve_bus(bus_name: String) -> String:
	if AudioServer.get_bus_index(bus_name) == -1:
		if AudioServer.get_bus_index(FALLBACK_BUS) == -1:
			return "Master"
		return FALLBACK_BUS
	return bus_name
