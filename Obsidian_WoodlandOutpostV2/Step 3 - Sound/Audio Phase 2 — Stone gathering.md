
### 1. Import it![[stone_gather_01.wav]]

Place it here:

```
res://assets/audio/sfx/stone_gather_01.wav
```

Keep looping disabled.

### 2. Add the exported property

In `resource_node.gd`, beneath `wood_gather_sound`, add:

```
@export var stone_gather_sound: AudioStream
```

Your audio exports should now be:

```
@export_category("Audio")
@export var wood_gather_sound: AudioStream
@export var stone_gather_sound: AudioStream
```

### 3. Assign it

Open `resource_node.tscn`, select the root, and assign:

```
Audio → Stone Gather Sound: stone_gather_01.wav
```

### 4. Generalize the playback function

Replace `_play_gather_sound()` with:

```
func _play_gather_sound() -> void:
	var selected_sound: AudioStream = null

	match resource_type:
		ResourceTypes.Type.WOOD:
			selected_sound = wood_gather_sound

		ResourceTypes.Type.STONE:
			selected_sound = stone_gather_sound

	if selected_sound == null:
		return

	gather_sound.stream = selected_sound
	gather_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	gather_sound.play()
```

Wood now produces a dry chop, while stone produces a sharper impact. Food remains silent temporarily; we’ll complete the resource sound set with the berry-gathering effect next.