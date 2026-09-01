### Scene styling

Select the root `ResultScreen`:

```
Visible: Off
Mouse Filter: Stop
Ordering → Z Index: 200
```

Set `Dimmer`:

```
Color: #08100cdb
Mouse Filter: Stop
```

For `Panel → Theme Overrides → Styles → Panel`, create a `StyleBoxFlat`:

```
Background Color: #18231ff7
Border Color:     #31443b
Border Width:     3 on every side
Corner Radius:    0

Content Margin Left:   18
Content Margin Top:    16
Content Margin Right:  18
Content Margin Bottom: 16
```

Set `Content`, the internal `VBoxContainer`:

```
Alignment: Center
Theme Overrides → Constants → Separation: 10
```

Set the labels:

```
TitleLabel:
Font Size: 22
Horizontal Alignment: Center

MessageLabel:
Font Size: 12
Font Color: #f2e7c9
Horizontal Alignment: Center
Vertical Alignment: Center
Autowrap Mode: Word Smart
```

Set `RestartButton`:

```
Text: Return to Title
Custom Minimum Size Y: 30
Focus Mode: None
```

Reuse the main-menu button styles.

## Replace `result_screen.gd`

```
class_name ResultScreen
extends Control


signal restart_requested


@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var restart_button: Button = (
	$Panel/MarginContainer/Content/RestartButton
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)


var result_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 200

	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	hide()
	call_deferred("_apply_layout")


func show_result(
	title: String,
	message: String
) -> void:
	title_label.text = title
	message_label.text = message

	match title:
		"Victory":
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2d479")
			)

		"Defeat":
			title_label.add_theme_color_override(
				"font_color",
				Color("#e06c68")
			)

		_:
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2e7c9")
			)

	show()
	_apply_layout()
	_play_result_animation()


func _play_result_animation() -> void:
	if result_tween != null:
		result_tween.kill()

	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.88, 0.88)
	panel.pivot_offset = panel.size / 2.0

	result_tween = create_tween()
	result_tween.set_parallel(true)

	result_tween.tween_property(
		dimmer,
		"modulate:a",
		1.0,
		0.25
	)

	result_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.18
	)

	result_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _apply_layout() -> void:
	var viewport_size := (
		get_viewport().get_visible_rect().size
	)

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	dimmer.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	dimmer.position = Vector2.ZERO
	dimmer.size = viewport_size

	panel.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	panel.size = Vector2(420.0, 190.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		(viewport_size.y - panel.size.y) / 2.0
	)


func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func _on_restart_button_pressed() -> void:
	restart_button.disabled = true
	_play_ui_click()

	await get_tree().create_timer(
		0.09,
		true
	).timeout

	restart_requested.emit()
```

The screen now uses gold for victory, muted red for defeat, appears above every other interface layer, and returns to the newly created title menu when the scene reloads.