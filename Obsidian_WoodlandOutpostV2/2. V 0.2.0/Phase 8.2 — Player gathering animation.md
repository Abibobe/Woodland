### 1. Update `player_animation.gd`

Add these variables near the top:

```
@export_category("Gathering Animation")
@export_range(0.5, 10.0, 0.1) var gathering_speed := 4.5
@export_range(0.0, 10.0, 0.5) var gathering_bob_amount := 2.0
@export_range(0.0, 15.0, 0.5) var gathering_tilt_degrees := 4.0

var is_gathering := false
var gathering_time := 0.0
var gathering_target_position := Vector2.ZERO
var resting_position := Vector2.ZERO
```

In `_ready()`, save the sprite’s existing position:

```
func _ready() -> void:
	resting_position = position

	frame_changed.connect(
		_on_animation_frame_changed
	)
```

Replace `_process()` with:

```
func _process(delta: float) -> void:
	var movement := player.velocity

	if is_gathering and movement.length_squared() <= 0.0:
		_update_gathering_animation(delta)
		return

	_reset_gathering_transform()

	if movement.length_squared() > 0.0:
		_update_walking_animation(movement)
	else:
		_update_idle_animation()
```

Then add:

```
func start_gathering(
	target_position: Vector2
) -> void:
	is_gathering = true
	gathering_target_position = target_position
	gathering_time = 0.0

	_update_facing_toward(
		gathering_target_position
	)


func stop_gathering() -> void:
	is_gathering = false
	gathering_time = 0.0
	_reset_gathering_transform()


func _update_gathering_animation(delta: float) -> void:
	gathering_time += delta

	_update_facing_toward(
		gathering_target_position
	)
	_update_idle_animation()

	var motion := sin(
		gathering_time
		* gathering_speed
		* TAU
	)

	position = (
		resting_position
		+ Vector2(
			0.0,
			absf(motion) * gathering_bob_amount
		)
	)

	rotation = deg_to_rad(
		motion * gathering_tilt_degrees
	)


func _update_facing_toward(
	target_position: Vector2
) -> void:
	var direction := (
		target_position
		- player.global_position
	)

	if absf(direction.x) > absf(direction.y):
		last_facing = Facing.SIDE
		last_side_was_left = direction.x < 0.0
	elif direction.y < 0.0:
		last_facing = Facing.UP
	else:
		last_facing = Facing.DOWN


func _reset_gathering_transform() -> void:
	position = resting_position
	rotation = 0.0
```

This deliberately reuses your existing idle artwork, so no new sprite sheet is required yet.

### 2. Reference the animation from `player_interaction.gd`

Near its other references, add:

```
@onready var player_animation: PlayerAnimation = (
	$"../PlayerVisual"
)
```

Inside `_start_gathering()`, after setting `active_gathering_resource`, add:

```
player_animation.start_gathering(
	resource.global_position
)
```

The complete function should contain:

```
func _start_gathering(resource: ResourceNode) -> void:
	if resource == null:
		return

	if resource.is_depleted:
		return

	active_gathering_resource = resource
	gathering_request_sent = false

	resource.set_gathering_active(true)

	player_animation.start_gathering(
		resource.global_position
	)
```

### 3. Stop the animation correctly

At the beginning of `_stop_gathering()`, add:

```
player_animation.stop_gathering()
```

Also update the moving section inside `_process()`:

```
if player.velocity.length_squared() > 0.0:
	active_gathering_resource.set_gathering_active(
		false
	)

	player_animation.stop_gathering()
	return
```

When the player stops while still holding `E`, restart it immediately before advancing progress:

```
active_gathering_resource.set_gathering_active(true)

player_animation.start_gathering(
	active_gathering_resource.global_position
)
```

`start_gathering()` currently resets its rhythm, so add this guard at its beginning:

```
if (
	is_gathering
	and gathering_target_position
		== target_position
):
	return
```

The final function begins like this:

```
func start_gathering(
	target_position: Vector2
) -> void:
	if (
		is_gathering
		and gathering_target_position
			== target_position
	):
		return

	is_gathering = true
```

Now the player will:

- Turn toward the selected resource.
- Bob and lean rhythmically while gathering.
- Stop immediately when moving or releasing `E`.
- Resume when gathering resumes.
- Turn automatically toward the next resource while `E` remains held.

This should already make the four-to-six-second actions feel much less static. The next improvement can synchronize a small impact effect with each gathering sound, giving every chop, strike, or berry-pick a visible response.


FIX:::::
Not quite—`player_interaction.gd` is mostly correct, but three essential parts are missing from `player_animation.gd`. As written, the gathering motion will not run, the target position is never stored, and the sprite may jump from `(0, -2)` to `(0, 0)`.

## 1. Fix `_ready()`

Replace it with:

```
func _ready() -> void:
	resting_position = position

	frame_changed.connect(
		_on_animation_frame_changed
	)
```

This preserves the `PlayerVisual` position configured in `player.tscn`.

## 2. Replace `_process()`

Your current `_process()` still handles only walking and idle animations. Replace it with:

```
func _process(delta: float) -> void:
	var movement := player.velocity

	if (
		is_gathering
		and movement.length_squared() <= 0.0
	):
		_update_gathering_animation(delta)
		return

	_reset_gathering_transform()

	if movement.length_squared() > 0.0:
		_update_walking_animation(movement)
	else:
		_update_idle_animation()
```

Notice that the parameter must be `delta`, not `_delta`, because it is now used.

## 3. Complete `start_gathering()`

Your function currently sets only `is_gathering`. It also needs to save the target and reset the animation when the target changes.

Replace it with:

```
func start_gathering(
	target_position: Vector2
) -> void:
	if (
		is_gathering
		and gathering_target_position
			== target_position
	):
		return

	is_gathering = true
	gathering_target_position = target_position
	gathering_time = 0.0

	_update_facing_toward(
		gathering_target_position
	)
```

Without this correction, the player always faces and animates relative to `Vector2.ZERO`.

## 4. Small fix in `player_interaction.gd`

Your normal start, movement interruption, and release handling are correct.

However, when a resource disappears or becomes depleted, the player animation isn’t stopped. Replace this section in `_request_gathering_completion()`:

```
if not is_instance_valid(resource):
	active_gathering_resource = null
	return

if resource.is_depleted:
	resource.set_gathering_active(false)
	active_gathering_resource = null
	return
```

with:

```
if not is_instance_valid(resource):
	player_animation.stop_gathering()
	active_gathering_resource = null
	return

if resource.is_depleted:
	resource.set_gathering_active(false)
	player_animation.stop_gathering()
	active_gathering_resource = null
	return
```

On the next frame, holding `E` can still select another nearby resource and start the animation again.

After these corrections, the implementation is complete. Test these cases:

- Hold `E`: the player turns toward the resource and moves rhythmically.
- Release `E`: the sprite returns exactly to its original position and rotation.
- Walk while holding: gathering animation stops.
- Stop walking while still holding: animation resumes.
- Deplete a resource: the player switches cleanly to the next nearby resource.
- Gather resources on every side: facing direction updates correctly.