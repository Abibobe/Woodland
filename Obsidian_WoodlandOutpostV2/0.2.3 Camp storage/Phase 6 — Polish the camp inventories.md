Let’s bring the camp-storage side closer to the visual quality of the backpack.

### 1. Add icons to the storage rows

Update the hierarchy:

```
StorageRows
├── FoodRow
│   ├── FoodIcon
│   ├── FoodLabel
│   ├── FoodSpacer
│   ├── FoodAmount
│   └── TakeFoodButton
├── WoodRow
│   ├── WoodIcon
│   ├── WoodLabel
│   ├── WoodSpacer
│   ├── WoodAmount
│   └── TakeWoodButton
└── StoneRow
    ├── StoneIcon
    ├── StoneLabel
    ├── StoneSpacer
    ├── StoneAmount
    └── TakeStoneButton
```

Each icon should be a `TextureRect` with:

```
Custom Minimum Size: 86 × 46
Expand Mode: Ignore Size
Stretch Mode: Keep Aspect Centered
Mouse Filter: Ignore
Texture Filter: Nearest
```

Assign:

```
FoodIcon  → backpack_food.png
WoodIcon  → backpack_wood.png
StoneIcon → backpack_stone.png
```

Set each storage row to:

```
Custom Minimum Size Y: 54
Alignment: Center
Separation: 8
```

Suggested labels:

```
Berries · 1 KG
Wood · 2 KG
Stone · 3 KG
```

### 2. Add a backpack instruction

Under `BackpackSummary`, add a `Label`:

```
BackpackHint
```

Configure:

```
Text: Click an item to deposit one unit
Horizontal Alignment: Center
Font Size: 11
Font Color: #b9c7b8
```

The left panel should now read naturally:

```
BACKPACK                  5 / 12 KG
[ visual contents ]
Food 1 • Wood 2 • Stone 0
Click an item to deposit one unit
[ DEPOSIT ALL — 5 KG → ]
```

### 3. Improve item tooltips

In `backpack_grid.gd`, replace:

```
panel.tooltip_text = (
	"Deposit 1 %s"
	% ResourceTypes.get_display_name(
		resource_type
	)
)
```

with:

```
panel.tooltip_text = (
	"Deposit 1 %s — %d KG"
	% [
		ResourceTypes.get_display_name(
			resource_type
		),
		weight
	]
)
```

### 4. Add hover feedback

In `_create_item_block()`, after the `gui_input.connect(...)` call, add:

```
panel.mouse_entered.connect(
	_on_item_mouse_entered.bind(
		panel,
		resource_type
	)
)

panel.mouse_exited.connect(
	_on_item_mouse_exited.bind(
		panel,
		resource_type
	)
)
```

Then add:

```
func _on_item_mouse_entered(
	panel: PanelContainer,
	resource_type: int
) -> void:
	if not is_instance_valid(panel):
		return

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			_get_resource_color(
				resource_type
			).lightened(0.10),
			Color("#fff0a3"),
			2
		)
	)


func _on_item_mouse_exited(
	panel: PanelContainer,
	resource_type: int
) -> void:
	if not is_instance_valid(panel):
		return

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			_get_resource_color(
				resource_type
			),
			ACTIVE_BORDER_COLOR,
			2
		)
	)
```

Now clickable resources become slightly brighter when hovered.

### 5. Improve the retrieval buttons

Change the button text from:

```
← TAKE
```

to:

```
← TAKE ONE
```

Set:

```
Custom Minimum Size: 96 × 32
Mouse Default Cursor Shape: Pointing Hand
```

Add tooltips:

```
TakeFoodButton:  Move 1 Food to backpack · Requires 1 KG
TakeWoodButton:  Move 1 Wood to backpack · Requires 2 KG
TakeStoneButton: Move 1 Stone to backpack · Requires 3 KG
```

### Result

The two sides now communicate different things clearly:

- The left side shows limited physical backpack space.
- The right side shows unlimited stored quantities.
- Resource artwork visually connects both inventories.
- Hovering explains weight and transfer direction.
- Buttons clearly transfer one item at a time.

After this visual pass, we can add a small transfer animation without moving or rebuilding either inventory.