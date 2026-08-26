The terrain base is now in good shape. We’ll move to resource artwork one object at a time, beginning with the tree. The sprite will be transparent, aligned around its trunk base, and deliberately taller than one ground cell so it has a stronger silhouette.

### 1. Import it
![[tree_01.png]]
Place it in:

```
res://assets/resources/tree_01.png
```

Use:

```
Compress Mode: Lossless
Mipmaps: Off
```

### 2. Add the tree texture property

In `resource_node.gd`, add:

```
@export_category("Visuals")
@export var tree_texture: Texture2D
```

In `_ready()`, add the filtering line:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
```

### 3. Update `_draw_tree()`

Replace `_draw_tree()` with:

```
func _draw_tree() -> void:
	if tree_texture == null:
		_draw_tree_fallback()
		return

	var texture_size := tree_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		tree_texture,
		draw_position
	)
```

Rename the previous drawing function to:

```
func _draw_tree_fallback() -> void:
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
```

Keeping the fallback means the resource still works if the texture is missing.

### 4. Assign the sprite

Open:

```
res://scenes/resources/resource_node.tscn
```

Select the root `ResourceNode` and assign:

```
Visuals → Tree Texture: tree_01.png
```

Save and run the game. All wood resources should now use the new tree sprite; rocks and berry bushes will continue using their temporary drawings.