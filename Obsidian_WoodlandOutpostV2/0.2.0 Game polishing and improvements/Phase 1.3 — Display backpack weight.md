The current flow is clear, and we found the critical point:

```
ResourceNode.interact()
→ immediately removes the resource
→ GameManager receives the result afterward
```

Therefore, we must not simply replace `inventory.add_resource()` with `backpack.add_resource()`. If the backpack were full, the resource would already have been consumed. We’ll fix that transaction in the next step.

First, let’s connect the backpack to the HUD while leaving gathering unchanged.

### 1. Add the HUD label

In `game.tscn`, locate:

```
Interface
└── HUD
    └── TopBar
        └── MarginContainer
            └── ResourceRow
```

Add a `Label` named:

```
BackpackLabel
```

Place it after the resource counters and set:

```
Text: Backpack 0/12
Horizontal Alignment: Right
Size Flags → Horizontal: Expand + Fill
```

Use:

```
Font Size: 11
Font Color: #f2d16b
Mouse Filter: Ignore
```

If the hidden `AudioButton` still occupies space in `ResourceRow`, either remove it or ensure:

```
Visible: Off
```

### 2. Reference it in `hud.gd`

Add near the other label references:

```
@onready var backpack_label: Label = (
	$TopBar/MarginContainer/ResourceRow/
	BackpackLabel
)
```

Add this function:

```
func set_backpack_weight(
	current_weight: int,
	maximum_weight: int
) -> void:
	backpack_label.text = "Backpack %d/%d" % [
		current_weight,
		maximum_weight
	]

	if current_weight >= maximum_weight:
		backpack_label.modulate = Color("#e38b65")
	else:
		backpack_label.modulate = Color.WHITE
```

For now, we won’t animate it. First we verify that its data is correct.

### 3. Connect it in `game_manager.gd`

You should already have:

```
@onready var backpack: PlayerBackpack = $PlayerBackpack
```

In `_ready()`, connect its signal:

```
backpack.weight_changed.connect(
	_on_backpack_weight_changed
)
```

Add:

```
func _on_backpack_weight_changed(
	current_weight: int,
	maximum_weight: int
) -> void:
	hud.set_backpack_weight(
		current_weight,
		maximum_weight
	)
```

At the end of `_update_entire_hud()`, add:

```
hud.set_backpack_weight(
	backpack.get_current_weight(),
	backpack.maximum_weight
)
```

The complete end of that function should resemble:

```
hud.set_resource_amount(
	ResourceTypes.Type.FOOD,
	inventory.get_amount(
		ResourceTypes.Type.FOOD
	)
)

hud.set_backpack_weight(
	backpack.get_current_weight(),
	backpack.maximum_weight
)
```

## Test

Run the game and verify:

```
Backpack 0/12
```

The value should remain `0/12` when gathering. That is expected: gathering still goes directly into camp storage during this safe intermediate step.

Your existing Wood, Stone, and Food counters should continue increasing exactly as before.

Next, we’ll make collection transactional:

1. Ask the backpack whether the reward fits.
2. If it fits, deplete the resource and add it to the backpack.
3. If it does not fit, preserve the resource completely.
4. Show “Backpack full — return to camp.”
5. Play the existing denied-action sound.