We’ll create a modal tutorial that appears after the player starts their first game—not while the title menu is visible.

### 1. Create the tutorial interface

Under `Interface`, add:

```
TutorialPrompt
├── Backdrop
└── TutorialCenter
    └── Panel
        └── MarginContainer
            └── Content
                ├── TitleLabel
                ├── MessageLabel
                ├── MoveLabel
                ├── InteractLabel
                ├── PauseLabel
                └── GotItButton
```

Use these node types:

|Node|Type|
|---|---|
|`TutorialPrompt`|`Control`|
|`Backdrop`|`ColorRect`|
|`TutorialCenter`|`CenterContainer`|
|`Panel`|`PanelContainer`|
|`MarginContainer`|`MarginContainer`|
|`Content`|`VBoxContainer`|
|Remaining nodes|`Label` or `Button`|

Configure `TutorialPrompt`:

```
Layout: Full Rect
Visibility: Off
Mouse → Filter: Stop
Process → Mode: Always
Ordering → Z Index: 150
```

Set both `Backdrop` and `TutorialCenter` to **Full Rect**.

Use a translucent backdrop:

```
Backdrop Color: #09100dcc
Mouse Filter: Stop
```

### 2. Configure the text

Set:

```
TitleLabel:    WELCOME, SETTLER
MessageLabel: Prepare your outpost before winter arrives.

MoveLabel:     WASD / Arrow Keys — Move
InteractLabel: E — Gather or interact
PauseLabel:    ESC — Pause

GotItButton:   Got it
```

Recommended styling:

```
Title color: #f2d16b
Title size: 18
Text color: #d7ded2
Text size: 11
Content separation: 7
```

Apply the same pixel-style panel and button resources used by your other menus.

## 3. Create `tutorial_prompt.gd`

Attach this script to `TutorialPrompt`:

```
class_name TutorialPrompt
extends Control


const CONFIG_PATH := "user://tutorial_settings.cfg"
const CONFIG_SECTION := "tutorial"
const DISMISSED_KEY := "controls_dismissed"


@export var main_menu: MainMenu


@onready var got_it_button: Button = (
	$TutorialCenter/Panel/MarginContainer/
	Content/GotItButton
)


var previous_pause_state: bool = false


func _ready() -> void:
	hide()

	got_it_button.pressed.connect(
		_dismiss_prompt
	)

	main_menu.visibility_changed.connect(
		_on_main_menu_visibility_changed
	)

	call_deferred(
		"_check_for_first_game"
	)


func open_prompt() -> void:
	if visible:
		return

	previous_pause_state = get_tree().paused
	get_tree().paused = true

	show()
	got_it_button.grab_focus()


func _dismiss_prompt() -> void:
	_save_dismissed_state()

	hide()
	get_tree().paused = previous_pause_state


func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	call_deferred(
		"_check_for_first_game"
	)


func _check_for_first_game() -> void:
	if main_menu.visible:
		return

	if _was_previously_dismissed():
		return

	open_prompt()


func _was_previously_dismissed() -> bool:
	var config := ConfigFile.new()

	if config.load(CONFIG_PATH) != OK:
		return false

	return bool(
		config.get_value(
			CONFIG_SECTION,
			DISMISSED_KEY,
			false
		)
	)


func _save_dismissed_state() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(
		CONFIG_SECTION,
		DISMISSED_KEY,
		true
	)

	config.save(CONFIG_PATH)
```

Assign `Interface/MainMenu` to the script’s `Main Menu` property.

## 4. Add “Show Tutorial Again”

Inside the pause menu’s `Content`, add a button between **How to Play** and **Return to Title**:

```
ShowTutorialButton
Text: Show Tutorial Again
```

In `pause_menu.gd`, add:

```
@export var tutorial_prompt: TutorialPrompt
```

Add the button reference:

```
@onready var show_tutorial_button: Button = (
	$PauseCenter/Panel/MarginContainer/
	Content/ShowTutorialButton
)
```

Connect it in `_ready()`:

```
show_tutorial_button.pressed.connect(
	_open_tutorial
)

tutorial_prompt.visibility_changed.connect(
	_on_secondary_panel_visibility_changed
)
```

Add:

```
func _open_tutorial() -> void:
	_play_ui_click()

	hide()
	tutorial_prompt.open_prompt()
```

Also update `_restore_after_secondary_panel()` by adding:

```
if tutorial_prompt.visible:
	return
```

Assign `TutorialPrompt` to the new exported property on `PauseMenu`.

## 5. Test it

To test the first-launch behavior again, delete:

```
user://tutorial_settings.cfg
```

Then run the project:

1. The main menu should appear normally.
2. Click **Start Game**.
3. The tutorial should appear and pause gameplay.
4. Click **Got it**.
5. Restart the project—the tutorial should no longer appear automatically.
6. Open Pause and select **Show Tutorial Again** to display it manually.

FIX:::: Stato caotico dei menu

You’re right—that state is chaotic. Two things are happening:

1. The pause menu is being restored by a generic `visibility_changed` signal.
2. `ConfirmPanel` was not forcibly reset before the tutorial opened.

We’ll make restoration intentional instead of reacting to every visibility change.

## 1. Verify the scene hierarchy

`TutorialPrompt` must be a sibling of `PauseMenu`, not its child:

```
Interface
├── PauseMenu
├── TutorialPrompt
├── AudioSettingsBackdrop
├── AudioSettingsPanel
└── MainMenu
```

Also set these initial Inspector values:

