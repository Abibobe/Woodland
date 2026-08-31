Next I’ll add a quiet looping forest ambience—soft wind and leaves with a few distant bird notes. It will be mixed well below footsteps and gameplay sounds, and prepared for seamless looping.

### 1. Import it
![[forest_ambience_loop_01.wav]]
Place it here:

```
res://assets/audio/ambient/forest_ambience_loop_01.wav
```

Select it and enable:

```
Loop Mode: Forward
```

Reimport if Godot requests it.

### 2. Add the ambience player

Add an `AudioStreamPlayer` directly beneath `Game`:

```
Game
├── ForestAmbience
├── WorldTint
├── World
├── Entities
└── Interface
```

Configure:

```
Stream: forest_ambience_loop_01.wav
Autoplay: On
Volume dB: -22
```

Use `AudioStreamPlayer`, not `AudioStreamPlayer2D`, so the ambience remains consistent everywhere.

### 3. Fade it out when the game ends

In `game_manager.gd`, add:

```
@onready var forest_ambience: AudioStreamPlayer = (
	$ForestAmbience
)
```

Add:

```
func _fade_out_ambience() -> void:
	if not forest_ambience.playing:
		return

	var ambience_tween := create_tween()

	ambience_tween.tween_property(
		forest_ambience,
		"volume_db",
		-35.0,
		0.6
	)

	ambience_tween.tween_callback(
		forest_ambience.stop
	)
```

Inside `_finish_game()`, after selecting the victory or defeat sound, add:

```
_fade_out_ambience()
```

The ambience will remain quiet beneath footsteps and interactions, then fade away when the result screen appears so the victory or defeat cue stays clear.