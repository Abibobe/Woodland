Next I’ll create one exact `64 × 32` result strip: a warm completed-cabin emblem for victory and a cold winter emblem for defeat. The result script will select the correct `32 × 32` region automatically.

### 1. Import it
![[result_icons.png]]
Place it here:

```
res://assets/ui/result_icons.png
```

Use lossless compression and disable mipmaps.

### 2. Add the icon node

Inside the result panel’s `Content` container, add `ResultIcon`:

```
Content
├── TitleLabel
├── ResultIcon
├── MessageLabel
├── StatsLabel
└── RestartButton
```

Configure it:

```
Custom Minimum Size: 32 × 32
Expand Mode: Ignore Size
Stretch Mode: Keep Aspect Centered
Mouse Filter: Ignore
```

### 3. Add the texture property

Near the top of `result_screen.gd`:

```
@export_category("Visuals")
@export var result_icons_texture: Texture2D
```

Add the node reference:

```
@onready var result_icon: TextureRect = (
	$Panel/MarginContainer/Content/ResultIcon
)
```

### 4. Add the selection function

```
func _set_result_icon(title: String) -> void:
	if result_icons_texture == null:
		result_icon.hide()
		return

	var source_x: float

	match title:
		"Victory":
			source_x = 0.0

		"Defeat":
			source_x = 32.0

		_:
			result_icon.hide()
			return

	var atlas_texture := AtlasTexture.new()

	atlas_texture.atlas = result_icons_texture
	atlas_texture.region = Rect2(
		source_x,
		0.0,
		32.0,
		32.0
	)

	result_icon.texture = atlas_texture
	result_icon.show()
```

### 5. Call it from `show_result()`

After setting the labels:

```
title_label.text = title
message_label.text = message
stats_label.text = _format_stats(stats)

_set_result_icon(title)
```

### 6. Assign the strip

Select the root `ResultScreen` and assign:

```
Visuals → Result Icons Texture: result_icons.png
```

Increase the panel height slightly:

```
panel.size = Vector2(420.0, 285.0)
```

The result screen will now automatically show the warm cabin emblem for victory and the cold winter emblem for defeat.