```
PauseMenu → Visible: Off
PauseMenu/PauseCenter/ConfirmPanel → Visible: Off
TutorialPrompt → Visible: Off
```

## 2. Track whether PauseMenu opened the secondary window

In `pause_menu.gd`, add:

```
var waiting_for_secondary_panel: bool = false
```

Replace `_open_tutorial()` with:

```
func _open_tutorial() -> void:
	if tutorial_prompt == null:
		return

	_play_ui_click()

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
	hide()

	tutorial_prompt.open_prompt()
```

Update the Audio and Help functions similarly:

```
func _open_audio_settings() -> void:
	_play_ui_click()

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
	hide()

	audio_settings_panel.open_panel()


func _open_help() -> void:
	_play_ui_click()

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
	hide()

	main_menu.open_help_panel()
```

## 3. Replace the restoration function

Replace `_restore_after_secondary_panel()` completely:

```
func _restore_after_secondary_panel() -> void:
	if not waiting_for_secondary_panel:
		return

	if audio_settings_panel.visible:
		return

	if help_center.visible:
		return

	if tutorial_prompt != null:
		if tutorial_prompt.visible:
			return

	waiting_for_secondary_panel = false

	if not get_tree().paused:
		return

	confirm_panel.hide()
	panel.show()
	show()

	resume_button.grab_focus()
```

Keep the signal handler as:

```
func _on_secondary_panel_visibility_changed() -> void:
	call_deferred(
		"_restore_after_secondary_panel"
	)
```

The `waiting_for_secondary_panel` flag prevents startup visibility changes from unexpectedly opening the pause menu.

## 4. Reset everything when Pause opens

At the beginning of `_open_pause_menu()`, use:

```
func _open_pause_menu() -> void:
	get_tree().paused = true
	waiting_for_secondary_panel = false

	confirm_panel.hide()
	panel.show()

	confirm_button.disabled = false
	cancel_button.disabled = false

	# Keep the existing opening-animation code below.
```

Do not add another `show()` if your animation code already calls it.

## 5. Prevent PauseMenu from opening during the tutorial

At the beginning of `_unhandled_input()`, after checking for `ui_cancel`, ensure the modal check happens before opening Pause:

```
if tutorial_prompt != null:
	if tutorial_prompt.visible:
		return
```

Your modal checker can contain:

```
func _is_another_modal_open() -> bool:
	if main_menu.visible:
		return true

	if audio_settings_panel.visible:
		return true

	if help_center.visible:
		return true

	if result_screen.visible:
		return true

	if tutorial_prompt != null and tutorial_prompt.visible:
		return true

	return false
```

After these changes:

- A first-game tutorial appears by itself.
- Opening it from Pause hides the entire pause interface.
- `ConfirmPanel` cannot remain visible behind it.
- Closing a manually opened tutorial restores the normal pause panel.
- Closing the automatic first-launch tutorial resumes gameplay.


Replace the complete `_unhandled_input()` function with this clean version:

```
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if tutorial_prompt != null and tutorial_prompt.visible:
		return

	if audio_settings_panel.visible:
		return

	if help_center.visible:
		return

	if result_screen.visible:
		return

	if main_menu.visible:
		return

	get_viewport().set_input_as_handled()

	if confirm_panel.visible and visible:
		_cancel_return_to_title()
		return

	if visible:
		_resume_game()
		return

	if get_tree().paused:
		return

	_open_pause_menu()
```

Then replace `_set_buttons_disabled()` with:

```
func _set_buttons_disabled(value: bool) -> void:
	resume_button.disabled = value
	audio_button.disabled = value
	help_button.disabled = value
	title_button.disabled = value
	show_tutorial_button.disabled = value
```

Delete this misplaced section from the old function:

```
if tutorial_prompt.visible:
	return
```

Also fix the Cancel button focus. In `_cancel_return_to_title()`, change:

```
confirm_button.grab_focus()
```

to:

```
title_button.grab_focus()
```

Finally, select `PauseMenu` in Godot and confirm:

```
Process → Mode: Always
Visibility → Visible: Off
```


e likely issue is that another UI node consumes `Esc` before `_unhandled_input()` receives it. We can make the pause controller read the action directly every frame.

Delete `_unhandled_input()` completely and replace it with:

```
func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return

	_handle_pause_input()
```

Then add:

```
func _handle_pause_input() -> void:
	if tutorial_prompt != null:
		if tutorial_prompt.is_visible_in_tree():
			return

	if audio_settings_panel.is_visible_in_tree():
		return

	if help_center.is_visible_in_tree():
		return

	if result_screen.is_visible_in_tree():
		return

	if main_menu.is_visible_in_tree():
		return

	if confirm_panel.visible and visible:
		_cancel_return_to_title()
		return

	if visible:
		_resume_game()
		return

	if get_tree().paused:
		return

	_open_pause_menu()
```

Using `Input.is_action_just_pressed()` avoids the competition between `_unhandled_input()` functions in the different menus.

Also verify these two settings on `PauseMenu`:

```
Process → Mode: Always
Visibility → Visible: Off
```

### Important MainMenu check

When **Start Game** finishes, `MainMenu` must actually be hidden—not merely transparent.

Find the end of your Start Game transition in `main_menu.gd` and ensure it contains:

```
hide()
```

Changing only this:

```
modulate.a = 0.0
```

makes the menu invisible but leaves `main_menu.is_visible_in_tree()` equal to `true`, which intentionally blocks the pause menu.

After making these changes, restart the running scene rather than only stopping and resuming it. `Esc` should then reliably open and close Pause.