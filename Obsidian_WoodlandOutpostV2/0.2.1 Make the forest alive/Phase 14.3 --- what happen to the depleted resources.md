
 Instead of resources suddenly disappearing, gathering would visibly transform the forest:

- Tree → cut stump
- Berry bush → leafier but visibly empty bush
- Rock → shallow excavated hole with a few loose stones

The depleted version should:

- Replace the normal sprite immediately after gathering.
- Remain permanently in the world.
- Disable interaction and the gathering progress bar.
- Disable its collision, so dozens of depleted objects do not obstruct movement.
- Use slightly darker, less saturated colors so active resources remain easy to recognize.

This also gives the player useful environmental storytelling: explored areas gradually show visible signs of harvesting.

Implementation-wise, I’d change `ResourceNode` so depletion no longer calls `queue_free()`. Instead, it would run something like:

```
func _become_depleted() -> void:
	is_depleted = true
	gathering_active = false

	gathering_progress_bar.hide()
	interaction_area.monitoring = false

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			true
		)

	queue_redraw()
```

Then the drawing code chooses between two sprite collections:

```
func _get_current_texture() -> Texture2D:
	if is_depleted:
		return _get_depleted_texture()

	return _get_resource_texture()
```

I recommend creating three depleted sprites at the same `96 × 96` canvas size as the current resources, with their ground contact and baked shadows aligned identically. That will let us swap them without any visible jumping.

One important consequence: the map will gradually fill with stumps, empty bushes, and holes, but this is desirable here. It prevents the world from looking as though nothing happened while still clearly communicating that these objects cannot be gathered again.

Send me the latest `resource_node.gd` and `resource_node.tscn` before we implement it. I’ll adapt the change to the current larger-sprite system, and then we can create a matching depleted-resource sprite pack.

## 1. Add the depleted textures

In `resource_node.gd`, beneath your visual variant arrays, add:

```
@export_category("Depleted Visuals")
@export var depleted_tree_texture: Texture2D
@export var depleted_rock_texture: Texture2D
@export var depleted_bush_texture: Texture2D
```

Add a reference to the collision shape:

```
@onready var collision_shape: CollisionShape2D = (
	$CollisionShape2D
)
```

## 2. Draw the depleted resource

Replace `_draw()` with:

```
func _draw() -> void:
	if is_depleted:
		_draw_depleted_resource()
		return

	match resource_type:
		ResourceTypes.Type.WOOD:
			_draw_tree()

		ResourceTypes.Type.STONE:
			_draw_rock()

		ResourceTypes.Type.FOOD:
			_draw_berry_bush()
```

Then add:

```
func _draw_depleted_resource() -> void:
	var depleted_texture: Texture2D = null
	var visual_scale := 1.0

	match resource_type:
		ResourceTypes.Type.WOOD:
			depleted_texture = depleted_tree_texture
			visual_scale = tree_visual_scale

		ResourceTypes.Type.STONE:
			depleted_texture = depleted_rock_texture
			visual_scale = rock_visual_scale

		ResourceTypes.Type.FOOD:
			depleted_texture = depleted_bush_texture
			visual_scale = bush_visual_scale

	if depleted_texture == null:
		_draw_depleted_fallback()
		return

	_draw_grounded_texture(
		depleted_texture,
		visual_scale
	)
```

Add this temporary fallback so the game remains usable before the new sprites are assigned:

```
func _draw_depleted_fallback() -> void:
	match resource_type:
		ResourceTypes.Type.WOOD:
			draw_rect(
				Rect2(-9.0, -5.0, 18.0, 10.0),
				Color("#70482b")
			)

			draw_rect(
				Rect2(-6.0, -6.0, 12.0, 4.0),
				Color("#c08a52")
			)

		ResourceTypes.Type.STONE:
			draw_ellipse_hole()

		ResourceTypes.Type.FOOD:
			draw_circle(
				Vector2(0.0, -3.0),
				14.0,
				Color("#365d39")
			)
```

Godot does not have a built-in `draw_ellipse()`, so add this small hole function:

```
func draw_ellipse_hole() -> void:
	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2(1.0, 0.45)
	)

	draw_circle(
		Vector2.ZERO,
		14.0,
		Color("#513c2c")
	)

	draw_circle(
		Vector2(0.0, 2.0),
		10.0,
		Color("#2d281f")
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)
```

