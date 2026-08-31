Next we’ll give nighttime its own ambience: quieter wind, soft crickets, and a distant low woodland call. Then we’ll crossfade between the existing daytime forest loop and the night loop using the same phase signal that controls the world tint.

### 1. Import it
![[forest_night_loop_01.wav]]
Place it here:

```
res://assets/audio/ambient/forest_night_loop_01.wav
```

Enable:

```
Loop Mode: Forward
```

### 2. Add the night player

Add another `AudioStreamPlayer` beneath `Game`:

```
Game
├── ForestAmbience
├── NightAmbience
├── WorldTint
└── ...
```

Configure `NightAmbience`:

```
Stream: forest_night_loop_01.wav
Autoplay: On
Volume dB: -80
```

Both loops run continuously; changing only their volumes keeps the transition smooth.

### 3. Add the reference and tween

In `game_manager.gd`:

```
@onready var night_ambience: AudioStreamPlayer = (
	$NightAmbience
)

var ambience_crossfade_tween: Tween
```

### 4. Add the crossfade function

```
func _update_ambience(phase: String) -> void:
	var use_night_ambience := (
		phase == "evening"
		or phase == "night"
	)

	var day_volume := -80.0 if use_night_ambience else -22.0
	var night_volume := -21.0 if use_night_ambience else -80.0

	if ambience_crossfade_tween != null:
		ambience_crossfade_tween.kill()

	ambience_crossfade_tween = create_tween()
	ambience_crossfade_tween.set_parallel(true)

	ambience_crossfade_tween.tween_property(
		forest_ambience,
		"volume_db",
		day_volume,
		2.0
	)

	ambience_crossfade_tween.tween_property(
		night_ambience,
		"volume_db",
		night_volume,
		2.0
	)
```

### 5. Connect it to the phase

At the end of `_update_world_tint()`, you already have:

```
var normalized_phase := phase.to_lower()
```

Add:

```
_update_ambience(normalized_phase)
```

### 6. Replace `_fade_out_ambience()`

```
func _fade_out_ambience() -> void:
	if ambience_crossfade_tween != null:
		ambience_crossfade_tween.kill()

	ambience_crossfade_tween = create_tween()
	ambience_crossfade_tween.set_parallel(true)

	ambience_crossfade_tween.tween_property(
		forest_ambience,
		"volume_db",
		-80.0,
		0.6
	)

	ambience_crossfade_tween.tween_property(
		night_ambience,
		"volume_db",
		-80.0,
		0.6
	)

	ambience_crossfade_tween.set_parallel(false)

	ambience_crossfade_tween.tween_callback(
		func() -> void:
			forest_ambience.stop()
			night_ambience.stop()
	)
```

The daytime birds and leaves will now fade into quieter wind and crickets during evening, then return smoothly the next morning.