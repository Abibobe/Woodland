
First we’ll create the structure-selection interface. We won’t place remote campfires yet; this phase verifies that B behaves correctly during scouting, gameplay, and other menus.

### 1. Create `build_menu.gd`

Create:

```text
res://scripts/ui/build_menu.gd
```

Add:

```gdscript
class_name BuildMenu
extends Control


signal campfire_requested
signal close_requested


@onready var background: ColorRect = $Background

@onready var panel: PanelContainer = (
	$CenterContainer/Panel
)

@onready var main_camp_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/MainCampButton
)

@onready var campfire_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/CampfireButton
)

@onready var rabbit_trap_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/RabbitTrapButton
)

@onready var close_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/CloseButton
)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	campfire_button.pressed.connect(
		_on_campfire_pressed
	)

	close_button.pressed.connect(
		_on_close_pressed
	)

	main_camp_button.disabled = true
	rabbit_trap_button.disabled = true

	hide()


func open_menu() -> void:
	main_camp_button.text = (
		"MAIN CAMP — ALREADY ESTABLISHED"
	)

	campfire_button.text = (
		"CAMPFIRE\nCost: 3 Wood"
	)

	rabbit_trap_button.text = (
		"RABBIT TRAP — LOCKED"
	)

	show()
	campfire_button.grab_focus()


func close_menu() -> void:
	hide()


func _on_campfire_pressed() -> void:
	campfire_requested.emit()


func _on_close_pressed() -> void:
	close_requested.emit()
```

### 2. Create `build_menu.tscn`

Create this hierarchy:

```text
BuildMenu (Control)
├── Background (ColorRect)
└── CenterContainer
    └── Panel (PanelContainer)
        └── MarginContainer
            └── Content (VBoxContainer)
                ├── TitleLabel
                ├── DescriptionLabel
                ├── MainCampButton
                ├── CampfireButton
                ├── RabbitTrapButton
                ├── Separator
                └── CloseButton
```

Configure `BuildMenu`:

```text
Layout: Full Rect
Visible: Off
Z Index: 85
Mouse Filter: Stop
Script: build_menu.gd
```

Configure `Background`:

```text
Layout: Full Rect
Color: #08100cdd
Mouse Filter: Stop
```

Configure `CenterContainer`:

```text
Layout: Full Rect
Mouse Filter: Ignore
```

Configure `Panel`:

```text
Custom Minimum Size: 440 × 400
```

Set all `MarginContainer` margins to `20`.

Configure `Content`:

```text
Separation: 12
```

Suggested text:

```text
TitleLabel:
BUILD MENU

DescriptionLabel:
Choose a structure to place in the woodland.

MainCampButton:
MAIN CAMP — ALREADY ESTABLISHED

CampfireButton:
CAMPFIRE
Cost: 3 Wood

RabbitTrapButton:
RABBIT TRAP — LOCKED

CloseButton:
CLOSE
```

Set the title colour to:

```text
#f2d479
```

Give the structure buttons a minimum height of approximately `62`.

### 3. Add it to `game.tscn`

Instantiate the scene beneath `Interface`:

```text
Interface
├── HUD
├── CampMenu
├── BackpackView
├── BuildMenu
└── ...
```

### 4. Reference it in `GameManager`

Add:

```gdscript
@onready var build_menu: BuildMenu = (
	$Interface/BuildMenu
)
```

In `_ready()`, connect:

```gdscript
build_menu.close_requested.connect(
	_close_build_menu
)

build_menu.campfire_requested.connect(
	_on_campfire_build_requested
)
```

### 5. Add opening and closing functions

```gdscript
func _open_build_menu() -> void:
	if game_finished:
		return

	if not camp_is_placed:
		return

	if camp_menu.visible:
		return

	if backpack_view.visible:
		return

	if main_menu.visible:
		return

	player.set_movement_enabled(false)

	player_interaction.set_process_unhandled_input(
		false
	)

	day_cycle.set_running(false)
	hud.hide_interaction_prompt()
	hud.hide()

	build_menu.open_menu()


func _close_build_menu() -> void:
	build_menu.close_menu()

	if game_finished:
		return

	hud.show()

	player.set_movement_enabled(true)

	player_interaction.set_process_unhandled_input(
		true
	)

	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
```

For now, add a temporary campfire handler:

```gdscript
func _on_campfire_build_requested() -> void:
	build_menu.close_menu()

	hud.show()
	hud.show_milestone(
		"C Run mode."
	)

	player.set_movement_enabled(true)

	player_interaction.set_process_unhandled_input(
		true
	)

	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
```

Use this corrected message instead of the accidental placeholder above:

```gdscript
func _on_campfire_build_requested() -> void:
	build_menu.close_menu()

	hud.show()
	hud.show_milestone(
		"CAMPFIRE SELECTED\nPLACEMENT COMING NEXT"
	)

	player.set_movement_enabled(true)

	player_interaction.set_process_unhandled_input(
		true
	)

	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
```

### 6. Update `GameManager._unhandled_input()`

Near the beginning, after the echo check, add:

```gdscript
if build_menu.visible:
	if (
		event.is_action_pressed(
			"toggle_build_mode"
		)
		or event.is_action_pressed(
			"ui_cancel"
		)
	):
		_close_build_menu()
		get_viewport().set_input_as_handled()

	return
```

Then, after the existing backpack/camp interface checks, add:

```gdscript
if (
	camp_is_placed
	and event.is_action_pressed(
		"toggle_build_mode"
	)
):
	_open_build_menu()
	get_viewport().set_input_as_handled()
	return
```

### Test

- During Day 0, B still controls Main Camp placement.
    
- After establishing the camp, B opens the Build Menu.
    
- Main Camp is disabled and marked as established.
    
- Rabbit Trap is visible but locked.
    
- Campfire is selectable.
    
- B or Escape closes the menu.
    
- The pause menu does not appear behind it.
    
- Movement, Hunger, and time resume after closing.
    
- TAB does not open the backpack behind the Build Menu.
    

Once this menu works reliably, we’ll replace the temporary campfire message with real campfire placement and a `3 Wood` cost check.