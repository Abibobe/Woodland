Let’s use the existing day-cycle phases to tint the world gradually while leaving the HUD readable.

### 1. Add `CanvasModulate`

In `game.tscn`, add a `CanvasModulate` beneath `Game` and name it:

```
WorldTint
```

Keep it outside `Entities` and place it before `Interface`:

```
Game
├── WorldTint
├── World
├── Entities
├── ResourceInventory
├── DayCycle
└── Interface
```

Set its initial color to white:

```
#ffffff
```

Because the HUD is under `Interface`, which should be a `CanvasLayer`, the tint should affect the world without darkening the UI.

### 2. Add the reference

In `game_manager.gd`, add:

```
@onready var world_tint: CanvasModulate = $WorldTint

var world_tint_tween: Tween
```

### 3. Update the time-display method

Change:

```
func _on_time_display_changed(
	day: int,
	phase: String
) -> void:
	hud.set_day(day, phase)
```

to:

```
func _on_time_display_changed(
	day: int,
	phase: String
) -> void:
	hud.set_day(day, phase)
	_update_world_tint(phase)
```

### 4. Add the tint function

```
func _update_world_tint(phase: String) -> void:
	var target_color := Color.WHITE

	match phase.to_lower():
		"morning":
			target_color = Color("#fff1d6")

		"afternoon":
			target_color = Color("#ffffff")

		"evening":
			target_color = Color("#ddb29f")

		"night":
			target_color = Color("#8497bd")

	if world_tint_tween != null:
		world_tint_tween.kill()

	world_tint_tween = create_tween()

	world_tint_tween.tween_property(
		world_tint,
		"color",
		target_color,
		1.5
	)
```

Run through a full day. The world should transition gradually:

- Morning: warm sunlight.
- Afternoon: neutral original colours.
- Evening: soft orange-red.
- Night: cool blue.

The interface should remain unchanged and fully readable.