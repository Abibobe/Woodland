We’ll complete the end-state pair with a restrained defeat cue: three descending, muted notes rather than a harsh alarm. It should communicate failure clearly while fitting the calm woodland tone.

### 1. Import it
![[defeat_01.wav]]
Place it here:

```
res://assets/audio/sfx/defeat_01.wav
```

Keep looping disabled.

### 2. Add the audio player

Under `Interface`, add:

```
DefeatSound
```

It should be an `AudioStreamPlayer` configured as:

```
Stream: defeat_01.wav
Autoplay: Off
Volume dB: -4
```

### 3. Add the reference

In `game_manager.gd`:

```
@onready var defeat_sound: AudioStreamPlayer = (
	$Interface/DefeatSound
)
```

Add:

```
func _play_defeat_sound() -> void:
	if defeat_sound.stream == null:
		return

	defeat_sound.pitch_scale = 1.0
	defeat_sound.play()
```

### 4. Select the correct end-state sound

In `_finish_game()`, replace:

```
if title == "Victory":
	_play_victory_sound()
```

with:

```
match title:
	"Victory":
		_play_victory_sound()

	"Defeat":
		_play_defeat_sound()
```

Now each result has its own audio identity:

- Victory: bright ascending four-note chime.
- Defeat: soft descending three-note phrase.
- Neither sound uses world-position attenuation.