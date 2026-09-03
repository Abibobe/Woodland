Before generating hundreds of resources, we’ll create and test one reusable resource component. Trees, rocks, and berry bushes will all use the same scene.
### 1. Create a new scene

Create a new scene with a **StaticBody2D** root:

```
ResourceNode
```

Add:

```
ResourceNode (StaticBody2D)
└── CollisionShape2D
```

Select `CollisionShape2D` and create a `RectangleShape2D`:

```
Size: 24 × 24
Position: 0, -6
```

### 2. Add the resource script

Attach a script to `ResourceNode` and save it as:

```
res://scripts/resources/resource_node.gd
```

Add:

```
class_name ResourceNode
extends StaticBody2D


enum ResourceType {
	WOOD,
	STONE,
	FOOD
}


@export var resource_type: ResourceType = ResourceType.WOOD:
	set(value):
		resource_type = value
		queue_redraw()

@export_range(1, 10) var resource_amount: int = 3


func _ready() -> void:
	queue_redraw()


func get_resource_name() -> String:
	match resource_type:
		ResourceType.WOOD:
			return "Wood"

		ResourceType.STONE:
			return "Stone"

		ResourceType.FOOD:
			return "Food"

	return "Unknown"


func _draw() -> void:
	match resource_type:
		ResourceType.WOOD:
			_draw_tree()

		ResourceType.STONE:
			_draw_rock()

		ResourceType.FOOD:
			_draw_berry_bush()


func _draw_tree() -> void:
	draw_rect(
		Rect2(-5, -20, 10, 24),
		Color("#6B4423")
	)

	draw_circle(
		Vector2(0, -24),
		17,
		Color("#285943")
	)

	draw_circle(
		Vector2(-10, -18),
		12,
		Color("#347052")
	)

	draw_circle(
		Vector2(10, -18),
		12,
		Color("#347052")
	)


func _draw_rock() -> void:
	var rock_shape := PackedVector2Array([
		Vector2(-14, 4),
		Vector2(-11, -9),
		Vector2(-3, -15),
		Vector2(10, -11),
		Vector2(15, 2),
		Vector2(8, 8),
		Vector2(-8, 8)
	])

	draw_colored_polygon(
		rock_shape,
		Color("#70777D")
	)


func _draw_berry_bush() -> void:
	draw_circle(
		Vector2.ZERO,
		15,
		Color("#3E7045")
	)

	draw_circle(Vector2(-7, -5), 3, Color("#A83E5B"))
	draw_circle(Vector2(6, -7), 3, Color("#A83E5B"))
	draw_circle(Vector2(3, 5), 3, Color("#A83E5B"))
```

Save the scene as:

```
res://scenes/resources/resource_node.tscn
```

## 3. Test the three resource types

Return to `game.tscn`.

Add a new `Node2D` under `World`:

```
Game
├── World
│   └── ResourceObjects
├── Actors
│   └── Player
└── Interface
```

Instantiate `resource_node.tscn` three times under `ResourceObjects`.

Configure them as follows:

|Node name|Resource Type|Position|
|---|---|---|
|`TestTree`|Wood|`300, 300`|
|`TestRock`|Stone|`450, 300`|
|`TestBush`|Food|`600, 300`|

Run the game. You should see a tree, rock, and berry bush, and the player should be unable to walk directly through them.

The artwork is intentionally temporary, but we now have one reusable component instead of three nearly identical scripts. Next, we’ll remove these test objects and introduce a dedicated `ResourceSpawner` that places them procedurally using the world seed.