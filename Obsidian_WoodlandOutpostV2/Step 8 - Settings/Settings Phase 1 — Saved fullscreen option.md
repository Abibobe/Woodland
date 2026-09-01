
We can add fullscreen without complicating the existing audio code by giving the fullscreen button its own small script.

### 1. Add the display section

Inside the Audio Settings panel’s `VBoxContainer`, add:

```
DisplayTitle
FullscreenButton
```

Place them after the ambience controls and before Reset/Close.

Configure:

```
DisplayTitle
    Type: Label
    Text: DISPLAY
    Font Color: #f2d16b
    Font Size: 12

FullscreenButton
    Type: Button
    Text: Fullscreen: Off
    Toggle Mode: On
    Focus Mode: All
```

Apply the same pixel-style button theme used by the other menu buttons.

You may also rename the panel’s main title:

```
AUDIO SETTINGS
```

to:

```
SETTINGS
```

And rename the menu buttons from:

```
Audio Settings
```

to:

```
Settings
```

The existing node names can remain unchanged, so no script paths need to change.

## 2. Create `display_mode_button.gd`

Attach this script directly to `FullscreenButton`:

```
class_name DisplayModeButton
extends Button


const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const FULLSCREEN_KEY := "fullscreen"


func _ready() -> void:
	toggle_mode = true

	toggled.connect(
		_on_fullscreen_toggled
	)

	_load_setting()


func _load_setting() -> void:
	var config := ConfigFile.new()
	var fullscreen_enabled := false

	if config.load(CONFIG_PATH) == OK:
		fullscreen_enabled = bool(
			config.get_value(
				CONFIG_SECTION,
				FULLSCREEN_KEY,
				false
			)
		)

	set_pressed_no_signal(
		fullscreen_enabled
	)

	_apply_display_mode(
		fullscreen_enabled
	)

	_update_button_text(
		fullscreen_enabled
	)


func _on_fullscreen_toggled(
	enabled: bool
) -> void:
	_apply_display_mode(enabled)
	_update_button_text(enabled)
	_save_setting(enabled)


func _apply_display_mode(
	fullscreen_enabled: bool
) -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


func _update_button_text(
	fullscreen_enabled: bool
) -> void:
	if fullscreen_enabled:
		text = "Fullscreen: On"
	else:
		text = "Fullscreen: Off"


func _save_setting(
	fullscreen_enabled: bool
) -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(
		CONFIG_SECTION,
		FULLSCREEN_KEY,
		fullscreen_enabled
	)

	config.save(CONFIG_PATH)
```

### 3. Prevent the selected style from lingering

Because this is a toggle button, Godot normally keeps its pressed appearance while fullscreen is enabled. For this particular button, that behavior is meaningful—but if you prefer the normal pixel-button appearance, assign the same `StyleBox` to:

```
Theme Overrides → Styles
├── Normal
└── Pressed
```

The text will still clearly display `On` or `Off`.

### 4. Test outside the embedded game window

Godot’s embedded game view may not visibly switch to fullscreen.

To test correctly:

1. Open the editor’s three-dot game menu.
2. Disable **Embed Game on Play**, or enable **Make Game Workspace Floating** depending on your Godot version.
3. Run the project.
4. Open **Settings** and select **Fullscreen**.
5. Restart the project and verify that the selection is remembered.

The setting is saved at:

```
user://display_settings.cfg
```

FIX::

The MainMenu’s full-screen `Control` is probably still intercepting mouse events while the Settings panel is displayed. We’ll explicitly disable its mouse handling while Settings is open.

In `main_menu.gd`, find the function that opens Audio Settings/Settings. Add:

```
func _open_audio_settings() -> void:
	_play_ui_click()

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_menu_buttons_disabled(true)

	audio_settings_panel.open_panel()
```

Use your existing function name if it differs.

Then ensure the Settings visibility signal is connected in `_ready()`:

```
audio_settings_panel.visibility_changed.connect(
	_on_settings_visibility_changed
)
```

Add:

```
func _on_settings_visibility_changed() -> void:
	if audio_settings_panel.visible:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_menu_buttons_disabled(true)
		return

	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_menu_buttons_disabled(false)

	audio_button.grab_focus()
```

Your button-disabling function should include all main-menu buttons:

```
func _set_menu_buttons_disabled(value: bool) -> void:
	start_button.disabled = value
	help_button.disabled = value
	audio_button.disabled = value
	quit_button.disabled = value
```

Also verify these Inspector settings:

```
MainMenu
└── Ordering → Z Index: 50

AudioSettingsBackdrop
├── Mouse Filter: Stop
└── Ordering → Z Index: 100

AudioSettingsPanel
├── Mouse Filter: Stop
├── Process Mode: Always
└── Ordering → Z Index: 101
```

For the controls inside `AudioSettingsPanel`, use:

```
Sliders → Mouse Filter: Stop
Buttons → Mouse Filter: Stop
Labels → Mouse Filter: Ignore
```

Setting labels to `Ignore` prevents decorative text from catching clicks intended for nearby controls.

