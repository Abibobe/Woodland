Now we’ll replace the numeric Output messages with the compact HUD we planned: one thin bar, no collection of permanent windows.

### 1. Create the HUD scene

Create a new scene with a `Control` root:

```
HUD
```

Set its layout preset to **Full Rect**.

Create this structure:

```
HUD (Control)
└── TopBar (PanelContainer)
    └── MarginContainer
        └── ResourceRow (HBoxContainer)
            ├── DayLabel
            ├── Spacer
            ├── WoodLabel
            ├── StoneLabel
            └── FoodLabel
```

Node types:

|Node|Type|
|---|---|
|`DayLabel`|Label|
|`Spacer`|Control|
|`WoodLabel`|Label|
|`StoneLabel`|Label|
|`FoodLabel`|Label|

### 2. Configure the top bar

Select `TopBar`:

1. Choose **Layout → Anchors Preset → Top Wide**.
2. Set its bottom offset to `42`.

The bar should stretch across the top of the screen while remaining only 42 pixels tall.

Select `MarginContainer` and add these theme overrides:

```
Margin Left: 14
Margin Right: 14
Margin Top: 8
Margin Bottom: 8
```

Select `ResourceRow` and set its theme separation to approximately:

```
22
```

### 3. Configure the labels

Set their initial text:

```
DayLabel:    Day 1
WoodLabel:   Wood 0
StoneLabel:  Stone 0
FoodLabel:   Food 0
```

Select `Spacer`, then enable:

```
Layout → Container Sizing → Horizontal → Expand
```

This pushes the resource labels toward the right:

```
Day 1                              Wood 0   Stone 0   Food 0
```

### 4. Give the bar a subtle background

Select `TopBar`.

Under:

**Theme Overrides → Styles → Panel**

Create a new `StyleBoxFlat`.

Suggested settings:

```
Background Color: #17231DE6
Corner Radius Bottom Left: 8
Corner Radius Bottom Right: 8
```

Use a light font colour for the labels, such as:

```
#F1EBD9
```

Save the scene as:

```
res://scenes/ui/hud.tscn
```

## 5. Create the HUD script

Attach this script to the root `HUD` node:

```
res://scripts/ui/hud.gd
```

Add:

```
class_name HUD
extends Control


@onready var day_label: Label = (
	$TopBar/MarginContainer/ResourceRow/DayLabel
)

@onready var wood_label: Label = (
	$TopBar/MarginContainer/ResourceRow/WoodLabel
)

@onready var stone_label: Label = (
	$TopBar/MarginContainer/ResourceRow/StoneLabel
)

@onready var food_label: Label = (
	$TopBar/MarginContainer/ResourceRow/FoodLabel
)


func set_resource_amount(
	resource_type: int,
	amount: int
) -> void:
	match resource_type:
		ResourceNode.ResourceType.WOOD:
			wood_label.text = "Wood %s" % amount

		ResourceNode.ResourceType.STONE:
			stone_label.text = "Stone %s" % amount

		ResourceNode.ResourceType.FOOD:
			food_label.text = "Food %s" % amount


func set_day(day: int) -> void:
	day_label.text = "Day %s" % day
```

The HUD only displays values. It does not calculate resources or modify the inventory.

## 6. Add the HUD to the game

Open `game.tscn`.

Instantiate `hud.tscn` beneath `Interface`:

```
Game
├── World
│   └── ResourceSpawner
├── Actors
│   └── Player
├── ResourceInventory
└── Interface
    └── HUD
```

## 7. Connect the inventory to the HUD

Open `game_manager.gd`.

Add this reference beneath the existing `@onready` variables:

```
@onready var hud: HUD = $Interface/HUD
```

Replace `_on_inventory_resource_changed()` with:

```
func _on_inventory_resource_changed(
	resource_type: int,
	new_amount: int
) -> void:
	hud.set_resource_amount(
		resource_type,
		new_amount
	)
```

At the end of `_ready()`, add:

```
	_update_entire_hud()
```

Then add this new function:

```
func _update_entire_hud() -> void:
	hud.set_resource_amount(
		ResourceNode.ResourceType.WOOD,
		inventory.get_amount(ResourceNode.ResourceType.WOOD)
	)

	hud.set_resource_amount(
		ResourceNode.ResourceType.STONE,
		inventory.get_amount(ResourceNode.ResourceType.STONE)
	)

	hud.set_resource_amount(
		ResourceNode.ResourceType.FOOD,
		inventory.get_amount(ResourceNode.ResourceType.FOOD)
	)
```

Your complete `_ready()` should now be:

```
func _ready() -> void:
	player_interaction.resource_collected.connect(
		_on_resource_collected
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)

	_update_entire_hud()
```

Run the game and gather resources. The values should update immediately in the small top bar.

The HUD remains entirely passive:

```
Gather resource
      ↓
Inventory changes
      ↓
Inventory emits signal
      ↓
GameManager forwards value
      ↓
HUD updates one label
```

This is the clean relationship we wanted, with no game rules hidden inside the interface.

Small Fix: 
Exactly—the two issues come from the map and HUD using different vertical dimensions:

- The map is `22 × 32 = 704` pixels tall, leaving 16 unused pixels in a 720-pixel window.
- The HUD overlays the world, but the player’s movement boundary does not reserve its 42-pixel height.

We’ll let the map extend slightly beyond the window and reserve the HUD area for interface only.

### 1. Remove the grey bottom area

Select `World` in `game.tscn` and change:

```
Map Height: 23
```

The world becomes 736 pixels tall, and Godot simply crops the final 16 pixels outside the window.

### 2. Keep the player below the HUD

Select `Player` and change its exported boundaries:

```
Minimum Position: 10, 60
Maximum Position: 1270, 706
```

The player’s centre cannot move above `Y = 60`, keeping its body and visual below the 42-pixel bar.

You can also change the defaults in `player.gd`:

```
@export var minimum_position := Vector2(10.0, 60.0)
@export var maximum_position := Vector2(1270.0, 706.0)
```

Remember that existing scene values may override script defaults, so changing them in the Inspector is important.

### 3. Prevent resources from appearing behind the HUD

In `resource_spawner.gd`, find this code inside `_find_available_cell()`:

```
var candidate := Vector2i(
	random.randi_range(1, map_width - 2),
	random.randi_range(1, map_height - 2)
)
```

Change it to:

```
var candidate := Vector2i(
	random.randi_range(1, map_width - 2),
	random.randi_range(2, map_height - 2)
)
```

The first usable resource row will now be row 2:

```
2 × 32 + 16 = 80 pixels
```

That leaves enough room beneath the 42-pixel HUD, even for the tops of trees.

After these changes:

- The ground fills the complete window.
- The HUD remains overlaid at the top.
- The player cannot walk behind it.
- Trees, rocks, and bushes cannot spawn behind it.