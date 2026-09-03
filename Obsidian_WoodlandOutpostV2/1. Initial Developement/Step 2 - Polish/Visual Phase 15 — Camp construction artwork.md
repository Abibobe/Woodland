Next we’ll polish the camp with one exact four-stage strip—site, campfire, foundation, and completed cabin. Each stage occupies a 64×64 cell, so construction can change artwork without changing the camp’s position or collision.

It contains four exact `64 × 64` cells:

```
0: Construction site
1: Campfire
2: Foundation
3: Cabin
```

### 1. Import it
![[camp_stages_strip.png]]
Place it in:

```
res://assets/buildings/camp_stages_strip.png
```

Use lossless compression with mipmaps disabled.

### 2. Add the texture property

In `camp.gd`, add:

```
@export_category("Visuals")
@export var stages_texture: Texture2D
```

Update `_ready()`:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
```

### 3. Update `_draw()`

Add this at the beginning of `_draw()`:

```
func _draw() -> void:
	if stages_texture != null:
		_draw_stage_texture()
		return

	match current_stage:
		CampStage.SITE:
			_draw_site()

		CampStage.CAMPFIRE:
			_draw_campfire()

		CampStage.FOUNDATION:
			_draw_foundation()

		CampStage.CABIN:
			_draw_cabin()
```

The existing drawing functions remain as fallbacks.

### 4. Add the stage texture function

```
func _draw_stage_texture() -> void:
	var frame_size := Vector2(64.0, 64.0)

	var source_rect := Rect2(
		Vector2(
			int(current_stage) * frame_size.x,
			0.0
		),
		frame_size
	)

	var destination_rect := Rect2(
		Vector2(-32.0, -48.0),
		frame_size
	)

	draw_texture_rect_region(
		stages_texture,
		destination_rect,
		source_rect
	)
```

### 5. Assign it

Open `camp.tscn`, select the root `Camp`, and assign:

```
Visuals → Stages Texture: camp_stages_strip.png
```

Run the game and build each stage. The camp should switch cleanly between the four cells without moving or changing its collision.