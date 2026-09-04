The embers will appear only when:

- The camp is at the `CAMPFIRE` stage.
- Night lighting is enabled.
- The warm light is visible.

### 1. Add ember settings

In camp.gd Below the visual exports, add:

```
@export_category("Campfire Embers")
@export_range(0, 16) var ember_count := 7
@export_range(4.0, 48.0, 1.0) var ember_height := 28.0
@export var ember_color := Color("#f5c451")
@export var ember_hot_color := Color("#fff0a3")
```

### 2. Replace `_draw()`

Your current function returns immediately after drawing the texture, which would prevent embers from being drawn. Replace it with:

```
func _draw() -> void:
	_draw_stage_shadow()

	if stages_texture != null:
		_draw_stage_texture()
	else:
		match current_stage:
			CampStage.SITE:
				_draw_site()

			CampStage.CAMPFIRE:
				_draw_campfire()

			CampStage.FOUNDATION:
				_draw_foundation()

			CampStage.CABIN:
				_draw_cabin()

	if (
		current_stage == CampStage.CAMPFIRE
		and night_lighting_enabled
		and warm_light.visible
	):
		_draw_campfire_embers()
```

This works with both your texture strip and the fallback procedural camp drawings.

### 3. Add the ember drawing function

Add this beneath `_draw_campfire()`:

```
func _draw_campfire_embers() -> void:
	if ember_count <= 0:
		return

	var ember_origin := Vector2(0.0, -7.0)

	for ember_index in range(ember_count):
		var phase_offset := (
			float(ember_index)
			* TAU
			/ float(ember_count)
		)

		var speed_variation := (
			1.0
			+ float(ember_index % 3) * 0.17
		)

		var ember_time := (
			light_animation_time
			* speed_variation
			+ phase_offset
		)

		var cycle := fposmod(
			ember_time * 0.75,
			1.0
		)

		var horizontal_movement := (
			sin(ember_time * 3.0)
			* (3.0 + float(ember_index % 3))
		)

		var vertical_movement := (
			-cycle * ember_height
		)

		var draw_position := (
			ember_origin
			+ Vector2(
				horizontal_movement,
				vertical_movement
			)
		)

		var fade := sin(cycle * PI)

		var selected_color := ember_color

		if ember_index % 3 == 0:
			selected_color = ember_hot_color

		selected_color.a = fade * 0.85

		draw_circle(
			draw_position,
			1.6,
			Color(
				selected_color.r,
				selected_color.g,
				selected_color.b,
				selected_color.a * 0.18
			)
		)

		draw_circle(
			draw_position,
			0.8,
			selected_color
		)
```

The particles rise, drift sideways, fade in and out, and restart at different times.

### 4. Update `set_night_lighting()`

Replace it with:

```
func set_night_lighting(enabled: bool) -> void:
	night_lighting_enabled = enabled
	_update_stage_light()
	queue_redraw()
```

This ensures the embers appear and disappear immediately when the day phase changes.

### 5. Update `_process()`

At the end of the existing function, after setting `warm_light.texture_scale`, add:

```
queue_redraw()
```

The complete ending should be:

```
warm_light.texture_scale = (
	0.9
	+ primary_flicker * 0.35
)

queue_redraw()
```

### Expected result

- No embers at the empty camp site.
- Embers appear around the built campfire at night.
- Each ember rises and drifts independently.
- The campfire light continues flickering normally.
- Embers disappear immediately in the morning.
- Foundation and cabin stages do not show campfire embers.
- No particles, collisions, or additional scene nodes are required.

Start with `Ember Count: 7` and `Ember Height: 28`. That should remain subtle enough for the current pixel-art scale.