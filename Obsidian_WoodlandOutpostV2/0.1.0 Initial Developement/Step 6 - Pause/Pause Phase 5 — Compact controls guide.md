We’ll add a small two-column controls section without duplicating the full **How to Play** screen.

### 1. Add a controls grid

Inside `Content`, place a `GridContainer` between `SubtitleLabel` and `ResumeButton`:

```
Content
├── TitleLabel
├── SubtitleLabel
├── ControlsGrid
├── ResumeButton
├── AudioButton
├── HelpButton
├── ReturnButton
└── HintLabel
```

Set:

```
ControlsGrid → Columns: 2
Theme Overrides → Constants:
    H Separation: 18
    V Separation: 3
```

### 2. Add the control labels

Add eight `Label` children in this exact order:

| Node             | Text          |
| ---------------- | ------------- |
| `MoveAction`     | Move          |
| `MoveKey`        | WASD / Arrows |
| `InteractAction` | Interact      |
| `InteractKey`    | E             |
| `PauseAction`    | Pause         |
| `PauseKey`       | ESC           |
| `SelectAction`   | Select        |
| `SelectKey`      | Enter         |

The grid will arrange them as:

|Action|Key|
|---|---|
|Move|WASD / Arrows|
|Interact|E|
|Pause|ESC|
|Select|Enter|

### 3. Style the columns

For the four action labels, use:

```
Font Size: 10
Font Color: #aab8a5
Horizontal Alignment: Left
```

For the four key labels, use:

```
Font Size: 10
Font Color: #f2d16b
Horizontal Alignment: Right
Size Flags → Horizontal: Expand + Fill
```

Set `ControlsGrid` itself to:

```
Size Flags → Horizontal: Fill
```

### 4. Add breathing room

Select `ControlsGrid` and set:

```
Layout → Transform → Custom Minimum Size Y: 50
```

If the bottom of the panel becomes cramped, remove any fixed height from `Panel`. Containers should calculate the required height automatically.

### 5. Ensure buttons support keyboard navigation

Select each pause-menu button and verify:

```
Focus → Mode: All
```

Keep this in `_open_pause_menu()`:

```
resume_button.grab_focus()
```

Godot will then navigate vertically using the arrow keys, while `Enter` activates the selected button and `Escape` resumes the game.

The pause screen now provides the essential controls at a glance, while **How to Play** remains available for the complete instructions.