One final check: if you renamed the node from `AudioButton` to `SettingsButton`, update its script path accordingly—or rename the node back to `AudioButton` and change only its displayed text to `Settings`. This avoids breaking existing `$.../AudioButton` references.

I found the concrete problem in the scripts: the Settings button may be connected twice.

`MainMenu` connects it here:

```
audio_button.pressed.connect(_open_audio_settings)
```

But `AudioSettingsPanel` can connect the same button again through its exported `Open Button`. One click may therefore open and immediately toggle/close the panel.

## 1. Clear the duplicate connection

Select:

```
Interface/AudioSettingsPanel
```

In the Inspector, find:

```
Opening → Open Button
```

Clear that field so it displays:

```
<empty>
```

`MainMenu` already opens the panel, so `AudioSettingsPanel` does not need that reference.

## 2. Remove the incomplete visibility connection

Your `main_menu.gd` connects this function:

```
audio_settings_panel.visibility_changed.connect(
	_on_settings_visibility_changed
)
```

But `_on_settings_visibility_changed()` does not exist in the uploaded script.

Delete that entire connection. You already have the cleaner signal:

```
audio_settings_panel.panel_closed.connect(
	_on_audio_settings_closed
)
```

## 3. Restore mouse input when Settings closes

Replace `_on_audio_settings_closed()` with:

```
func _on_audio_settings_closed() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_buttons_disabled(false)
	audio_button.grab_focus()
```

Keep `_open_audio_settings()` as:

```
func _open_audio_settings() -> void:
	_play_ui_click()

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_buttons_disabled(true)

	audio_settings_panel.open_panel()
```

## 4. Correct the visual/input order

Your screenshot shows `MainMenu` after `AudioSettingsPanel` in the scene tree. Therefore explicit Z indices are essential.

Set:

```
MainMenu
└── Ordering → Z Index: 50

AudioSettingsBackdrop
└── Ordering → Z Index: 100

AudioSettingsPanel
├── Ordering → Z Index: 101
└── Process → Mode: Always
```

Also set:

```
AudioSettingsBackdrop → Mouse Filter: Stop
AudioSettingsPanel → Mouse Filter: Stop
```

The important fixes are clearing `Open Button` and removing the nonexistent visibility callback. After saving, stop the running game completely and launch it again. The Settings button should open the panel once, and its sliders, fullscreen control, reset, and close buttons should all receive clicks normally.

## Definitive fix

At the very beginning of `_ready()` in `audio_settings_panel.gd`, add:

```
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	if open_button != null:
		open_button.pressed.connect(_toggle_panel)

	# Keep the remainder of your existing _ready() here.
```

Your complete beginning should therefore resemble:

```
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
```

The script setting guarantees the correct process mode even if the Inspector value was missed.

Also select these children and leave their process mode as `Inherit`:

```
AudioSettingsPanel
├── MarginContainer
│   └── VBoxContainer
│       ├── MasterSlider
│       ├── EffectsSlider
│       ├── AmbienceSlider
│       ├── FullscreenButton
│       ├── ResetButton
│       └── CloseButton
```

They will inherit `Always` from `AudioSettingsPanel`.

Keep:

```
AudioSettingsPanel → Mouse Filter: Stop
Labels → Mouse Filter: Ignore
```

Stop the project completely and run it again. The panel was visually opening while its processing was frozen; setting `PROCESS_MODE_ALWAYS` directly in its script resolves that exact behavior.

The screenshot also shows the main-menu panel behind Settings. We can hide only that panel while keeping the `MainMenu` root visible, which avoids triggering the tutorial.

## Replace `_open_audio_settings()`

In `main_menu.gd`:

```
func _open_audio_settings() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	menu_panel.hide()

	audio_settings_panel.open_panel()
```

Do not call `hide()` on the complete `MainMenu`, because that could trigger the first-launch tutorial.

## Replace `_on_audio_settings_closed()`

```
func _on_audio_settings_closed() -> void:
	menu_panel.show()
	menu_panel.modulate.a = 1.0
	menu_panel.scale = Vector2.ONE

	_set_buttons_disabled(false)
	audio_button.grab_focus()
```

You can now remove these mouse-filter changes from `main_menu.gd`:

```
mouse_filter = Control.MOUSE_FILTER_IGNORE
```

and:

```
mouse_filter = Control.MOUSE_FILTER_STOP
```

They are no longer necessary.

## Force Settings above everything

At the beginning of `AudioSettingsPanel._ready()`, keep `PROCESS_MODE_ALWAYS` and add explicit ordering:

```
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_as_relative = false
	z_index = 101

	backdrop.z_as_relative = false
	backdrop.z_index = 100

	mouse_filter = Control.MOUSE_FILTER_STOP

	# Keep the existing connections below.
```

The key fix is `menu_panel.hide()`. It removes all its child controls from Godot’s GUI hit-testing while Settings is open, but keeps `MainMenu.visible == true`, so the tutorial will not mistakenly start.

After closing Settings, the main-menu panel is shown again and its buttons are restored.