Next I’ll add a distinct “cannot afford” cue: a quiet descending double tone that plays only when construction fails, so it won’t be confused with the normal click or build sound.

### 1. Import it
![[ui_denied_01.wav]]
Place it here:

```
res://assets/audio/sfx/ui_denied_01.wav
```

Keep looping disabled.

### 2. Add a separate audio player

Under `Interface`, add another `AudioStreamPlayer`:

```
Interface
├── HUD
├── CampMenu
├── ResultScreen
├── UISound
└── UIDeniedSound
```

Configure it:

```
Stream: ui_denied_01.wav
Autoplay: Off
Volume dB: -6
```

A separate player allows the denied sound to follow the initial button click without cutting it off.

### 3. Add the reference

In `game_manager.gd`:

```
@onready var ui_denied_sound: AudioStreamPlayer = (
	$Interface/UIDeniedSound
)
```

Add:

```
func _play_ui_denied() -> void:
	if ui_denied_sound.stream == null:
		return

	ui_denied_sound.play()
```

### 4. Trigger it when construction fails

Find this section:

```
if not _can_afford(costs):
	camp_menu.show_message("Not enough resources")
	return
```

Change it to:

```
if not _can_afford(costs):
	_play_ui_denied()
	camp_menu.show_message("Not enough resources")
	return
```

Now an unaffordable build produces:

1. The quiet physical button click.
2. The descending denied cue.
3. The existing “Not enough resources” message.

Successful construction continues into the stronger hammer sound instead.