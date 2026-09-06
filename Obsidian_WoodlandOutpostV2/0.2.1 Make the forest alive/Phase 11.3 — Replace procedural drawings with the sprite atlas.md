
Done! I created a transparent, Godot-ready pixel-art atlas matching the current woodland palette.
![[woodland_decorations_atlas.png]]
Download woodland_decorations_atlas.png

Specifications:

- Size: `128 × 96`
- Grid: `4 columns × 3 rows`
- Cell size: `32 × 32`
- Transparent background
- Includes saplings, plain shrubs, stump, fallen log, moss, leaf litter, fern, flowers, mushrooms and grass

In Godot’s Import settings, use:

```
Filter: Off
Mipmaps: Off
Repeat: Disabled
```

The next step is replacing `ForestDecorator`’s drawing functions with this single texture atlas. That should be dramatically faster while preserving the denser woodland.


This first integration removes all vegetation animation and replaces multiple circles/lines per object with one texture draw.

### 1. Add the atlas to the project

Place the downloaded file somewhere such as:

```
res://assets/environment/woodland_decorations_atlas.png
```

Confirm these import settings:

```
Filter: Off
Mipmaps: Off
Repeat: Disabled
```

### 2. Add the texture export

In `forest_decorator.gd`, under the existing exports, add:

```
@export_category("Decoration Sprites")
@export var decoration_atlas: Texture2D
```

Then select `ForestDecorator` in your scene and assign:

```
woodland_decorations_atlas.png
```

to `Decoration Atlas`.

### 3. Ensure the decorator is static

Replace `_ready()` with:

```
func _ready() -> void:
	z_index = -50
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
```

You can now delete or comment out the decorator’s `_process()` function. Also remove these variables if present:

```
var animation_time := 0.0
var redraw_elapsed := 0.0
```

The wind exports and `_get_wind_offset()` are no longer needed either.

### 4. Add the atlas coordinates

Add:

```
const ATLAS_CELL_SIZE := Vector2(32.0, 32.0)

const ATLAS_SAPLING_A := Vector2i(0, 0)
const ATLAS_SAPLING_B := Vector2i(1, 0)
const ATLAS_SHRUB_A := Vector2i(2, 0)
const ATLAS_SHRUB_B := Vector2i(3, 0)

const ATLAS_STUMP := Vector2i(0, 1)
const ATLAS_LOG := Vector2i(1, 1)
const ATLAS_MOSS := Vector2i(2, 1)
const ATLAS_LEAVES := Vector2i(3, 1)

const ATLAS_FERN := Vector2i(0, 2)
const ATLAS_FLOWERS := Vector2i(1, 2)
const ATLAS_MUSHROOMS := Vector2i(2, 2)
const ATLAS_GRASS := Vector2i(3, 2)
```

### 5. Replace `_draw()`

Replace the entire existing `_draw()` function with:

```
func _draw() -> void:
	if decoration_atlas == null:
		return

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		var draw_position := (
			decoration["position"] as Vector2
		)

		var variant := int(
			decoration["variant"]
		)

		var atlas_cell := _get_atlas_cell(
			decoration_type,
			variant
		)

		_draw_atlas_sprite(
			draw_position,
			atlas_cell
		)
```

### 6. Add the atlas lookup

```
func _get_atlas_cell(
	decoration_type: int,
	variant: int
) -> Vector2i:
	match decoration_type:
		DecorationType.GRASS:
			return ATLAS_GRASS

		DecorationType.FLOWER:
			return ATLAS_FLOWERS

		DecorationType.PEBBLE:
			return ATLAS_MOSS

		DecorationType.BRANCH:
			return ATLAS_LOG

		DecorationType.MUSHROOM:
			return ATLAS_MUSHROOMS

		DecorationType.FERN:
			return ATLAS_FERN

		DecorationType.SAPLING:
			if variant % 2 == 0:
				return ATLAS_SAPLING_A

			return ATLAS_SAPLING_B

		DecorationType.SHRUB:
			if variant % 2 == 0:
				return ATLAS_SHRUB_A

			return ATLAS_SHRUB_B

	return ATLAS_GRASS
```

For now, the old pebble type uses the moss sprite and the branch type uses the fallen log. We can give all four new objects their own generation probabilities afterward.

### 7. Add the sprite drawing function

```
func _draw_atlas_sprite(
	draw_position: Vector2,
	atlas_cell: Vector2i
) -> void:
	var source_position := Vector2(
		atlas_cell.x * ATLAS_CELL_SIZE.x,
		atlas_cell.y * ATLAS_CELL_SIZE.y
	)

	var source_rect := Rect2(
		source_position,
		ATLAS_CELL_SIZE
	)

	# The generated position represents the point where the
	# decoration meets the ground.
	var destination_rect := Rect2(
		draw_position - Vector2(16.0, 28.0),
		ATLAS_CELL_SIZE
	)

	draw_texture_rect_region(
		decoration_atlas,
		destination_rect,
		source_rect
	)
```

### 8. Remove the old drawing functions

Once the atlas works, these functions can be deleted:

```
_draw_grass()
_draw_flower()
_draw_pebble()
_draw_branch()
_draw_mushroom()
_draw_fern()
_draw_sapling()
_draw_shrub()
_get_wind_offset()
```

Nothing should call them after `_draw()` has been replaced.

## Conservative density settings

Start with:

```
Decoration Density:       0.30
Undergrowth Density:      0.10
Cluster Probability:      0.20
Maximum Cluster Size:     2
```

The new sprites occupy much more of each tile than the old lines and circles, so we should reassess density visually instead of immediately returning to the previous high values.

## Expected improvement

Each decoration now requires one atlas-texture operation instead of multiple circles and lines. More importantly, the entire forest is generated only once and no longer rebuilt for wind animation.

Butterflies, fireflies, drifting leaves and campfire embers can remain animated because their counts are small. If this version runs smoothly, we can next add proper probabilities for stumps, logs, moss and leaf litter.