The logic is correct: `2 Food + 2 Wood + 1 Stone = 9 kg`, and exactly nine cells are occupied.

The filled view exposes two visual issues:

- The continuation dots are too small, so it is difficult to tell which cells form one item.
- The tutorial text remains visible behind the backpack overlay.

## Make item weight explicit

In `_refresh_slots()`, replace:

```
_fill_slot(
	next_slot,
	resource_type,
	weight_index == 0
)
```

with:

```
_fill_slot(
	next_slot,
	resource_type,
	weight_index,
	weight
)
```

Then replace `_fill_slot()` with:

```
func _fill_slot(
	slot_index: int,
	resource_type: int,
	weight_index: int,
	resource_weight: int
) -> void:
	var panel := slots[slot_index]
	var label := slot_labels[slot_index]

	var slot_color := EMPTY_COLOR
	var resource_text := ""

	match resource_type:
		ResourceTypes.Type.FOOD:
			slot_color = FOOD_COLOR
			resource_text = "FOOD"

		ResourceTypes.Type.WOOD:
			slot_color = WOOD_COLOR
			resource_text = "WOOD"

		ResourceTypes.Type.STONE:
			slot_color = STONE_COLOR
			resource_text = "STONE"

	if resource_weight == 1:
		label.text = resource_text
	elif weight_index == 0:
		label.text = "%s\n1/%d" % [
			resource_text,
			resource_weight
		]
	else:
		label.text = "%d/%d" % [
			weight_index + 1,
			resource_weight
		]

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			slot_color,
			ACTIVE_BORDER_COLOR
		)
	)
```

One stone will now read:

```
STONE
1/3
```

followed by:

```
2/3
3/3
```

One wood becomes:

```
WOOD
1/2
```

followed by:

```
2/2
```

That is much clearer than the dots and prevents three occupied stone cells from looking like three separate stones.

## Hide the normal HUD behind the backpack

Inside `_open_backpack_view()`, replace:

```
hud.hide_interaction_prompt()
```

with:

```
hud.hide_interaction_prompt()
hud.hide()
```

Then, inside `_close_backpack_view()`, immediately after:

```
backpack_view.close_view()
```

add:

```
hud.show()
```

This removes the tutorial hint and top bar from behind the overlay. The backpack becomes a clean, focused screen.

## Small visual adjustments

In the Inspector:

```
TitleLabel
Font Color: #f2d479
Font Size: 18

CapacityLabel
Font Color: #f2d479
```

For `Background`, slightly increase its opacity:

```
Color: #08100cd9
```

Your current grid size and panel dimensions are good—I would keep them. Once the numbered weight cells are in place, the next improvement can be small resource icons without sacrificing clarity.