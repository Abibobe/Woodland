Next we’ll add one side-facing strip with three exact cells: idle, step A, and step B. The same artwork will serve both right and left movement by flipping it horizontally, so we avoid duplicating assets and keep the animation controller small.


The side-facing strip is ready: player_side_strip.png.

It contains three exact `32 × 32` cells:

```
Frame 0: idle right
Frame 1: walk right A
Frame 2: walk right B
```

### 1. Import it
![[player_side_strip.png]]
Place it in:

```
res://assets/player/player_side_strip.png
```

Use lossless compression and disable mipmaps.

### 2. Add `idle_side`

In `PlayerVisual`’s SpriteFrames panel:

1. Add an animation named `idle_side`.
2. Choose **Add Frames from a Sprite Sheet**.
3. Select player_side_strip.png.
4. Set:

```
Horizontal: 3
Vertical:   1
```

5. Select only the first cell.

### 3. Add `walk_side`

Create another animation:

```
walk_side
```

Use the same `3 × 1` split, but select only the second and third cells.

Configure:

```
Speed: 6 FPS
Looping: On
```

### 4. Replace `player_animation.gd`

```
class_name PlayerAnimation
extends AnimatedSprite2D


enum Facing {
	DOWN,
	SIDE
}


@onready var player: Player = get_parent()


var last_facing: Facing = Facing.DOWN
var last_side_was_left: bool = false


func _process(_delta: float) -> void:
	var movement := player.velocity

	if movement.length_squared() > 0.0:
		_update_walking_animation(movement)
	else:
		_update_idle_animation()


func _update_walking_animation(
	movement: Vector2
) -> void:
	if absf(movement.x) > absf(movement.y):
		last_facing = Facing.SIDE
		last_side_was_left = movement.x < 0.0

		flip_h = last_side_was_left
		_play_if_changed("walk_side")
		return

	last_facing = Facing.DOWN
	flip_h = false

	_play_if_changed("walk_down")


func _update_idle_animation() -> void:
	match last_facing:
		Facing.SIDE:
			flip_h = last_side_was_left
			_play_if_changed("idle_side")

		Facing.DOWN:
			flip_h = false
			_play_if_changed("idle_down")


func _play_if_changed(
	animation_name: StringName
) -> void:
	if animation == animation_name:
		return

	play(animation_name)
```

Run the game:

- Moving right uses the original side artwork.
- Moving left flips the same artwork.
- Stopping preserves the last horizontal direction.
- Vertical movement still uses the downward animation temporarily.

This gives us four-way movement behaviour with only one missing visual direction: upward-facing artwork.