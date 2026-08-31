Next we’ll add the victory cue: a short ascending four-note woodland-style chime that plays when the cabin is completed or the survival period ends successfully. It will sit above the UI sounds without being overly loud.

### 1. Import it
![[victory_01.wav]]
Place it here:

```
res://assets/audio/sfx/victory_01.wav
```

Keep looping disabled.

### 2. Add the audio player

Under `Interface`, add an `AudioStreamPlayer`:

```
Interface
├── HUD
├── CampMenu
├── ResultScreen
├── UISound
├── UIDeniedSound
└── VictorySound
```

Configure it:

```
Stream: victory_01.wav
Autoplay: Off
Volume dB: -3
```

### 3. Add the reference

In `game_manager.gd`:

```
@onready var victory_sound: AudioStreamPlayer = (
	$Interface/VictorySound
)
```

Add:

```
func _play_victory_sound() -> void:
	if victory_sound.stream == null:
		return

	victory_sound.pitch_scale = 1.0
	victory_sound.play()
```

### 4. Trigger it from `_finish_game()`

Inside `_finish_game()`, add this immediately after:

```
game_finished = true
active_camp = null
```

Add:

```
if title == "Victory":
	_play_victory_sound()
```

That section becomes:

```
game_finished = true
active_camp = null

if title == "Victory":
	_play_victory_sound()

day_cycle.set_running(false)
```

Both victory paths already call `_finish_game("Victory", ...)`, so the cue plays correctly whether the player completes the cabin directly or survives until winter with the cabin ready.