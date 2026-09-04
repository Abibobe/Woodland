### 1. Add the feedback interval

In `resource_node.gd`, under the gathering exports, add:

```
@export_range(0.1, 2.0, 0.05) var gathering_feedback_interval := 0.45
```

Near `gathering_elapsed`, add:

```
var gathering_feedback_elapsed := 0.0
var gathering_active := false
```

### 2. Update `set_gathering_active()`

Replace it with:

```
func set_gathering_active(active: bool) -> void:
	if is_depleted:
		gathering_active = false
		gathering_progress_bar.hide()
		return

	if active and not gathering_active:
		# Produce immediate feedback when gathering begins.
		gathering_feedback_elapsed = (
			gathering_feedback_interval
		)

	gathering_active = active

	_update_gathering_progress_bar()
	gathering_progress_bar.visible = active
```

### 3. Update `advance_gathering()`

Replace it with:

```
func advance_gathering(delta: float) -> bool:
	if is_depleted:
		return false

	gathering_elapsed = minf(
		gathering_elapsed + delta,
		get_gathering_duration()
	)

	_update_gathering_feedback(delta)
	_update_gathering_progress_bar()

	return is_gathering_complete()
```

### 4. Add the feedback function

Add beneath `advance_gathering()`:

```
func _update_gathering_feedback(delta: float) -> void:
	gathering_feedback_elapsed += delta

	if (
		gathering_feedback_elapsed
		< gathering_feedback_interval
	):
		return

	gathering_feedback_elapsed = 0.0

	_play_gather_animation()
	_play_gather_sound()
```

### 5. Allow completion during a feedback animation

Your existing animation uses `is_gather_animation_playing`. Since feedback now happens repeatedly, it must not prevent collection.

Replace the beginning of `interact()`:

```
if is_gather_animation_playing or is_depleted:
	return {}
```

with:

```
if is_depleted:
	return {}
```

Then replace the beginning of `collect()`:

```
if is_gather_animation_playing or is_depleted:
	return 0
```

with:

```
if is_depleted:
	return 0
```

### 6. Avoid playing the sound twice at completion

Because gathering now plays sounds continuously, replace `collect()` with:

```
func collect(requested_amount: int = 1) -> int:
	if is_depleted:
		return 0
	
	var gathered_amount := gather(
		requested_amount
	)
	
	return gather(requested_amount)
```

### 7. Reset feedback after collection

Inside `complete_gathering()`, update the successful section:

```
if gathered_amount > 0:
	gathering_elapsed = 0.0
	gathering_feedback_elapsed = 0.0

	_update_gathering_progress_bar()
	set_gathering_active(false)
```

The complete function should now be:

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
		gathering_feedback_elapsed = 0.0

		_update_gathering_progress_bar()
		set_gathering_active(false)

	return gathered_amount
```

Now gathering should:

- React immediately when `E` is held.
- Shake rhythmically during progress.
- Play the appropriate wood, stone, or food sound repeatedly.
- Continue automatically through multiple units.
- Stop its feedback immediately when released or interrupted.
- Preserve all progress after interruption.