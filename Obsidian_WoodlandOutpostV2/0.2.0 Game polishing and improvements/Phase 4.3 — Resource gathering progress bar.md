We’ll add one small pixel-style progress bar to `resource_node.tscn`. It will appear while gathering and preserve its value when hidden.

### 1. Add the bar to the resource scene

Open:

```
res://scenes/resources/resource_node.tscn
```

Add a `ProgressBar` as a direct child of `ResourceNode`:

```
ResourceNode
├── ...
└── GatheringProgressBar
```

Its position and appearance will be configured by code, so you don’t need to adjust its offsets manually.

### 2. Reference it in `resource_node.gd`

Below the existing `@onready` variables, add:

```
@onready var gathering_progress_bar: ProgressBar = (
	$GatheringProgressBar
)
```

### 3. Configure it in `_ready()`

Replace `_ready()` with:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_configure_gathering_progress_bar()
	_update_gathering_progress_bar()
	gathering_progress_bar.hide()

	queue_redraw()
```

### 4. Add the progress-bar configuration

Add these functions beneath `_ready()`:

```
func _configure_gathering_progress_bar() -> void:
	gathering_progress_bar.min_value = 0.0
	gathering_progress_bar.max_value = 1.0
	gathering_progress_bar.step = 0.01
	gathering_progress_bar.show_percentage = false

	gathering_progress_bar.size = Vector2(
		40.0,
		7.0
	)

	gathering_progress_bar.position = Vector2(
		-20.0,
		_get_progress_bar_y()
	)

	gathering_progress_bar.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	gathering_progress_bar.z_as_relative = false
	gathering_progress_bar.z_index = 200

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#17231d")
	background_style.border_color = Color("#08100c")
	background_style.set_border_width_all(1)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#f2d479")
	fill_style.border_color = Color("#fff0a3")
	fill_style.set_border_width_all(1)

	gathering_progress_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	gathering_progress_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)


func _get_progress_bar_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -62.0

		ResourceTypes.Type.STONE:
			return -30.0

		ResourceTypes.Type.FOOD:
			return -36.0

	return -40.0
```

These different heights place the bar above each sprite rather than at one fixed height.

### 5. Add the display functions

Add:

```
func set_gathering_active(active: bool) -> void:
	if is_depleted:
		gathering_progress_bar.hide()
		return

	_update_gathering_progress_bar()
	gathering_progress_bar.visible = active


func _update_gathering_progress_bar() -> void:
	gathering_progress_bar.value = (
		get_gathering_ratio()
	)
```

### 6. Update `advance_gathering()`

Replace it with:

```
func advance_gathering(delta: float) -> bool:
	if is_depleted:
		return false

	gathering_elapsed = minf(
		gathering_elapsed + delta,
		get_gathering_duration()
	)

	_update_gathering_progress_bar()

	return is_gathering_complete()
```

### 7. Update `complete_gathering()`

Replace it with:

```
func complete_gathering(
	requested_amount: int = 1
) -> int:
	if not is_gathering_complete():
		return 0

	var gathered_amount := collect(
		requested_amount
	)

	if gathered_amount > 0:
		gathering_elapsed = 0.0
		_update_gathering_progress_bar()
		set_gathering_active(false)

	return gathered_amount
```

### 8. Update `player_interaction.gd`

In `_start_gathering()`, add:

```
resource.set_gathering_active(true)
```

The complete function should be:

```
func _start_gathering(resource: ResourceNode) -> void:
	if resource == null:
		return

	if resource.is_depleted:
		return

	active_gathering_resource = resource
	gathering_request_sent = false

	resource.set_gathering_active(true)
```

Replace `_stop_gathering()` with:

```
func _stop_gathering() -> void:
	if is_instance_valid(active_gathering_resource):
		active_gathering_resource.set_gathering_active(
			false
		)

	active_gathering_resource = null
	gathering_request_sent = false
```

Finally, in `_process()`, find:

```
if player.velocity.length_squared() > 0.0:
	return
```

Replace it with:

```
if player.velocity.length_squared() > 0.0:
	active_gathering_resource.set_gathering_active(
		false
	)
	return

active_gathering_resource.set_gathering_active(true)
```

## Test

- Hold `E`: the golden bar should appear and fill.
- Release `E`: it should disappear.
- Hold again: it should resume from the saved value.
- Move while holding: it should disappear and stop advancing.
- Stop moving while still holding: it should reappear and resume.
- Complete gathering: the bar should reset.
- With a full backpack: the bar should remain complete until you release `E`, while the resource remains available.