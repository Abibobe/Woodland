class_name AudioSettingsPanel
extends PanelContainer

const SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SECTION := "audio"

var is_loading_settings: bool = false

@export_category("Opening")
@export var open_button: Button


@onready var master_slider: HSlider = (
	$MarginContainer/VBoxContainer/MasterSlider
)

@onready var effects_slider: HSlider = (
	$MarginContainer/VBoxContainer/EffectsSlider
)

@onready var ambience_slider: HSlider = (
	$MarginContainer/VBoxContainer/AmbienceSlider
)

@onready var close_button: Button = (
	$MarginContainer/VBoxContainer/CloseButton
)

@onready var backdrop: ColorRect = (
	$"../AudioSettingsBackdrop"
)

@onready var master_value_label: Label = (
	$MarginContainer/VBoxContainer/
	MasterHeader/MasterValueLabel
)

@onready var effects_value_label: Label = (
	$MarginContainer/VBoxContainer/
	EffectsHeader/EffectsValueLabel
)

@onready var ambience_value_label: Label = (
	$MarginContainer/VBoxContainer/
	AmbienceHeader/AmbienceValueLabel
)

@onready var reset_button: Button = (
	$MarginContainer/VBoxContainer/ResetButton
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)

@onready var fullscreen_button: DisplayModeButton = (
	$MarginContainer/VBoxContainer/FullscreenButton
)

@onready var vsync_button: VSyncButton = (
	$MarginContainer/VBoxContainer/VSyncButton
)



signal panel_closed


var previous_pause_state: bool = false
var panel_tween: Tween

func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	z_as_relative = false
	z_index = 101

	backdrop.z_as_relative = false
	backdrop.z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if open_button != null:
		open_button.pressed.connect(_toggle_panel)

	close_button.pressed.connect(_close_panel)

	master_slider.value_changed.connect(
		_on_master_changed
	)

	effects_slider.value_changed.connect(
		_on_effects_changed
	)

	ambience_slider.value_changed.connect(
		_on_ambience_changed
	)
	reset_button.pressed.connect(
		_reset_audio_settings
	)
	
	_load_audio_settings()

func _toggle_panel() -> void:
	if visible:
		_close_panel()
	else:
		_open_panel()


func _sync_sliders() -> void:
	master_slider.value = _get_bus_linear("Master")
	effects_slider.value = _get_bus_linear("SFX")
	ambience_slider.value = _get_bus_linear("Ambience")


func _get_bus_linear(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		return 1.0

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)



func _set_bus_linear(
	bus_name: StringName,
	value: float
) -> void:
	var bus_index := AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		return

	var should_mute := value <= 0.001

	AudioServer.set_bus_mute(
		bus_index,
		should_mute
	)

	if not should_mute:
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(value)
		)

func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(SETTINGS_PATH)

	is_loading_settings = true

	if load_result == OK:
		master_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"master",
				_get_bus_linear("Master")
			)
		)

		effects_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"effects",
				_get_bus_linear("SFX")
			)
		)

		ambience_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"ambience",
				_get_bus_linear("Ambience")
			)
		)
	else:
		_sync_sliders()

	is_loading_settings = false
	_update_value_labels()


func _save_audio_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(
		AUDIO_SECTION,
		"master",
		master_slider.value
	)

	config.set_value(
		AUDIO_SECTION,
		"effects",
		effects_slider.value
	)

	config.set_value(
		AUDIO_SECTION,
		"ambience",
		ambience_slider.value
	)

	var save_result := config.save(SETTINGS_PATH)

	if save_result != OK:
		push_warning(
			"Could not save audio settings: %s"
			% save_result
		)


func _on_master_changed(value: float) -> void:
	_set_bus_linear("Master", value)
	_update_value_labels()
	if not is_loading_settings:
		_save_audio_settings()


func _on_effects_changed(value: float) -> void:
	_set_bus_linear("SFX", value)
	_set_bus_linear("UI", value)
	_update_value_labels()

	if not is_loading_settings:
		_save_audio_settings()


func _on_ambience_changed(value: float) -> void:
	_set_bus_linear("Ambience", value)
	_update_value_labels()
	if not is_loading_settings:
		_save_audio_settings()


func _open_panel() -> void:
	previous_pause_state = get_tree().paused
	get_tree().paused = true

	if panel_tween != null:
		panel_tween.kill()

	backdrop.modulate.a = 0.0
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	pivot_offset = size / 2.0

	backdrop.show()
	show()

	panel_tween = create_tween()
	panel_tween.set_parallel(true)

	panel_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.14
	)

	panel_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.14
	)

	panel_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
	_play_ui_click()



func _close_panel() -> void:
	_play_ui_click()
	if not visible:
		return

	if panel_tween != null:
		panel_tween.kill()

	panel_tween = create_tween()
	panel_tween.set_parallel(true)

	panel_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	panel_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.1
	)

	panel_tween.tween_property(
		self,
		"scale",
		Vector2(0.94, 0.94),
		0.12
	)

	panel_tween.set_parallel(false)

	panel_tween.tween_callback(
		_finish_closing_panel
	)



func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_close_panel()
		get_viewport().set_input_as_handled()


func _finish_closing_panel() -> void:
	hide()
	backdrop.hide()

	scale = Vector2.ONE
	modulate.a = 1.0
	backdrop.modulate.a = 1.0

	get_tree().paused = previous_pause_state
	panel_closed.emit()


func _update_value_labels() -> void:
	master_value_label.text = "%d%%" % roundi(
		master_slider.value * 100.0
	)

	effects_value_label.text = "%d%%" % roundi(
		effects_slider.value * 100.0
	)

	ambience_value_label.text = "%d%%" % roundi(
		ambience_slider.value * 100.0
	)


func _reset_audio_settings() -> void:
	_play_ui_click()

	is_loading_settings = true

	master_slider.value = 1.0
	effects_slider.value = 0.8
	ambience_slider.value = 0.7

	is_loading_settings = false

	_update_value_labels()
	_save_audio_settings()

	fullscreen_button.reset_to_default()
	vsync_button.reset_to_default()



func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func open_panel() -> void:
	if visible:
		return

	_open_panel()
