Now we’ll create the compact camp menu. It appears only while inspecting the camp and pauses player movement.

### 1. Create the menu scene

Create a new scene with a `Control` root named `CampMenu`.

Add:

```
CampMenu (Control)
└── Panel (PanelContainer)
    └── MarginContainer
        └── Content (VBoxContainer)
            ├── TitleLabel
            ├── CostLabel
            ├── MessageLabel
            └── Buttons (HBoxContainer)
                ├── BuildButton
                └── CloseButton
```

Set the initial text:

```
TitleLabel: Build Campfire
CostLabel: Cost: 5 Wood
MessageLabel:
BuildButton: Build
CloseButton: Close
```

On `MarginContainer`, use margins of approximately `12`.

On `CampMenu`, disable **Visibility → Visible**. The menu should start hidden.

Save it as:

```
res://scenes/ui/camp_menu.tscn
```

### 2. Create `camp_menu.gd`

Attach this script to `CampMenu`:

```
class_name CampMenu
extends Control


signal build_requested
signal close_requested


@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var cost_label: Label = (
	$Panel/MarginContainer/Content/CostLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var build_button: Button = (
	$Panel/MarginContainer/Content/Buttons/BuildButton
)

@onready var close_button: Button = (
	$Panel/MarginContainer/Content/Buttons/CloseButton
)


func _ready() -> void:
	build_button.pressed.connect(
		_on_build_button_pressed
	)

	close_button.pressed.connect(
		_on_close_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	call_deferred("_apply_layout")


func open_menu(
	next_stage_name: String,
	cost_text: String,
	can_build: bool,
	is_complete: bool
) -> void:
	message_label.text = ""

	if is_complete:
		title_label.text = "Cabin complete"
		cost_label.text = "Ready for winter"
		build_button.hide()
	else:
		title_label.text = "Build %s" % next_stage_name
		cost_label.text = "Cost: %s" % cost_text
		build_button.show()
		build_button.disabled = not can_build

	show()
	_apply_layout()


func close_menu() -> void:
	hide()


func show_message(text: String) -> void:
	message_label.text = text


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(360.0, 140.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		viewport_size.y - panel.size.y - 24.0
	)


func _on_build_button_pressed() -> void:
	build_requested.emit()


func _on_close_button_pressed() -> void:
	close_requested.emit()
```

## 3. Add it to the interface

Instantiate `camp_menu.tscn` beneath `Interface`:

```
Interface
├── HUD
└── CampMenu
```

Place it after `HUD` so it draws above the HUD when visible.

## 4. Allow player movement to be disabled

Add this variable to `player.gd`:

```
var movement_enabled: bool = true
```

At the beginning of `_physics_process()`, add:

```
func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector(
```

Add this function:

```
func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

	if not movement_enabled:
		velocity = Vector2.ZERO
```

Keep the remainder of `_physics_process()` unchanged.

## 5. Connect the menu in `game_manager.gd`

Add these references and variable:

```
@onready var player: Player = $Actors/Player
@onready var camp_menu: CampMenu = $Interface/CampMenu

var active_camp: Camp
```

Inside `_ready()`, add:

```
	camp_menu.build_requested.connect(
		_on_camp_build_requested
	)

	camp_menu.close_requested.connect(
		_close_camp_menu
	)
```

Replace the existing `"camp_opened"` match section with:

```
		"camp_opened":
			var camp := result.get("camp") as Camp

			if camp != null:
				_open_camp_menu(camp)
```

Then add these functions:

```
func _open_camp_menu(camp: Camp) -> void:
	active_camp = camp

	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)

	_refresh_camp_menu()


func _refresh_camp_menu() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()
	var is_complete := costs.is_empty()

	camp_menu.open_menu(
		active_camp.get_next_stage_name(),
		_format_cost(costs),
		_can_afford(costs),
		is_complete
	)


func _on_camp_build_requested() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()

	if not _can_afford(costs):
		camp_menu.show_message("Not enough resources")
		return

	_pay_cost(costs)
	active_camp.advance_construction()

	_refresh_camp_menu()


func _can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var required_amount := int(costs[resource_type])

		if not inventory.has_resources(
			int(resource_type),
			required_amount
		):
			return false

	return true


func _pay_cost(costs: Dictionary) -> void:
	for resource_type in costs:
		inventory.remove_resource(
			int(resource_type),
			int(costs[resource_type])
		)


func _format_cost(costs: Dictionary) -> String:
	if costs.is_empty():
		return ""

	var parts := PackedStringArray()

	for resource_type in costs:
		var resource_name := _get_resource_name(
			int(resource_type)
		)

		parts.append(
			"%s %s" % [
				costs[resource_type],
				resource_name
			]
		)

	return ", ".join(parts)


func _get_resource_name(resource_type: int) -> String:
	match resource_type:
		ResourceNode.ResourceType.WOOD:
			return "Wood"

		ResourceNode.ResourceType.STONE:
			return "Stone"

		ResourceNode.ResourceType.FOOD:
			return "Food"

	return "Unknown"


func _close_camp_menu() -> void:
	camp_menu.close_menu()
	active_camp = null

	player.set_movement_enabled(true)
	player_interaction.set_process_unhandled_input(true)
```

Run the game, gather five wood, and inspect the camp. The menu should:

- Appear only after pressing E at the camp.
- Stop the player from moving.
- Show the next construction stage and cost.
- Enable Build only when you can afford it.
- Deduct resources and change the camp visually.
- Disappear when Close is pressed.

The camp menu contains no construction rules. It displays information and emits button signals; `GameManager` coordinates the transaction.


Small Fix:::

The menu is functioning correctly. The disabled **Build** button is expected because you don’t currently have five wood.

However, the `E — Inspect camp` prompt is overlapping the menu. We should hide it while the menu is open.

In `_open_camp_menu()` inside `game_manager.gd`, add:

```
func _open_camp_menu(camp: Camp) -> void:
	active_camp = camp

	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)

	hud.hide_interaction_prompt()

	_refresh_camp_menu()
```

Then add this public function to `player_interaction.gd`:

```
func refresh_prompt() -> void:
	_refresh_interaction_prompt()
```

Finally, update `_close_camp_menu()`:

```
func _close_camp_menu() -> void:
	camp_menu.close_menu()
	active_camp = null

	player.set_movement_enabled(true)
	player_interaction.set_process_unhandled_input(true)
	player_interaction.refresh_prompt()
```

Open `player_interaction.gd` and replace the end of `interact()` with this:

```
func interact() -> void:
	var target := _get_closest_target()

	if target == null:
		return

	var result := target.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	if target.is_queued_for_deletion():
		nearby_targets.erase(target)

	# Opening the camp menu disables interaction.
	# In that case, do not show the prompt again.
	if not is_processing_unhandled_input():
		return

	_refresh_interaction_prompt()
```

Optionally, select the `Buttons` `HBoxContainer` and set:

```
Alignment: Center
```

That will centre the Build and Close buttons.

After the overlap fix, the menu layout is perfectly acceptable for this stage. We can polish its colours and dimensions later, once all construction behaviour is working.