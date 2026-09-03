The next useful addition is a pixel-styled **How to Play** panel showing movement, interaction, construction, food consumption, and the winter objective.

### 1. Add the main-menu button

Inside the main menu’s `VBoxContainer`, add a button between Audio and Quit:

```
HowToPlayButton
```

Configure:

```
Text: How to Play
Custom Minimum Size: 180 × 30
Focus Mode: None
```

Reuse the other menu-button styles.

### 2. Add the help overlay

Under `Interface`, add:

```
HelpBackdrop                 ColorRect
HelpPanel                    PanelContainer
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        ├── MoveLabel
        ├── InteractLabel
        ├── ResourcesLabel
        ├── CampLabel
        ├── SurvivalLabel
        └── CloseButton
```

Configure both roots:

```
Visible: Off
Process Mode: Always
```

For `HelpBackdrop`:

```
Layout → Anchors Preset: Full Rect
Color: #08100c80
Mouse Filter: Stop
Z Index: 100
```

For `HelpPanel`:

```
Layout → Anchors Preset: Center
Offsets: Left -170, Top -125, Right 170, Bottom 125
Mouse Filter: Stop
Z Index: 101
```

Use the same panel style as Audio Settings.

### 3. Add the help text

```
TitleLabel:
HOW TO PLAY

MoveLabel:
WASD / Arrow Keys — Move

InteractLabel:
E — Gather or interact

ResourcesLabel:
Gather wood, stone, and food.

CampLabel:
Use resources at the camp to build
the campfire, foundation, and cabin.

SurvivalLabel:
One food is consumed each day.
Complete the cabin before winter.
```

Style:

```
Title: 16 px, #f2d479, centred
Body:  12 px, #f2e7c9
```

Set `CloseButton` to:

```
Text: Close
Focus Mode: None
```

### 4. Add references to `main_menu.gd`

```
@onready var how_to_play_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/HowToPlayButton
)

@onready var help_backdrop: ColorRect = (
	$"../HelpBackdrop"
)

@onready var help_panel: PanelContainer = (
	$"../HelpPanel"
)

@onready var help_close_button: Button = (
	$"../HelpPanel/MarginContainer/VBoxContainer/CloseButton"
)
```

### 5. Connect the controls

Inside `_ready()`:

```
how_to_play_button.pressed.connect(
	_open_help
)

help_close_button.pressed.connect(
	_close_help
)
```

Add:

```
func _open_help() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	help_backdrop.show()
	help_panel.show()


func _close_help() -> void:
	if not help_panel.visible:
		return

	_play_ui_click()

	help_panel.hide()
	help_backdrop.hide()

	_set_buttons_disabled(false)
```

### 6. Include the new button in disabling

Update `_set_buttons_disabled()`:

```
func _set_buttons_disabled(value: bool) -> void:
	start_button.disabled = value
	audio_button.disabled = value
	how_to_play_button.disabled = value
	quit_button.disabled = value
```

### 7. Close with Escape

Add to `main_menu.gd`:

```
func _unhandled_input(event: InputEvent) -> void:
	if not help_panel.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_close_help()
		get_viewport().set_input_as_handled()
```

The help panel now sits above the title menu, blocks input behind itself, plays the standard UI click, and closes through its button or `Esc`.


---- Graphical FIX::::


In recent Godot versions, offsets are often displayed as **Position** and **Size** under `Layout → Transform`. The easier and more reliable solution is to use a `CenterContainer`, avoiding manual offsets entirely.

## Recommended setup

Change the scene structure to:

```
Interface
├── HelpBackdrop
└── HelpCenter
    └── HelpPanel    visible==on
```

`HelpCenter` should be a `CenterContainer`.

### Configure `HelpCenter`

Select it and choose:

```
Layout → Anchors Preset → Full Rect
```

Ensure its transform values are:

```
Position: 0, 0
Offsets:  0 on every side
```

Set:

```
Mouse Filter: Ignore
Z Index: 101
Process Mode: Always
Visible: Off
```

### Configure `HelpPanel`

Remove its manual anchors and set:

```
Custom Minimum Size: 420 × 290
```

The `CenterContainer` will position it automatically.

Set `HelpPanel`:

```
Mouse Filter: Stop
```

### Update the script paths

In `main_menu.gd`, change:

```
@onready var help_panel: PanelContainer = (
	$"../HelpPanel"
)
```

to:

```
@onready var help_center: CenterContainer = (
	$"../HelpCenter"
)

@onready var help_panel: PanelContainer = (
	$"../HelpCenter/HelpPanel"
)
```

Update the Close button path:

```
@onready var help_close_button: Button = (
	$"../HelpCenter/HelpPanel/MarginContainer/"
	+ "VBoxContainer/CloseButton"
)
```

Because multiline node paths should not use string concatenation here, use this cleaner version:

```
@onready var help_close_button: Button = (
	$"../HelpCenter/HelpPanel/MarginContainer/VBoxContainer/CloseButton"
)
```

Finally, replace:

```
help_panel.show()
help_panel.hide()
```

with:

```
help_center.show()
help_center.hide()
```

Also change visibility checks to:

```
if not help_center.visible:
	return
```

This keeps the help window perfectly centred at every resolution without manually configuring offsets.


The help panel needs more width, stronger background separation, and the same woodland border palette.
The panel is now centred correctly, but its fixed `420 × 290` minimum size creates the large empty area beneath the Close button. The title is also still left-aligned.

## 1. Let the height fit its content

Select `HelpPanel` and change:

```
Custom Minimum Size X: 420
Custom Minimum Size Y: 0
```

Do not set a fixed height. `HelpCenter` will centre the panel using the height required by its contents.

If you prefer a little extra height, use:

```
Custom Minimum Size: 420 × 210
```

## 2. Centre the title

Select `TitleLabel`:

```
Horizontal Alignment: Center
Horizontal Size Flags: Fill
Custom Minimum Size Y: 24
```

Set:

```
Font Size: 16
Font Color: #f2d479
```

## 3. Improve internal spacing

Select the `VBoxContainer`:

```
Theme Overrides → Constants → Separation: 6
```

Select the inner `MarginContainer`:

```
Theme Overrides → Constants:

Margin Left:   12
Margin Top:    10
Margin Right:  12
Margin Bottom: 10
```

## 4. Remove forced expansion

Check `VBoxContainer` and `CloseButton`. Disable:

```
Vertical Size Flags → Expand
```

Set `CloseButton`:

```
Horizontal Size Flags: Fill
Custom Minimum Size Y: 28
```

## 5. Fix the bright border

The screenshot still shows a nearly white border. On `HelpPanel`, edit:

```
Theme Overrides → Styles → Panel
```

Use:

```
Background Color: #18231ff7
Border Color:     #31443b
Border Width:     3 on every side
Corner Radius:    0
```

The resulting panel will shrink around the instructions, remain centred automatically, and match the dark green pixel-style interface.

---Graphical Add on:: icons for the guide
The icon strip is ready: how_to_play_icons.png.

It contains five exact `16 × 16` cells:

```
0: Movement
1: Interaction
2: Resources
3: Camp
4: Winter survival
```

## 1. Import it
![[how_to_play_icons.png]]
Place it here:

```
res://assets/ui/how_to_play_icons.png
```

Use lossless compression and disable mipmaps.

## 2. Convert the instructions into rows

Inside the help panel’s `VBoxContainer`, use:

Change the VBoxContainer Theme Overrides -> Separation : 12 (better visual)

```
TitleLabel
MoveRow
├── MoveIcon
└── MoveLabel

InteractRow
├── InteractIcon
└── InteractLabel

ResourcesRow
├── ResourcesIcon
└── ResourcesLabel

CampRow
├── CampIcon
└── CampLabel

SurvivalRow
├── SurvivalIcon
└── SurvivalLabel

CloseButton
```

Each row should be an `HBoxContainer` with:

```
Theme Overrides → Constants → Separation: 8
Horizontal Size Flags: Fill
```

Configure every icon:

```
Custom Minimum Size: 16 × 16
Expand Mode: Ignore Size
Stretch Mode: Keep Aspect Centered
Mouse Filter: Ignore
```

Configure every label:

```
Horizontal Size Flags: Expand + Fill
Vertical Alignment: Center
Autowrap Mode: Word Smart
Custom minimum x: 16
```

## 3. Assign the atlas regions

Create a separate `AtlasTexture` for each icon, all using:

```
Atlas: how_to_play_icons.png
```

Use these regions:

```
MoveIcon:      x 0,  y 0, width 16, height 16
InteractIcon:  x 16, y 0, width 16, height 16
ResourcesIcon: x 32, y 0, width 16, height 16
CampIcon:      x 48, y 0, width 16, height 16
SurvivalIcon:  x 64, y 0, width 16, height 16
```

## 4. Simplify the text

Use:

```
MoveLabel:
WASD / Arrow Keys — Move

InteractLabel:
E — Gather or interact

ResourcesLabel:
Gather wood, stone, and food.

CampLabel:
Use resources at camp to build the cabin.

SurvivalLabel:
Consume one food daily. Finish before winter.
```

This creates a much clearer icon-and-text guide while keeping the panel compact and consistent with the HUD.