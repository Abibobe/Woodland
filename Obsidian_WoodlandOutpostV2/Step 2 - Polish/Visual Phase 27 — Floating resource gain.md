Next we can add a small floating notification such as `+1 Wood` when gathering

### 1. Add the popup label

In the HUD scene, add a `Label` directly beneath the root `HUD`:

```
HUD
├── TopBar
├── InteractionPrompt
└── ResourceGainPopup
```

Configure it:

```
Visible: Off
Mouse Filter: Ignore
Size: 120 × 24
Horizontal Alignment: Center
Vertical Alignment: Center
```

Under **Theme Overrides**:

```
Font Size:         12
Font Color:        #f2d479
Font Outline Color:#172019
Outline Size:      3
```

### 2. Add the HUD reference

In `hud.gd`, add:

```
@onready var resource_gain_popup: Label = (
	$ResourceGainPopup
)

var resource_gain_tween: Tween
```

### 3. Add the popup method

Add this function to `hud.gd`:

```
func show_resource_gain(
	text: String,
	screen_position: Vector2
) -> void:
	if resource_gain_tween != null:
		resource_gain_tween.kill()

	resource_gain_popup.text = text
	resource_gain_popup.size = Vector2(120.0, 24.0)

	var start_position := Vector2(
		screen_position.x - 60.0,
		screen_position.y - 42.0
	)

	resource_gain_popup.position = start_position
	resource_gain_popup.modulate.a = 1.0
	resource_gain_popup.show()

	resource_gain_tween = create_tween()

	resource_gain_tween.tween_property(
		resource_gain_popup,
		"position",
		start_position + Vector2(0.0, -20.0),
		0.65
	)

	resource_gain_tween.parallel().tween_property(
		resource_gain_popup,
		"modulate:a",
		0.0,
		0.5
	).set_delay(0.15)

	resource_gain_tween.chain().tween_callback(
		resource_gain_popup.hide
	)
```

### 4. Trigger it after gathering

In `game_manager.gd`, find:

```
inventory.add_resource(
	resource_type,
	amount
)
```

Immediately beneath it, add:

```
var resource_name := (
	ResourceTypes.get_display_name(resource_type)
)

var player_screen_position := (
	get_viewport().get_canvas_transform()
	* player.global_position
)

hud.show_resource_gain(
	"+%d %s" % [
		amount,
		resource_name
	],
	player_screen_position
)
```

The complete collection section becomes:

```
inventory.add_resource(
	resource_type,
	amount
)

var resource_name := (
	ResourceTypes.get_display_name(resource_type)
)

var player_screen_position := (
	get_viewport().get_canvas_transform()
	* player.global_position
)

hud.show_resource_gain(
	"+%d %s" % [
		amount,
		resource_name
	],
	player_screen_position
)
```

After gathering, text such as `+1 Wood` will appear above the player, rise by 20 pixels, and fade away. Inventory totals continue to be updated by the existing `resource_changed` signal.