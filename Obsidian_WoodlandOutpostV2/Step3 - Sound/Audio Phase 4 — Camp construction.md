### 1. Import it
![[camp_build_01.wav]]
Place it here:

```
res://assets/audio/sfx/camp_build_01.wav
```

Keep looping disabled.

### 2. Add the audio player

Open `camp.tscn` and add an `AudioStreamPlayer2D`:

```
Camp
├── WarmLight
└── BuildSound
```

Configure `BuildSound`:

```
Autoplay: Off
Volume dB: -2
Max Distance: 800
```

### 3. Add the script properties

In `camp.gd`, add:

```
@export_category("Audio")
@export var build_sound_stream: AudioStream
```

Add the node reference:

```
@onready var build_sound: AudioStreamPlayer2D = (
	$BuildSound
)
```

### 4. Assign the sound

Select the root `Camp` and assign:

```
Audio → Build Sound Stream: camp_build_01.wav
```

### 5. Add the playback function

```
func _play_build_sound() -> void:
	if build_sound_stream == null:
		return

	build_sound.stream = build_sound_stream
	build_sound.pitch_scale = randf_range(
		0.97,
		1.03
	)

	build_sound.play()
```

### 6. Trigger it during construction

Update `advance_construction()`:

```
func advance_construction() -> bool:
	if current_stage == CampStage.CABIN:
		return false

	current_stage += 1

	_play_build_sound()
	_play_construction_animation()

	stage_changed.emit(current_stage)

	return true
```

Every successful upgrade now combines three synchronized feedback layers:

- New stage artwork.
- Scale-and-fade construction animation.
- Two hammer impacts and a settling thump.