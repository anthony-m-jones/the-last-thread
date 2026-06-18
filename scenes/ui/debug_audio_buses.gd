extends CanvasLayer

const BUS_NAMES: Array[String] = ["Master", "Music", "Ambience", "SFX", "Dialogue", "UI"]

var _sliders: Dictionary = {}  # bus_name -> HSlider
var _labels: Dictionary = {}   # bus_name -> Label
var _audio_collapsed: bool = false


func _ready() -> void:
	# Connect audio collapse button
	var audio_collapse_btn: Button = $Control/MainVBox/AudioSection/AudioVBox/AudioHeader/AudioCollapseButton
	audio_collapse_btn.pressed.connect(_toggle_audio_collapse)
	
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
	

func _on_slider_changed(value: float, bus_name: String) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, value)
	_labels[bus_name].text = "%s: %.1f dB" % [bus_name, value]


func _toggle_audio_collapse() -> void:
	_audio_collapsed = not _audio_collapsed
	var audio_content: VBoxContainer = $Control/MainVBox/AudioSection/AudioVBox/AudioContent
	var audio_btn: Button = $Control/MainVBox/AudioSection/AudioVBox/AudioHeader/AudioCollapseButton
	
	audio_content.visible = not _audio_collapsed
	audio_btn.text = "▼ Audio" if not _audio_collapsed else "▶ Audio"



