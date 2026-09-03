We’ll replace the temporary single-line message with a dedicated pixel-style delivery panel. The existing stored-resource counters already flash when `inventory.add_resource()` emits its signals.

### 1. Add the HUD panel

Under `HUD`, add:

```
DeliveryPopup
└── MarginContainer
    └── DeliveryContent
        ├── DeliveryTitle
        ├── WoodDeliveryLabel
        ├── StoneDeliveryLabel
        └── FoodDeliveryLabel
```

Use:

|Node|Type|
|---|---|
|`DeliveryPopup`|`PanelContainer`|
|`MarginContainer`|`MarginContainer`|
|`DeliveryContent`|`VBoxContainer`|
|Remaining nodes|`Label`|

Configure `DeliveryPopup`:

```
Visible: Off
Custom Minimum Size: 220 × 100
Mouse Filter: Ignore
Z Index: 20
```

Apply the same dark pixel-style panel used by the HUD.

Configure the title:

```
Text: SUPPLIES DELIVERED
Horizontal Alignment: Center
Font Size: 12
Font Color: #f2d16b
```

Configure the other labels:

```
Font Size: 11
Horizontal Alignment: Center
Font Color: #f2e7c9
```

## 2. Add the HUD references

In `hud.gd`:

```
@onready var delivery_popup: PanelContainer = (
	$DeliveryPopup
)

@onready var wood_delivery_label resilient? Wait no. 
```

Use this complete block:

```
@onready var delivery_popup: PanelContainer = (
	$DeliveryPopup
)

@onready var wood_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/WoodDeliveryLabel
)

@onready var stone_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/StoneDeliveryLabel
)

@onready var food_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/FoodDeliveryLabel
)


var delivery_tween: Tween
```

## 3. Initialize and position it

At the end of `_ready()`:

```
delivery_popup.hide()
```

In `_apply_layout()`, add:

```
delivery_popup.set_anchors_preset(
	Control.PRESET_TOP_LEFT
)

delivery_popup.size = Vector2(
	220.0,
	100.0
)

delivery_popup.position = Vector2(
	(viewport_size.x - delivery_popup.size.x) / 2.0,
	viewport_size.y - 180.0
)
```

This places it above the interaction prompt.

## 4. Add the delivery animation

Add to `hud.gd`:

```
func show_delivery_summary(
	delivered_resources: Dictionary
) -> void:
	_set_delivery_line(
		wood_delivery_label,
		delivered_resources,
		ResourceTypes.Type.WOOD
	)

	_set_delivery_line(
		stone_delivery_label,
		delivered_resources,
		ResourceTypes.Type.STONE
	)

	_set_delivery_line(
		food_delivery_label,
		delivered_resources,
		ResourceTypes.Type.FOOD
	)

	if delivery_tween != null:
		delivery_tween.kill()

	delivery_popup.show()
	delivery_popup.modulate.a = 0.0
	delivery_popup.scale = Vector2(0.94, 0.94)
	delivery_popup.pivot_offset = (
		delivery_popup.size / 2.0
	)

	delivery_tween = create_tween()

	delivery_tween.tween_property(
		delivery_popup,
		"modulate:a",
		1.0,
		0.14
	)

	delivery_tween.parallel().tween_property(
		delivery_popup,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	delivery_tween.tween_interval(1.5)

	delivery_tween.tween_property(
		delivery_popup,
		"modulate:a",
		0.0,
		0.25
	)

	delivery_tween.tween_callback(
		_finish_delivery_popup
	)


func _set_delivery_line(
	label: Label,
	delivered_resources: Dictionary,
	resource_type: int
) -> void:
	var amount := int(
		delivered_resources.get(
			resource_type,
			0
		)
	)

	label.visible = amount > 0

	if amount <= 0:
		return

	var resource_name := (
		ResourceTypes.get_display_name(
			resource_type
		)
	)

	label.text = "+%d %s" % [
		amount,
		resource_name
	]


func _finish_delivery_popup() -> void:
	delivery_popup.hide()
	delivery_popup.modulate.a = 1.0
	delivery_popup.scale = Vector2.ONE
```

Only delivered resource types will be displayed.

## 5. Update `GameManager`

Inside `_on_deposit_timer_timeout()`, remove:

```
var summary := _format_delivery_summary(
	delivered_resources
)

hud.show_resource_gain(
	summary,
	_get_player_screen_position()
)
```

Replace it with:

```
hud.show_delivery_summary(
	delivered_resources
)
```

You can now delete `_format_delivery_summary()` because the HUD owns presentation formatting.

Keep `_get_player_screen_position()` because backpack warnings and ordinary gathering feedback can still use it.

## Test

Try depositing:

- Only wood
- Wood and food
- All three resources
- A completely full backpack

The panel should show only relevant lines, for example:

```
SUPPLIES DELIVERED
+4 Wood
+2 Stone
+3 Food
```

At the same time:

- Backpack returns to `0/12`.
- Camp-storage counters increase.
- Each changed counter flashes.
- The camp menu refreshes if it is open.