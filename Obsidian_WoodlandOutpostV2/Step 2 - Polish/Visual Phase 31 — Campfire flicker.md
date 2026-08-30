Let’s add a gentle flicker to the campfire while keeping the cabin light steady.

In `camp.gd`, add:

```
var light_animation_time: float = 0.0
```

Then add:

```
func _process(delta: float) -> void:
	if current_stage != CampStage.CAMPFIRE:
		return

	if not warm_light.visible:
		return

	light_animation_time += delta

	var primary_flicker := sin(
		light_animation_time * 7.0
	) * 0.07

	var secondary_flicker := sin(
		light_animation_time * 13.0
	) * 0.03

	warm_light.energy = (
		0.9
		+ primary_flicker
		+ secondary_flicker
	)

	warm_light.texture_scale = (
		0.9
		+ primary_flicker * 0.35
	)
```

Also reset the animation when configuring the campfire. Inside `_update_stage_light()`, update that branch to:

```
CampStage.CAMPFIRE:
	light_animation_time = 0.0
	warm_light.position = Vector2(0.0, -4.0)
	warm_light.energy = 0.9
	warm_light.texture_scale = 0.9
	warm_light.show()
```

The two overlapping sine waves prevent the glow from feeling like a simple mechanical pulse. Only the campfire flickers; the completed cabin retains a calm, stable light.