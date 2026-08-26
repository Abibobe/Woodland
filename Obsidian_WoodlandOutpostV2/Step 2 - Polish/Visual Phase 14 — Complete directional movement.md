We’ll complete directional movement with the upward-facing strip: idle, step A, and step B. As before, every frame stays centred in an exact 32×32 cell so movement remains visually stable.

he upward-facing strip is ready: player_up_strip.png.

Its three cells are:

```
Frame 0: idle up
Frame 1: walk up A
Frame 2: walk up B
```

### 1. Import it
	![[player_up_strip.png]]
Place it in:

```
res://assets/player/player_up_strip.png
```

Use lossless compression with mipmaps disabled.

### 2. Create `idle_up`

In the SpriteFrames panel:

1. Add `idle_up`.
2. Split player_up_strip.png into:

```
Horizontal: 3
Vertical:   1
```

3. Add only the first cell.

### 3. Create `walk_up`

Add `walk_up`, using only the second and third cells.

Configure it as:

```
Speed: 6 FPS
Looping: On
```

### 4. Update `player_animation.gd`

Replace it with:

```
class_name PlayerAnimation
extends AnimatedSprite2D


enum Facing {
	DOWN,
	UP,
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

	flip_h = false

	if movement.y < 0.0:
		last_facing = Facing.UP
		_play_if_changed("walk_up")
	else:
		last_facing = Facing.DOWN
		_play_if_changed("walk_down")


func _update_idle_animation() -> void:
	match last_facing:
		Facing.DOWN:
			flip_h = false
			_play_if_changed("idle_down")

		Facing.UP:
			flip_h = false
			_play_if_changed("idle_up")

		Facing.SIDE:
			flip_h = last_side_was_left
			_play_if_changed("idle_side")


func _play_if_changed(
	animation_name: StringName
) -> void:
	if animation == animation_name:
		return

	play(animation_name)
```

Test all directions:

- Down uses `walk_down`.
- Up uses `walk_up`.
- Right uses `walk_side`.
- Left flips `walk_side`.
- Stopping preserves the most recent facing direction.

The player’s movement and animation systems remain separate, and all frames use identical 32×32 alignment.