extends CanvasLayer

const BUS_NAMES: Array[String] = ["Master", "Music", "Ambience", "SFX", "Dialogue", "UI"]

var _sliders: Dictionary = {}  # bus_name -> HSlider
var _labels: Dictionary = {}   # bus_name -> Label
var _audio_collapsed: bool = false
var _text_collapsed: bool = false
var _font_size_label: Label
var _font_size_slider: HSlider


func _ready() -> void:
	# Connect audio collapse button
	var audio_collapse_btn: Button = $Control/MainVBox/AudioSection/AudioVBox/AudioHeader/AudioCollapseButton
	audio_collapse_btn.pressed.connect(_toggle_audio_collapse)
	
	# Connect text collapse button
	var text_collapse_btn: Button = $Control/MainVBox/TextSection/TextVBox/TextHeader/TextCollapseButton
	text_collapse_btn.pressed.connect(_toggle_text_collapse)
	
	var vbox: VBoxContainer = $Control/MainVBox/AudioSection/AudioVBox/AudioContent
	
	for bus_name in BUS_NAMES:
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		
		var current_volume: float = AudioServer.get_bus_volume_db(bus_index)
		
		# Create label with actual volume
		var label: Label = Label.new()
		label.text = "%s: %.1f dB" % [bus_name, current_volume]
		vbox.add_child(label)
		_labels[bus_name] = label
		
		# Create slider
		var slider: HSlider = HSlider.new()
		slider.min_value = -60.0
		slider.max_value = 0.0
		slider.step = 1.0
		slider.value = current_volume
		slider.value_changed.connect(_on_slider_changed.bind(bus_name))
		vbox.add_child(slider)
		_sliders[bus_name] = slider
	
	# Setup text/font controls
	_setup_text_controls()


func _on_slider_changed(value: float, bus_name: String) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, value)
	_labels[bus_name].text = "%s: %.1f dB" % [bus_name, value]


func _setup_text_controls() -> void:
	var text_vbox: VBoxContainer = $Control/MainVBox/TextSection/TextVBox/TextContent
	
	# Font size label
	_font_size_label = Label.new()
	_font_size_label.text = "Font Size: 24"
	text_vbox.add_child(_font_size_label)
	
	# Font size slider
	_font_size_slider = HSlider.new()
	_font_size_slider.min_value = 12.0
	_font_size_slider.max_value = 48.0
	_font_size_slider.step = 1.0
	_font_size_slider.value = 24.0
	_font_size_slider.value_changed.connect(_on_font_size_changed)
	text_vbox.add_child(_font_size_slider)


func _on_font_size_changed(value: float) -> void:
	_font_size_label.text = "Font Size: %.0f" % value
	# Apply font size to dialogue labels in the scene tree
	_apply_font_size_to_dialogue(int(value))


func _apply_font_size_to_dialogue(font_size: int) -> void:
	# Find all dialogue labels and update their font size
	var root = get_tree().root
	_update_label_font_sizes(root, font_size)


func _update_label_font_sizes(node: Node, font_size: int) -> void:
	if node is Label:
		if node.label_settings == null:
			node.label_settings = LabelSettings.new()
		node.label_settings.font_sizes[TextServer.HORIZONTAL_ALIGNMENT_LEFT] = font_size
	
	for child in node.get_children():
		_update_label_font_sizes(child, font_size)


func _toggle_audio_collapse() -> void:
	_audio_collapsed = not _audio_collapsed
	var audio_content: VBoxContainer = $Control/MainVBox/AudioSection/AudioVBox/AudioContent
	var audio_btn: Button = $Control/MainVBox/AudioSection/AudioVBox/AudioHeader/AudioCollapseButton
	
	audio_content.visible = not _audio_collapsed
	audio_btn.text = "▼ Audio" if not _audio_collapsed else "▶ Audio"


func _toggle_text_collapse() -> void:
	_text_collapsed = not _text_collapsed
	var text_content: VBoxContainer = $Control/MainVBox/TextSection/TextVBox/TextContent
	var text_btn: Button = $Control/MainVBox/TextSection/TextVBox/TextHeader/TextCollapseButton
	
	text_content.visible = not _text_collapsed
	text_btn.text = "▼ Text" if not _text_collapsed else "▶ Text"
