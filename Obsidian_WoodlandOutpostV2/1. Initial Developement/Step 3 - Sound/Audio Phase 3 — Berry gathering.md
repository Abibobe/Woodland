### 1. Import it
![[food_gather_01.wav]]
Place it here:

```
res://assets/audio/sfx/food_gather_01.wav
```

Keep looping disabled.

### 2. Add the exported property

In `resource_node.gd`, add:

```
@export var food_gather_sound: AudioStream
```

Your audio section should now be:

```
@export_category("Audio")
@export var wood_gather_sound: AudioStream
@export var stone_gather_sound: AudioStream
@export var food_gather_sound: AudioStream
```

### 3. Assign it

In `resource_node.tscn`, assign:

```
Audio → Food Gather Sound: food_gather_01.wav
```

### 4. Complete the sound selector

Add the food branch to `_play_gather_sound()`:

```
func _play_gather_sound() -> void:
	var selected_sound: AudioStream = null

	match resource_type:
		ResourceTypes.Type.WOOD:
			selected_sound = wood_gather_sound

		ResourceTypes.Type.STONE:
			selected_sound = stone_gather_sound

		ResourceTypes.Type.FOOD:
			selected_sound = food_gather_sound

	if selected_sound == null:
		return

	gather_sound.stream = selected_sound
	gather_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	gather_sound.play()
```

The resource audio set is now complete:

- Wood: dry chopping impact.
- Stone: sharp rocky clack.
- Food: soft leafy pluck.

All three retain slight pitch variation while sharing the same audio player and playback logic.