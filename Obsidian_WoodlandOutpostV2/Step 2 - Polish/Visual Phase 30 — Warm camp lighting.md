The natural next step is a warm camp light that appears for the campfire and cabin, becoming especially visible against the evening and night tint.

Your stage setter gives us a clean integration point. We’ll make the light appear only during evening/night and only for stages that actually emit light.

## Visual Phase 30 — Warm camp lighting

### 1. Add the light node

Open `camp.tscn` and add a `PointLight2D` beneath `Camp`:

```
Camp
└── WarmLight
```

Configure it:

```
Position: 0, -8
Color:    #ffb45f
Energy:   0.85
Visible:  Off
Shadows → Enabled: Off
```

### 2. Create its radial texture

For `WarmLight → Texture`, create a:

```
New GradientTexture2D
```

Configure:

```
Width:  128
Height: 128
Fill:   Radial
Fill From: 0.5, 0.5
Fill To:   1.0, 0.5
```

Open its gradient and create:

```
Offset 0.00: White, alpha 1.0
Offset 0.55: White, alpha 0.45
Offset 1.00: White, alpha 0.0
```

Set:

```
Texture Scale: 1.0
```

### 3. Add the light reference

In `camp.gd`, add:

```
@onready var warm_light: PointLight2D = $WarmLight

var night_lighting_enabled: bool = false
```

Update `_ready()`:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_stage_light()
	queue_redraw()
```

### 4. Update the stage setter

Replace the existing `current_stage` property with:

```
@export var current_stage: CampStage = CampStage.SITE:
	set(value):
		current_stage = value
		queue_redraw()

		if is_node_ready():
			_update_stage_light()
```

### 5. Add the lighting functions

```
func set_night_lighting(enabled: bool) -> void:
	night_lighting_enabled = enabled
	_update_stage_light()


func _update_stage_light() -> void:
	if not night_lighting_enabled:
		warm_light.hide()
		return

	match current_stage:
		CampStage.CAMPFIRE:
			warm_light.position = Vector2(0.0, -4.0)
			warm_light.energy = 0.9
			warm_light.texture_scale = 0.9
			warm_light.show()

		CampStage.CABIN:
			warm_light.position = Vector2(0.0, -18.0)
			warm_light.energy = 0.7
			warm_light.texture_scale = 1.35
			warm_light.show()

		_:
			warm_light.hide()
```

The site and foundation do not produce light.

### 6. Connect it to the day phase

At the end of `_update_world_tint()` in `game_manager.gd`, add:

```
var normalized_phase := phase.to_lower()

camp.set_night_lighting(
	normalized_phase == "evening"
	or normalized_phase == "night"
)
```

Now:

- The campfire emits a compact glow during evening and night.
- The cabin emits a larger, softer glow.
- The empty site and foundation remain dark.
- All lights switch off during morning and afternoon.