These fallbacks are only placeholders until we create the proper pixel-art versions.

## 3. Replace the depletion animation

Replace the existing `_play_depletion_animation()` entirely with:

```
func _play_depletion_animation() -> void:
	is_gather_animation_playing = true
	gathering_active = false

	gathering_progress_bar.hide()
	interaction_highlight.hide()
	gather_particles.emitting = false

	collision_layer = 0
	collision_mask = 0

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			true
		)

	if interaction_tween != null:
		interaction_tween.kill()

	interaction_tween = create_tween()

	interaction_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.12
	)

	interaction_tween.tween_callback(
		func() -> void:
			queue_redraw()
	)

	interaction_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.18
	)

	interaction_tween.tween_callback(
		func() -> void:
			is_gather_animation_playing = false
	)
```

Your `gather()` function already sets:

```
is_depleted = true
set_highlighted(false)
_play_depletion_animation()
```

So no further change is required there.

Your `GameManager` also already does the correct thing:

```
if resource.is_depleted:
	player_interaction.remove_target(resource)
```

This removes the depleted object from interaction without deleting its visual representation.

## 4. Add the images to the scene

After creating the three sprites, place them somewhere like:

```
res://assets/resources/depleted/
├── tree_stump.png
├── empty_bush.png
└── rock_hole.png
```

Then select `ResourceNode` and assign them under:

```
Depleted Visuals
├── Depleted Tree Texture
├── Depleted Rock Texture
└── Depleted Bush Texture
```

Make each sprite `96 × 96`, transparent, pixel-art, and aligned to the same bottom ground point as your current V5 resources. The resource will then fade briefly from its active form into its depleted form without moving or disappearing.

![[tree_stump.png]]

![[empty_bush.png]]

![[rock_hole.png]]

Each sprite has:

- A transparent `96 × 96` canvas
- Pixel-art rendering matching your V5 resources
- A shared ground baseline
- A contained, connected shadow
- Enough visual difference to communicate depletion clearly

They were generated using the existing V5 atlas as the style reference, with separate prompts for a cut stump, berryless bush, and mined-out hole.

Import the three PNGs into `res://assets/resources/depleted/`, then assign them to the new **Depleted Visuals** fields on `ResourceNode`.

The stomp loook a lot bigger? 
Yes, I see it—the stump especially is almost as visually dominant as a living tree. This happens because depleted sprites currently reuse the enlarged active-resource scales.

Give depleted resources their own smaller scales.

Under `Depleted Visuals`, add:

```
@export_category("Depleted Visual Scale")
@export_range(0.3, 1.5, 0.05) var stump_visual_scale := 0.70
@export_range(0.3, 1.5, 0.05) var empty_bush_visual_scale := 0.78
@export_range(0.3, 1.5, 0.05) var rock_hole_visual_scale := 0.68
```

Then replace `_draw_depleted_resource()` with:

```
func _draw_depleted_resource() -> void:
	var depleted_texture: Texture2D = null
	var visual_scale := 1.0

	match resource_type:
		ResourceTypes.Type.WOOD:
			depleted_texture = depleted_tree_texture
			visual_scale = stump_visual_scale

		ResourceTypes.Type.STONE:
			depleted_texture = depleted_rock_texture
			visual_scale = rock_hole_visual_scale

		ResourceTypes.Type.FOOD:
			depleted_texture = depleted_bush_texture
			visual_scale = empty_bush_visual_scale

	if depleted_texture == null:
		_draw_depleted_fallback()
		return

	_draw_grounded_texture(
		depleted_texture,
		visual_scale
	)
```

This should produce a better hierarchy:

- Living trees remain tall and important.
- Stumps become small traces left on the ground.
- Empty bushes remain recognizable without resembling active berry bushes.
- Rock holes read as ground details rather than new obstacles.

Because `_draw_grounded_texture()` compensates for the transparent bottom padding, all three sprites should remain correctly attached to their original ground position despite the smaller scale.

If the stump still attracts too much attention, reduce only:

```
stump_visual_scale = 0.60
```

The bright cut surface makes it naturally more noticeable, so it can comfortably be smaller than the other depleted sprites.