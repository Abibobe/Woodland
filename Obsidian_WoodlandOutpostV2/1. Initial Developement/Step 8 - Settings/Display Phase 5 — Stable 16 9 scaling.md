
Because Woodland Outpost is already designed at `1280 × 720`, we’ll preserve that base rather than changing to a smaller viewport and disrupting the map framing and UI.

### 1. Configure the base window

Open:

```
Project → Project Settings → Display → Window
```

Set:

```
Size
├── Viewport Width:  1280
├── Viewport Height: 720
├── Window Width Override:  1280
└── Window Height Override: 720
```

Godot treats this as the project’s design size rather than changing the monitor’s actual resolution. [Godot: Multiple resolutions](https://docs.godotengine.org/en/latest/tutorials/rendering/multiple_resolutions.html?utm_source=chatgpt.com)

### 2. Configure stretching

Under:

```
Display → Window → Stretch
```

Set:

```
Mode:       Viewport
Aspect:     Keep
Scale:      1.0
Scale Mode: Fractional
```

Why `Fractional` here? Your current base is 1280×720. A 1920×1080 monitor requires a `1.5×` scale. Integer mode would round that down to `1×`, leaving the game at only 1280×720 with large borders. Fractional scaling fills normal 1080p displays while nearest-filtered artwork remains hard-edged.

`Keep` prevents the image from becoming stretched horizontally or vertically on non-16:9 monitors.

### 3. Use exclusive fullscreen

Godot recommends exclusive fullscreen for games because it avoids the one-pixel size reduction that ordinary fullscreen can produce on Windows. [Godot fullscreen guidance](https://docs.godotengine.org/en/latest/tutorials/rendering/multiple_resolutions.html?utm_source=chatgpt.com)

In `display_mode_button.gd`, change:

```
DisplayServer.window_set_mode(
	DisplayServer.WINDOW_MODE_FULLSCREEN
)
```

to:

```
DisplayServer.window_set_mode(
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
)
```

The complete function becomes:

```
func _apply_display_mode(
	fullscreen_enabled: bool
) -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)
```

### 4. Preserve sharp textures

Verify these nodes use:

```
Texture → Filter: Nearest
```

- `GroundRenderer`
- `Entities`
- `PlayerVisual`
- Resource nodes
- Camp
- Any `TextureRect` displaying pixel icons

Labels do not need this setting.

### 5. Test resizing

When using Godot’s embedded game view, select:

```
Stretch to Fit
```

Then test:

- `1280 × 720`
- `1600 × 900`
- `1920 × 1080`
- A non-16:9 window

Expected behavior:

- The game remains centered.
- Circles and characters do not become wider or taller.
- Non-16:9 windows receive black bars.
- HUD elements stay anchored correctly.
- Fullscreen uses the entire 16:9 display.