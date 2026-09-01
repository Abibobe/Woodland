### 1. Create the scene structure

Under `Interface`, add:

```
PauseMenu                     Control
├── Backdrop                  ColorRect
└── CenterContainer
    └── Panel                 PanelContainer
        └── MarginContainer
            └── VBoxContainer
                ├── TitleLabel
                ├── ResumeButton
                ├── AudioButton
                ├── HelpButton
                └── TitleButton
```

Configure `PauseMenu`:

```
Layout → Anchors Preset: Full Rect
Visible: Off
Process Mode: Always
Mouse Filter: Stop
Z Index: 75
```

Configure `Backdrop`:

```
Layout → Anchors Preset: Full Rect
Color: #08100cc0
Mouse Filter: Stop
```

Configure `CenterContainer`:

```
Layout → Anchors Preset: Full Rect
Mouse Filter: Ignore
```

Set the text:

```
TitleLabel:   PAUSED
ResumeButton: Resume
AudioButton:  Audio Settings
HelpButton:   How to Play
TitleButton:  Return to Title
```

Give each button:

```
Custom Minimum Size: 180 × 30
Focus Mode: None
```

Reuse the main-menu styles.

### 2. Expose the existing Help panel

In `main_menu.gd`, add:

```
func open_help_panel() -> void:
	if help_center.visible:
		return

	_open_help()
```

### 3. Create `pause_menu.gd`

Attach this script to `PauseMenu`:

```
class_name PauseMenu
extends Control


@export_category("Existing Menus")
@export var main_menu: MainMenu
@export var audio_settings_panel: AudioSettingsPanel
@export var help_center: CenterContainer
@export var result_screen: ResultScreen


@onready var resume_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/ResumeButton
)

@onready var audio_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/AudioButton
)

@onready var help_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/HelpButton
)

@onready var title_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/TitleButton
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(_resume_game)
	audio_button.pressed.connect(_open_audio_settings)
	help_button.pressed.connect(_open_help)
	title_button.pressed.connect(_return_to_title)

	hide()
```

### 4. Add Escape-key handling

```
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _is_another_modal_open():
		return

	if visible:
		_resume_game()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		return

	_open_pause_menu()
	get_viewport().set_input_as_handled()


func _is_another_modal_open() -> bool:
	if main_menu != null and main_menu.visible:
		return true

	if (
		audio_settings_panel != null
		and audio_settings_panel.visible
	):
		return true

	if help_center != null and help_center.visible:
		return true

	if (
		result_screen != null
		and result_screen.visible
	):
		return true

	return false
```

### 5. Add the menu actions

```
func _open_pause_menu() -> void:
	get_tree().paused = true
	show()


func _resume_game() -> void:
	_play_ui_click()
	hide()
	get_tree().paused = false


func _open_audio_settings() -> void:
	if audio_settings_panel != null:
		audio_settings_panel.open_panel()


func _open_help() -> void:
	if main_menu != null:
		main_menu.open_help_panel()


func _return_to_title() -> void:
	_set_buttons_disabled(true)
	_play_ui_click()

	await get_tree().create_timer(
		0.09,
		true
	).timeout

	get_tree().paused = false
	get_tree().reload_current_scene()
```

Add the helpers:

```
func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func _set_buttons_disabled(value: bool) -> void:
	resume_button.disabled = value
	audio_button.disabled = value
	help_button.disabled = value
	title_button.disabled = value
```

### 6. Assign the exported nodes

Select `PauseMenu` and assign:

```
Main Menu:            Interface/MainMenu
Audio Settings Panel: Interface/AudioSettingsPanel
Help Center:          Interface/HelpCenter
Result Screen:        Interface/ResultScreen
```

`Esc` will now pause and resume gameplay, while correctly ignoring input when the title screen, audio settings, help window, or result screen is active.

## Fix `pause_menu.gd`

In `_ready()`, connect the visibility signals:

```
func _ready() -> void:
	resume_button.pressed.connect(_resume_game)
	audio_button.pressed.connect(_open_audio_settings)
	help_button.pressed.connect(_open_help)
	title_button.pressed.connect(_return_to_title)

	audio_settings_panel.visibility_changed.connect(
		_on_secondary_panel_visibility_changed
	)

	help_center.visibility_changed.connect(
		_on_secondary_panel_visibility_changed
	)
```

If your existing `_ready()` already connects the buttons, only add the two `visibility_changed` connections.

Replace the audio and help functions with:

```
func _open_audio_settings() -> void:
	_play_ui_click()

	hide()
	audio_settings_panel.open_panel()


func _open_help() -> void:
	_play_ui_click()

	hide()
	main_menu.open_help_panel()
```

Then add:

```
func _on_secondary_panel_visibility_changed() -> void:
	call_deferred("_restore_after_secondary_panel")


func _restore_after_secondary_panel() -> void:
	if audio_settings_panel.visible:
		return

	if help_center.visible:
		return

	if not get_tree().paused:
		return

	show()
	resume_button.grab_focus()
```

Finally, make sure opening the pause menu restores it properly:

```
func _open_pause_menu() -> void:
	get_tree().paused = true

	show()
	resume_button.grab_focus()
```

Now the behavior will be:

- Pause menu opens.
- Clicking **Audio Settings** hides the pause menu.
- Audio controls receive mouse input normally.
- Closing Audio Settings restores the pause menu.
- The same behavior applies to **How to Play**.
- The game remains paused throughout.