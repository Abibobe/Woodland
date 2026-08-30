Next we’ll add footsteps, but keep them restrained: one soft grass-and-dirt step per completed two-frame walking cycle, rather than a sound on every animation frame. This should support movement without dominating the other effects.

### 1. Import it
![[footstep_ground_01.wav]]
Place it here:

```
res://assets/audio/sfx/footstep_ground_01.wav
```

Keep looping disabled.

### 2. Add the audio player

Open `player.tscn` and add an `AudioStreamPlayer2D`:

```
Player
├── PlayerShadow
├── PlayerVisual
├── CollisionShape2D
├── PlayerInteraction
└── FootstepSound
```

Configure it:

```
Stream: footstep_ground_01.wav
Autoplay: Off
Volume dB: -12
Max Distance: 450
```

### 3. Update `player_animation.gd`

Add this reference:

```
@onready var footstep_sound: AudioStreamPlayer2D = (
	$"../FootstepSound"
)
```

Add `_ready()`:

```
func _ready() -> void:
	frame_changed.connect(
		_on_animation_frame_changed
	)
```

Then add:

```
func _on_animation_frame_changed() -> void:
	var animation_text := String(animation)

	if not animation_text.begins_with("walk_"):
		return

	if frame != 0:
		return

	if footstep_sound.stream == null:
		return

	footstep_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	footstep_sound.play()
```

The sound plays only on frame `0` of:

```
walk_down
walk_up
walk_side
```

Since each walk animation has two frames at `6 FPS`, this produces approximately three footsteps per second rather than an excessive sound on every frame. Left movement works automatically because it uses the flipped `walk_side` animation.


"cool but I find 2 things a little odd:

1. the sound is not executed as soon the player move
2. seems like that the sound becom lower when the player is fare from the center of the screen
"

Both observations are correct:

1. Waiting for frame `0` means the first sound may not occur until the animation loops.
2. `AudioStreamPlayer2D` attenuates and pans according to distance from the audio listener, normally near the screen/camera centre.

## Fix 1 — Use non-positional footsteps

In `player.tscn`, right-click `FootstepSound` and choose **Change Type**, then change it from:

```
AudioStreamPlayer2D
```

to:

```
AudioStreamPlayer
```

Keep:

```
Stream: footstep_ground_01.wav
Volume dB: -12
Autoplay: Off
```

There will no longer be a `Max Distance` property because the volume is now independent of world position.

Update the script reference:

```
@onready var footstep_sound: AudioStreamPlayer = (
	$"../FootstepSound"
)
```

## Fix 2 — Play immediately when walking starts

Add this variable:

```
var last_footstep_time_ms: int = -1000
```

Replace `_on_animation_frame_changed()` with:

```
func _on_animation_frame_changed() -> void:
	var animation_text := String(animation)

	if not animation_text.begins_with("walk_"):
		return

	if frame != 0:
		return

	_play_footstep()
```

Add the reusable function:

```
func _play_footstep() -> void:
	if footstep_sound.stream == null:
		return

	var current_time_ms := Time.get_ticks_msec()

	if current_time_ms - last_footstep_time_ms < 120:
		return

	last_footstep_time_ms = current_time_ms

	footstep_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	footstep_sound.play()
```

Finally, update `_play_if_changed()`:

```
func _play_if_changed(
	animation_name: StringName
) -> void:
	if animation == animation_name:
		return

	play(animation_name)

	if String(animation_name).begins_with("walk_"):
		_play_footstep()
```

Now the first step plays immediately when movement starts. Later sounds remain synchronized to the walking loop, and the short cooldown prevents an accidental double sound when the animation changes to frame `0`. Volume also remains constant everywhere on the map.