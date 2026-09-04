This prevents accidental loss of the current run.

### 1. Add the confirmation panel

Under `PauseCenter`, add another `PanelContainer`:

```
PauseMenu
├── Backdrop
└── PauseCenter
    ├── Panel
    └── ConfirmPanel
```

Set `ConfirmPanel → Visibility → Visible` to **Off**.

Inside it, create:

```
ConfirmPanel
└── MarginContainer
    └── ConfirmContent
        ├── ConfirmTitle
        ├── ConfirmMessage
        └── ConfirmButtons
            ├── CancelButton
            └── ConfirmButton
```

Use:

```
ConfirmTitle:   RETURN TO TITLE?
ConfirmMessage: Current progress will be lost.
CancelButton:   Cancel
ConfirmButton:  Return
```

Configure:

- `ConfirmContent`: `VBoxContainer`
- `ConfirmButtons`: `HBoxContainer`
- Both buttons: `Size Flags → Horizontal → Expand + Fill`
- Labels: horizontally centered
- `ConfirmTitle` color: `#f2d16b`
- `ConfirmMessage` color: `#d7ded2`

### 2. Add the references

In `pause_menu.gd`:

```
@onready var confirm_panel: PanelContainer = (
	$PauseCenter/ConfirmPanel
)

@onready var cancel_button: Button = (
	$PauseCenter/ConfirmPanel/MarginContainer/
	ConfirmContent/ConfirmButtons/CancelButton
)

@onready var confirm_button: Button = (
	$PauseCenter/ConfirmPanel/MarginContainer/
	ConfirmContent/ConfirmButtons/ConfirmButton
)
```

### 3. Connect the buttons

Add to `_ready()`:

```
cancel_button.pressed.connect(
	_cancel_return_to_title
)

confirm_button.pressed.connect(
	_confirm_return_to_title
)
```

### 4. Replace the existing return function

Replace `_return_to_title()` with:

```
func _return_to_title() -> void:
	_play_ui_click()

	panel.hide()
	confirm_panel.show()

	cancel_button.grab_focus()
```

Add:

```
func _cancel_return_to_title() -> void:
	_play_ui_click()

	confirm_panel.hide()
	panel.show()

	return_button.grab_focus()
```

Then move the old scene-reloading behavior into:

```
func _confirm_return_to_title() -> void:
	_play_ui_click()

	confirm_button.disabled = true
	cancel_button.disabled = true

	await get_tree().create_timer(
		0.09,
		true,
		false,
		true
	).timeout

	get_tree().paused = false
	get_tree().reload_current_scene()
```

The final `true` makes the timer continue while the game is paused.

### 5. Reset the panel when opening

At the beginning of `_open_pause_menu()`, after pausing, add:

```
confirm_panel.hide()
panel.show()

confirm_button.disabled = false
cancel_button.disabled = false
```

### 6. Make Escape cancel confirmation first

At the point in `_unhandled_input()` where `ui_cancel` is handled, use:

```
if event.is_action_pressed("ui_cancel"):
	get_viewport().set_input_as_handled()

	if confirm_panel.visible:
		_cancel_return_to_title()
		return

	if visible:
		_resume_game()
		return
```

Now **Return to Title** opens a confirmation prompt. `Cancel` or `Escape` returns to the pause menu, while `Return` reloads the game and displays the title screen.