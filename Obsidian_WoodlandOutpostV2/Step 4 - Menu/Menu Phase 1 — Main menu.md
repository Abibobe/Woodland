Let’s begin the next polish milestone: a proper title menu using the same pixel UI style. It will pause the
### 1. Create the menu structure

Under `Interface`, add:

```text
MainMenu                         Control
├── Background                  ColorRect
└── CenterContainer
    └── MenuPanel               PanelContainer
        └── MarginContainer
            └── VBoxContainer
                ├── TitleLabel
                ├── SubtitleLabel
                ├── StartButton
                ├── AudioButton
                └── QuitButton
```

Configure `MainMenu`:

```text
Layout → Anchors Preset: Full Rect
Process Mode: Always
Mouse Filter: Stop
```

Configure `Background`:

```text
Layout → Anchors Preset: Full Rect
Color: #08100cc0
Mouse Filter: Stop
```

Configure `CenterContainer`:

```text
Layout → Anchors Preset: Full Rect
```

### 2. Configure the content

Use:

```text
TitleLabel:    WOODLAND OUTPOST
SubtitleLabel: Survive. Gather. Build.

StartButton:   Start Game
AudioButton:   Audio Settings
QuitButton:    Quit
```

For the title:

```text
Font Size: 24
Font Color: #f2d479
Horizontal Alignment: Center
```

For the subtitle:

```text
Font Size: 11
Font Color: #b9c8b5
Horizontal Alignment: Center
```

Give each button:

```text
Custom Minimum Size: 180 × 30
```

Reuse the Audio button’s square normal, hover, pressed, and focus styles.

### 3. Style the menu panel

Create a `StyleBoxFlat` for `MenuPanel`:

```text
Background Color: #18231ff2
Border Color:     #0d1510
Border Width:     3 on every side
Corner Radius:    0
```

Set the internal margins to:

```text
Left:   18
Top:    16
Right:  18
Bottom: 16
```

Set the `VBoxContainer` separation to `8`.

### 4. Expose the audio panel publicly

In `audio_settings_panel.gd`, add:

```gdscript
func open_panel() -> void:
	if visible:
		return

	_open_panel()
```

### 5. Create the menu script

Attach this to `MainMenu`:

```text
res://scripts/ui/main_menu.gd
```

```gdscript
class_name MainMenu
extends Control


@export var audio_settings_panel: AudioSettingsPanel


@onready var start_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/StartButton
)

@onready var audio_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/AudioButton
)

@onready var quit_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/QuitButton
)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	start_button.pressed.connect(_start_game)
	audio_button.pressed.connect(_open_audio_settings)
	quit_button.pressed.connect(_quit_game)

	start_button.grab_focus()


func _start_game() -> void:
	hide()
	get_tree().paused = false


func _open_audio_settings() -> void:
	if audio_settings_panel != null:
		audio_settings_panel.open_panel()


func _quit_game() -> void:
	get_tree().quit()
```

### 6. Assign the audio panel

Select `MainMenu` and drag the existing:

```text
Interface/AudioSettingsPanel
```

into its exported `Audio Settings Panel` field.

When the scene starts, the generated world remains visible beneath the dark overlay, but player movement and the day cycle remain paused until **Start Game** is pressed.


FIX::: Audio settings menu showed under the main menu

That is a drawing-order issue. `MainMenu` is probably later in the scene tree, so it renders over the audio panel.

Set explicit UI Z indexes:

```
MainMenu
Ordering → Z Index: 50
```

```
AudioSettingsBackdrop
Ordering → Z Index: 100
```

```
AudioSettingsPanel
Ordering → Z Index: 101
```

Keep all three as direct children of `Interface`:

```
Interface
├── MainMenu
├── AudioSettingsBackdrop
└── AudioSettingsPanel
```

The scene-tree order no longer matters because the Z indexes define the layers:

```
Game UI          Z 0
Main menu        Z 50
Audio backdrop   Z 100
Audio panel      Z 101
```

Now Audio Settings will appear above the main menu. Closing it restores the still-paused main menu because `previous_pause_state` was already `true`, which is exactly the desired behavior.

The Z index fixed drawing, but Godot’s `Control` mouse routing also depends on scene-tree order. The main menu is likely still receiving input first.

## 1. Reorder the actual nodes

Under `Interface`, physically arrange them in this order:

```
Interface
├── MainMenu
├── AudioSettingsBackdrop
└── AudioSettingsPanel
```

Drag the nodes in the scene tree if necessary. `AudioSettingsPanel` must be the last of these siblings.

Keep the Z indexes:

```
MainMenu:                 50
AudioSettingsBackdrop:   100
AudioSettingsPanel:      101
```

## 2. Check mouse filters

Set:

```
AudioSettingsPanel
Mouse → Filter: Stop
```

```
AudioSettingsBackdrop
Mouse → Filter: Stop
```

The backdrop must cover the entire viewport:

```
Layout → Anchors Preset: Full Rect
Offset Left/Top/Right/Bottom: 0
```

Set decorative elements inside the main menu, such as labels, to:

```
Mouse → Filter: Ignore
```

Buttons should remain `Stop`.

## 3. Disable main-menu buttons while settings are open

For a completely robust fix, add a signal to `audio_settings_panel.gd`:

```
signal panel_closed
```

At the end of `_finish_closing_panel()`:

```
panel_closed.emit()
```

In `main_menu.gd`, update `_ready()`:

```
if audio_settings_panel != null:
	audio_settings_panel.panel_closed.connect(
		_on_audio_settings_closed
	)
```

Replace `_open_audio_settings()` with:

```
func _open_audio_settings() -> void:
	if audio_settings_panel == null:
		return

	_set_buttons_disabled(true)
	audio_settings_panel.open_panel()
```

Add:

```
func _on_audio_settings_closed() -> void:
	_set_buttons_disabled(false)
	audio_button.grab_focus()


func _set_buttons_disabled(value: bool) -> void:
	start_button.disabled = value
	audio_button.disabled = value
	quit_button.disabled = value
```

Now the main menu cannot react while Audio Settings is open, and its buttons reactivate when the panel finishes closing.

--> The focus stay on the Main Menu Buttons: 

After clicking, Godot keeps keyboard focus on that button until another control receives it.

For a mouse-first menu, select these buttons:

```
StartButton
AudioButton
QuitButton
```

Set:

```
Focus → Mode: None
```

Also remove these lines from `main_menu.gd`:

```
start_button.grab_focus()
```

and:

```
audio_button.grab_focus()
```

The second one is inside `_on_audio_settings_closed()`.

That function can become:

```
func _on_audio_settings_closed() -> void:
	_set_buttons_disabled(false)
```

Now the hover border disappears as soon as the cursor leaves, and clicking a button won’t leave it permanently highlighted.

Keep focus enabled on the audio sliders if you want arrow-key adjustment. Only the menu buttons need `Focus Mode: None`.