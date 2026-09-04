Now we’ll add the actual survival rules and proper victory/defeat screens.

Rules:

- Every completed day consumes one food.
- If no food is available, you lose.
- Completing the cabin produces an immediate victory.
- Reaching the end of day seven without a cabin produces defeat.

### 1. Create the result screen

Create a new scene with a `Control` root:

```
ResultScreen
```

Add:

```
ResultScreen (Control)
├── Dimmer (ColorRect)
└── Panel (PanelContainer)
    └── MarginContainer
        └── Content (VBoxContainer)
            ├── TitleLabel
            ├── MessageLabel
            └── RestartButton
```

Configure:

```
Dimmer Color: #00000099
TitleLabel: Victory
MessageLabel: The cabin is ready.
RestartButton: Play Again
```

Set both labels’ horizontal alignment to **Center**.

Set `MarginContainer` theme margins to `16`.

Turn off **Visible** on the root `ResultScreen`.

Save as:

```
res://scenes/ui/result_screen.tscn
```

### 2. Create `result_screen.gd`

Attach this script:

```
class_name ResultScreen
extends Control


signal restart_requested


@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var restart_button: Button = (
	$Panel/MarginContainer/Content/RestartButton
)


func _ready() -> void:
	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	call_deferred("_apply_layout")


func show_result(
	title: String,
	message: String
) -> void:
	title_label.text = title
	message_label.text = message

	show()
	_apply_layout()


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	dimmer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dimmer.position = Vector2.ZERO
	dimmer.size = viewport_size

	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400.0, 180.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		(viewport_size.y - panel.size.y) / 2.0
	)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
```

### 3. Add it to the game

Instantiate it beneath `Interface`, after the other UI scenes:

```
Interface
├── HUD
├── CampMenu
└── ResultScreen
```

### 4. Update `game_manager.gd`

Add these references and state variable:

```
@onready var camp: Camp = $World/Camp
@onready var result_screen: ResultScreen = $Interface/ResultScreen

var game_finished: bool = false
```

Inside `_ready()`, connect the restart button:

```
	result_screen.restart_requested.connect(
		_on_restart_requested
	)
```

Replace `_on_day_ended()` with:

```
func _on_day_ended(day: int) -> void:
	if game_finished:
		return

	var food_type := ResourceNode.ResourceType.FOOD
	var food_consumed := inventory.remove_resource(
		food_type,
		1
	)

	if not food_consumed:
		_finish_game(
			"Defeat",
			"You had no food at the end of day %s."
				% day
		)
		return

	print("Day %s ended. One food consumed." % day)
```

Replace `_on_survival_period_completed()` with:

```
func _on_survival_period_completed() -> void:
	if game_finished:
		return

	if camp.current_stage == Camp.CampStage.CABIN:
		_finish_game(
			"Victory",
			"The cabin is ready for winter."
		)
	else:
		_finish_game(
			"Defeat",
			"Winter arrived before the cabin was completed."
		)
```

### 5. Detect victory after construction

Inside `_on_camp_build_requested()`, find:

```
	active_camp.advance_construction()

	_refresh_camp_menu()
```

Replace it with:

```
	active_camp.advance_construction()

	if active_camp.current_stage == Camp.CampStage.CABIN:
		_finish_game(
			"Victory",
			"The cabin is complete. You are ready for winter."
		)
		return

	_refresh_camp_menu()
```

### 6. Add the end-game functions

Add these functions to `game_manager.gd`:

```
func _finish_game(
	title: String,
	message: String
) -> void:
	if game_finished:
		return

	game_finished = true
	active_camp = null

	day_cycle.set_running(false)
	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)

	hud.hide_interaction_prompt()
	camp_menu.close_menu()

	result_screen.show_result(
		title,
		message
	)


func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
```

## Test quickly

Temporarily use:

```
Day Duration: 10 seconds
```

Try these cases:

1. Gather no food → defeat after day one.
2. Gather food but don’t build → defeat after day seven.
3. Gather enough materials and finish the cabin → immediate victory.
4. Press **Play Again** → a new random world is generated.

Once everything works, restore the day duration to around `90` seconds. At this point, the project has a complete playable loop.