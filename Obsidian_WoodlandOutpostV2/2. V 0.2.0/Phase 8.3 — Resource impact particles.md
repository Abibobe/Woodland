### 1. Add the particle node

In `resource_node.tscn`, add this child:

```
ResourceNode
├── ...
├── GatherSound
├── GatheringProgressBar
└── GatherParticles (GPUParticles2D)
```

No Inspector configuration is required; the script will configure it.

### 2. Reference it

In `resource_node.gd`, beneath `gathering_progress_bar`, add:

```
@onready var gather_particles: GPUParticles2D = (
	$GatherParticles
)
```

### 3. Configure the particles

In `_ready()`, add:

```
_configure_gather_particles()
```

The complete beginning becomes:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_configure_gathering_progress_bar()
	_configure_gather_particles()

	_update_gathering_progress_bar()
	gathering_progress_bar.hide()

	queue_redraw()
```

Now add:

```
func _configure_gather_particles() -> void:
	gather_particles.emitting = false
	gather_particles.one_shot = true
	gather_particles.amount = 8
	gather_particles.lifetime = 0.35
	gather_particles.explosiveness = 1.0
	gather_particles.randomness = 0.35
	gather_particles.z_index = 30

	var particle_material := ParticleProcessMaterial.new()

	particle_material.particle_flag_disable_z = true
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 55.0

	particle_material.initial_velocity_min = 22.0
	particle_material.initial_velocity_max = 38.0

	particle_material.gravity = Vector3(
		0.0,
		75.0,
		0.0
	)

	particle_material.scale_min = 1.5
	particle_material.scale_max = 3.0

	match resource_type:
		ResourceTypes.Type.WOOD:
			particle_material.color = Color("#c98b45")
			gather_particles.position = Vector2(0.0, -20.0)

		ResourceTypes.Type.STONE:
			particle_material.color = Color("#a5adb0")
			gather_particles.position = Vector2(0.0, -7.0)

		ResourceTypes.Type.FOOD:
			particle_material.color = Color("#b94d68")
			gather_particles.position = Vector2(0.0, -10.0)

	gather_particles.process_material = particle_material
```

These produce small pixel-like fragments without requiring additional textures.

### 4. Add the burst function

```
func _play_gather_particles() -> void:
	if is_depleted:
		return

	gather_particles.restart()
	gather_particles.emitting = true
```

### 5. Synchronize the effect

Your `_update_gathering_feedback()` currently ends with:

```
_play_gather_animation()
_play_gather_sound()
```

Add the particle call:

```
_play_gather_animation()
_play_gather_sound()
_play_gather_particles()
```

All three effects will now happen on the same 0.45-second rhythm.

## Fix duplicate completion feedback

Your current `gather()` plays another animation when one unit is collected:

```
else:
	_play_gather_animation()
```

Remove that `else` section. The end should be:

```
if resource_amount <= 0:
	is_depleted = true
	set_highlighted(false)
	_play_depletion_animation()

return gathered_amount
```

Then replace `collect()` with:

```
func collect(requested_amount: int = 1) -> int:
	if is_depleted:
		return 0

	return gather(requested_amount)
```

This removes the extra completion sound currently found at lines 498–500.

## Recommended sound adjustment

Your pitch currently varies from `0.6` to `1.5`, which is extremely broad and can make impacts sound unnatural. I recommend:

```
gather_sound.pitch_scale = randf_range(
	0.92,
	1.08
)
```

After these changes, every gathering beat will produce exactly one:

- Resource movement.
- Appropriate sound.
- Colored particle burst.

The animation, audio, and particles will therefore feel like a single impact instead of three unrelated effects.