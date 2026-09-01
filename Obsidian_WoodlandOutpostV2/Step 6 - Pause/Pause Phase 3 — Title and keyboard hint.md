Update the pause panel’s content to this structure:

```
Panel
└── MarginContainer
    └── Content
        ├── TitleLabel
        ├── SubtitleLabel
        ├── ResumeButton
        ├── AudioButton
        ├── HelpButton
        ├── ReturnButton
        └── HintLabel
```

`Content` should remain a `VBoxContainer`.

### 1. Add the title

Add a `Label` named:

```
TitleLabel
```

Set:

```
Text: GAME PAUSED
Horizontal Alignment: Center
Theme Overrides → Font Sizes → Font Size: 20
Theme Overrides → Colors → Font Color: #f2d16b
```

### 2. Add a subtitle

Add another `Label` named:

```
SubtitleLabel
```

Set:

```
Text: The forest is waiting.
Horizontal Alignment: Center
Theme Overrides → Font Sizes → Font Size: 11
Theme Overrides → Colors → Font Color: #aab8a5
```

### 3. Add spacing

Select `Content` and set:

```
Theme Overrides
└── Constants
    └── Separation: 7
```

Give the `MarginContainer` these values:

```
Margin Left:   16
Margin Top:    14
Margin Right:  16
Margin Bottom: 12
```

### 4. Add the keyboard hint

At the bottom of `Content`, add a `Label` named:

```
HintLabel
```

Set:

```
Text: ESC — Resume
Horizontal Alignment: Center
Theme Overrides → Font Sizes → Font Size: 10
Theme Overrides → Colors → Font Color: #829181
```

If you are using a pixel font, keep the font sizes as whole numbers and avoid scaling the labels.

### 5. Optional focus adjustment

In `_open_pause_menu()`, keep:

```
resume_button.grab_focus()
```

This lets keyboard players immediately press `Enter` to resume, while `Escape` continues to close the menu.

The finished panel should read:

```
GAME PAUSED
The forest is waiting.

Resume
Audio Settings
How to Play
Return to Title

ESC — Resume
```

It will remain compact while making the game’s paused state immediately clear.