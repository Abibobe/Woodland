We’ll build the first walking animation as an exact two-frame strip: `64 × 32`, divided into two guaranteed `32 × 32` cells. The body stays centred in both frames; only arms and legs change, which prevents the sideways “sliding” problem you encountered previously

It contains exactly two `32 × 32` frames:

```
64 × 32 image
├── Frame 1: pixels 0–31
└── Frame 2: pixels 32–63
```


### 1. Import it
![[player_walk_down_strip.png]]
Place it in:

```
res://assets/player/player_walk_down_strip.png
```

Use lossless compression with mipmaps disabled.

### 2. Create the animation

Open `player.tscn` and select `PlayerVisual`.

In the SpriteFrames panel:

1. Add an animation named `walk_down`.
2. Enable looping.
3. Set speed to `6 FPS`.
4. Click **Add Frames from a Sprite Sheet**.
5. Select player_walk_down_strip.png.
6. Set:

```
Horizontal: 2
Vertical:   1
```

7. Select both cells and add them.

Do not use automatic cell dimensions; explicitly use the `2 × 1` split.

### 3. Create a separate animation controller

Attach a script to `PlayerVisual`:

```
res://scripts/player/player_animation.gd
```

Add:

```
class_name PlayerAnimation
extends AnimatedSprite2D


@onready var player: Player = get_parent()


func _process(_delta: float) -> void:
	if player.velocity.length_squared() > 0.0:
		_play_if_changed("walk_down")
	else:
		_play_if_changed("idle_down")


func _play_if_changed(animation_name: StringName) -> void:
	if animation == animation_name:
		return

	play(animation_name)
```

This preserves the responsibility split:

- `player.gd` controls movement.
- `player_animation.gd` observes movement and chooses an animation.
- `PlayerVisual` displays the selected frames.

Run the game. The character should alternate steps while moving and return to the idle frame when stopped. For now, the same front-facing animation plays in every direction; we’ll add directional visuals without changing this structure.