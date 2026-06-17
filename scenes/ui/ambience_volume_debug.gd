extends CanvasLayer

@onready var _slider: HSlider = $Control/VBox/Slider
@onready var _label: Label = $Control/VBox/Label


func _ready() -> void:
	# Set slider range: -30 to 0 dB
	_slider.min_value = -30.0
	_slider.max_value = 0.0
	_slider.step = 1.0
	
	# Get current ambience bus volume and set slider
	var ambience_bus_index: int = AudioServer.get_bus_index("Ambience")
	if ambience_bus_index >= 0:
		_slider.value = AudioServer.get_bus_volume_db(ambience_bus_index)
	
	_slider.value_changed.connect(_on_slider_changed)
	_update_label()


func _on_slider_changed(value: float) -> void:
	var ambience_bus_index: int = AudioServer.get_bus_index("Ambience")
	if ambience_bus_index >= 0:
		AudioServer.set_bus_volume_db(ambience_bus_index, value)
	_update_label()


func _update_label() -> void:
	_label.text = "Ambience Volume: %.1f dB" % _slider.value
