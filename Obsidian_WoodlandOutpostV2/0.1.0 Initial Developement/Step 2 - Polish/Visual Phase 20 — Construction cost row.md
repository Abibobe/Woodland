### 1. Add a cost container

Inside the construction panel’s `VBoxContainer`, add an `HBoxContainer` named:

```
CostRow
```

Move the existing `CostLabel` into it, then add a `TextureRect` before the label:

```
CostRow
├── WoodCostIcon
└── CostLabel
```

Set `CostRow`:

```
Alignment: Begin
Theme Overrides → Constants → Separation: 4
```

### 2. Configure the wood icon

Set `WoodCostIcon` to:

```
Custom Minimum Size: 16 × 16
Expand Mode: Ignore Size
Stretch Mode: Keep Aspect Centered
Mouse Filter: Ignore
```

Create a new `AtlasTexture` for its texture:

```
Atlas:  hud_resource_icons.png
Region: x 0, y 0, width 16, height 16
```

### 3. Simplify the label

Instead of:

```
Cost: 5 Wood
```

display:

```
Cost: 5
```

If your script constructs the text, change the relevant line from something like:

```
cost_label.text = "Cost: %d Wood" % wood_cost
```

to:

```
cost_label.text = "Cost: %d" % wood_cost
```

Because `CostLabel` was moved, update its `@onready` path if necessary. The easiest reliable method is:

1. Drag `CostLabel` from the scene tree into the script editor.
2. Hold `Ctrl` while dropping it.
3. Let Godot generate the correct node path.

### 4. Add affordability feedback

Where the cost label is updated, add:

```
if build_button.disabled:
	cost_label.modulate = Color("#e06c68")
else:
	cost_label.modulate = Color("#f2e7c9")
```

Use the variable your script already uses for the player’s current wood amount if it has a different name.

The construction window will now show a compact icon-based cost, with the number turning red when the player cannot afford the next stage.