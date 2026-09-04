### 1. Create the input actions

Open:

**Project → Project Settings → Input Map**

Create these four actions:

|Action|Keys|
|---|---|
|`move_up`|W and Up Arrow|
|`move_down`|S and Down Arrow|
|`move_left`|A and Left Arrow|
|`move_right`|D and Right Arrow|

For each action:

1. Enter its name.
2. Click **Add**.
3. Use the plus button beside it.
4. Select **Key**.
5. Press the desired key.

### 2. Create the player scene

Create a new scene with a **CharacterBody2D** root and name it:

```
Player
```

Add two children:

```
Player (CharacterBody2D)
├── PlayerVisual (Polygon2D)
└── CollisionShape2D
```

### 3. Configure the temporary visual

Select `PlayerVisual`.

In the Inspector, find **Polygon** and add four points:

```
(-10, -14)
(10, -14)
(10, 14)
(-10, 14)
```

Choose a visible colour such as warm yellow:

```
#E8B85C
```

This rectangle is only a placeholder. Later, `PlayerVisual` will be replaced with an animated pixel-art character without changing the movement code.

### 4. Configure the collision

Select `CollisionShape2D`.

Create a new **RectangleShape2D** and set its size to:

```
20 × 28
```

### 5. Create the player script

Attach a script to the root `Player` node and save it as:

```
res://scripts/player/player.gd
```

Use:

```
class_name Player
extends CharacterBody2D


@export_category("Movement")
@export var movement_speed: float = 180.0

@export_category("Map Boundaries")
@export var minimum_position := Vector2(10.0, 14.0)
@export var maximum_position := Vector2(1270.0, 690.0)


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = input_direction * movement_speed

	move_and_slide()
	_keep_inside_map()


func _keep_inside_map() -> void:
	global_position.x = clampf(
		global_position.x,
		minimum_position.x,
		maximum_position.x
	)

	global_position.y = clampf(
		global_position.y,
		minimum_position.y,
		maximum_position.y
	)
```

Save the scene as:

```
res://scenes/player/player.tscn
```

## 6. Add the player to the game

Return to `game.tscn`.

Select the `Actors` node, then click **Instantiate Child Scene** and choose:

```
res://scenes/player/player.tscn
```

Set the instantiated player’s position to approximately:

```
X: 640
Y: 360
```

Your scene tree should now be:

```
Game
├── World
├── Actors
│   └── Player
└── Interface
```

Run the game. You should be able to move the yellow character with WASD or the arrow keys, including diagonally.

The player should stop at the edges of the screen.

NOTE::: The Player element isnt'correctly showed, because the z-index is not setted. Go to the player and change the CanvasItem->Ordering->Z Index == 1
### Small map adjustment

Our current map height is `23 × 32 = 736`, slightly taller than the 720-pixel window. Select `World` and change:

```
Map Height: 22
```

That gives us a map height of 704 pixels, leaving a small area that we can later use for the clean HUD.

At this point, code ownership remains clear:

- `world_generator.gd` owns world generation.
- `player.gd` owns player movement.
- `game.tscn` assembles the independent pieces.

Next, we can generate trees, rocks, and berry bushes while keeping their placement separate from the player and resource-gathering rules.