extends CanvasLayer

const BUS_NAMES: Array[String] = ["Master", "Music", "Ambience", "SFX", "Dialogue", "UI"]

var _sliders: Dictionary = {}  # bus_name -> HSlider
var _labels: Dictionary = {}   # bus_name -> Label
var _is_collapsed: bool = false


func _ready() -> void:
	# Connect collapse button
	var collapse_btn: Button = $Control/MainVBox/Header/CollapseButton
	collapse_btn.pressed.connect(_toggle_collapse)
	
	var vbox: VBoxContainer = $Control/MainVBox/Content
	
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


func _toggle_collapse() -> void:
	_is_collapsed = not _is_collapsed
	var content_vbox: VBoxContainer = $Control/MainVBox/Content
	var collapse_btn: Button = $Control/MainVBox/Header/CollapseButton
	
	content_vbox.visible = not _is_collapsed
	collapse_btn.text = "▼ Audio" if not _is_collapsed else "▶ Audio"
