Next is the UI click: a tiny, warm wooden tick for opening/closing menus and pressing interface buttons. It will be deliberately quieter than gathering and construction so the interface never feels noisy.

### 1. Import it
![[ui_click_01.wav]]
Place it here:

```
res://assets/audio/sfx/ui_click_01.wav
```

Keep looping disabled.

### 2. Add one shared UI audio player

In `game.tscn`, add an `AudioStreamPlayer` beneath `Interface`:

```
Interface
├── HUD
├── CampMenu
├── ResultScreen
└── UISound
```

Configure it:

```
Stream: ui_click_01.wav
Autoplay: Off
Volume dB: -8
```

Use `AudioStreamPlayer`, not `AudioStreamPlayer2D`, because interface sounds should not change volume based on world position.

### 3. Add the reference

In `game_manager.gd`, add:

```
@onready var ui_sound: AudioStreamPlayer = (
	$Interface/UISound
)
```

Add this reusable function:

```
func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()
```

### 4. Play it when opening the camp menu

Inside `_open_camp_menu()`, after assigning `active_camp`, add:

```
_play_ui_click()
```

```
func _open_camp_menu(camp: Camp) -> void:
	active_camp = camp
	_play_ui_click()

	# Keep the existing function below.
```

### 5. Play it when closing

At the beginning of `_close_camp_menu()`:

```
func _close_camp_menu() -> void:
	_play_ui_click()

	camp_menu.close_menu()
```

### 6. Play it when pressing Build

Inside `_on_camp_build_requested()`, after verifying that `active_camp` exists:

```
func _on_camp_build_requested() -> void:
	if active_camp == null:
		return

	_play_ui_click()

	var costs := active_camp.get_next_stage_cost()
```

The UI click is deliberately quiet. A successful upgrade will produce the small click first, followed immediately by the stronger positional construction sound.