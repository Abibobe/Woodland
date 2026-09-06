## Phase 12.1 — Deterministic resource variants

## First integration
![[woodland_resources_v3_padded.zip]]
Copy these three files into:

```
res://assets/resources/
```

Each resource will select one of its three sprites based on its map cell. This adds variety without consuming additional random numbers or changing resource placement.

### 1. Add texture arrays to `resource_node.gd`

Under the existing texture exports, add:

```
@export_category("Visual Variants")
@export var tree_textures: Array[Texture2D] = []
@export var rock_textures: Array[Texture2D] = []
@export var bush_textures: Array[Texture2D] = []

@export_range(0, 2) var visual_variant := 0:
	set(value):
		visual_variant = value
		queue_redraw()
```

Keep the original exports:

```
@export var tree_texture: Texture2D
@export var rock_texture: Texture2D
@export var bush_texture: Texture2D
```

They will serve as fallbacks if an array is empty.

### 2. Add a texture-selection helper

Add above `_draw_tree()`:

```
func _get_variant_texture(
	textures: Array[Texture2D],
	fallback_texture: Texture2D
) -> Texture2D:
	if textures.is_empty():
		return fallback_texture

	var selected_index := posmod(
		visual_variant,
		textures.size()
	)

	return textures[selected_index]
```

### 3. Replace `_draw_tree()`

```
func _draw_tree() -> void:
	var selected_texture := _get_variant_texture(
		tree_textures,
		tree_texture
	)

	if selected_texture == null:
		_draw_tree_fallback()
		return

	var texture_size := selected_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		selected_texture,
		draw_position
	)
```

### 4. Replace `_draw_rock()`

```
func _draw_rock() -> void:
	var selected_texture := _get_variant_texture(
		rock_textures,
		rock_texture
	)

	if selected_texture == null:
		_draw_rock_fallback()
		return

	var texture_size := selected_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 8.0
	)

	draw_texture(
		selected_texture,
		draw_position
	)
```

### 5. Replace `_draw_berry_bush()`

```
func _draw_berry_bush() -> void:
	var selected_texture := _get_variant_texture(
		bush_textures,
		bush_texture
	)

	if selected_texture == null:
		_draw_berry_bush_fallback()
		return

	var texture_size := selected_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		selected_texture,
		draw_position
	)
```

## 6. Assign the arrays in `resource_node.tscn`

Select the root `ResourceNode`. Expand each array in the Inspector and set its size to `3`.

Assign:

```
Tree Textures
├── 0: tree_01_v3.png
├── 1: tree_02_v3.png
└── 2: tree_03_v3.png

Bush Textures
├── 0: berry_bush_01_v3.png
├── 1: berry_bush_02_v3.png
└── 2: berry_bush_03_v3.png

Rock Textures
├── 0: rock_01_v3.png
├── 1: rock_02_v3.png
└── 2: rock_03_v3.png
```

Leave the original individual texture fields assigned for fallback safety.

## 7. Select variants in `resource_spawner.gd`

Inside `_spawn_resource()`, immediately after:

```
resource.resource_type = resource_type
resource.resource_amount = units_per_resource
```

add:

```
resource.visual_variant = posmod(
	cell.x * 31
		+ cell.y * 17
		+ resource_type * 13,
	3
)
```

This calculation:

- Produces values from `0` to `2`.
- Uses no additional random calls.
- Preserves the existing resource-placement sequence.
- Returns the same variant for the same cell and world seed.

## Test

Generate a fixed world and verify:

- All three tree variants appear.
- Berry bushes still have obvious red berries.
- All three rocks appear.
- Collisions remain at their original positions.
- Gathering bars remain above each resource.
- Resource counts and locations are unchanged.
- Reusing the same world seed produces the same variants.

If the visual positions feel correct, we can then adjust the shadow sizes and interaction-highlight brackets to match the upgraded sprites more precisely.

#### FIX ::: 
Yes—the screenshot makes it clear. The original universal shadow is too wide, too dark, and identical for every resource. The new trees have narrow trunks, while rocks and bushes have different footprints.

## Replace the shadow colour

Change:

```
const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)
```

to:

```
const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.20)
```

This will blend better with the terrain, especially during evening and night.

## Replace `_draw_shadow()`

```
func _draw_shadow() -> void:
	var shadow_radius := 7.0
	var shadow_position := Vector2(0.0, 2.0)
	var shadow_scale := Vector2(1.0, 0.28)

	match resource_type:
		ResourceTypes.Type.WOOD:
			# Narrow shadow around the trunk.
			shadow_radius = 7.0
			shadow_position = Vector2(0.0, 1.0)
			shadow_scale = Vector2(1.0, 0.30)

		ResourceTypes.Type.FOOD:
			# Slightly wider because the bush touches more ground.
			shadow_radius = 10.0
			shadow_position = Vector2(0.0, 2.0)
			shadow_scale = Vector2(1.0, 0.28)

		ResourceTypes.Type.STONE:
			# Compact shadow beneath the boulder.
			shadow_radius = 9.0
			shadow_position = Vector2(1.0, 3.0)
			shadow_scale = Vector2(1.0, 0.32)

	draw_set_transform(
		shadow_position,
		0.0,
		shadow_scale
	)

	draw_circle(
		Vector2.ZERO,
		shadow_radius,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)
```

## Expected improvement

- Tree shadows will sit tightly around their trunks.
- Bush shadows will remain slightly wider.
- Rock shadows will align with the boulder footprint.
- Shadows will be less prominent during evening.
- All three visual variants can continue using the same type-specific shadow.

No scene or collision changes are required. The large floating dark ovals beneath the trees should now become subtle grounding shadows.


### FIX:::

Yes—both changes are appropriate. The screenshot shows that harvestable resources no longer have enough visual priority: the trees are only slightly larger than saplings, while berry bushes blend into flowers and shrubs.

## Better visual hierarchy

I recommend these approximate visible sizes:

|Resource|Current visible size|New target|
|---|---|---|
|Tree|~40×52 px|~58×78 px|
|Berry bush|~38×28 px|~48×38 px|
|Rock|~32×22 px|~42×30 px|

Trees can extend beyond one 32×32 tile visually. Their collision footprint can remain exactly the same—the large crown does not need a large collision shape.

## Incorporating the shadow

Baking the shadow into each sprite is a good solution here because:

- It will always align with the trunk or resource base.
- Each variant can have a shadow matching its own silhouette.
- We can remove the generic procedural shadow.
- It eliminates another runtime drawing operation.
- The result is easier to preview and adjust.

The baked shadow should be a subtle dark-green ellipse with approximately `18–22%` opacity, not a solid black shape.

## Changes after introducing the new sprites

In `resource_node.gd`, change `_draw()` from:

```
func _draw() -> void:
	_draw_shadow()

	match resource_type:
```

to:

```
func _draw() -> void:
	match resource_type:
```

The `_draw_shadow()` function and `SHADOW_COLOR` constant can then be deleted.

The collision remains:

```
24 × 24
Position: 0, -6
```

so balance and movement are unaffected.

## Progress-bar positions

Larger sprites will need slightly higher bars:

```
func _get_progress_bar_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -84.0

		ResourceTypes.Type.STONE:
			return -38.0

		ResourceTypes.Type.FOOD:
			return -46.0

	return -44.0
```

I would create the next pack as:

```
V4 Resource Pack
├── 3 large trees with baked shadows
├── 3 medium berry bushes with baked shadows
└── 3 medium rocks with baked shadows
```

All sprites can use transparent `96×96` canvases. That gives every object enough room and keeps their ground-contact point consistent. This should restore the intended hierarchy: resources become prominent, while decorative plants remain environmental texture.

### FIX:::
You were right—the generic ellipses were the problem. V5 uses compressed silhouettes derived from each resource’s own shape, positioned behind and overlapping its base.

Download V5 with connected shadows
![[woodland_resources_v5_connected_shadows.zip]]
Preview/download the V5 atlas

Improvements:

- Tree shadows reflect the canopy shape and connect to the trunk.
- Bush shadows follow their irregular leafy outlines.
- Rock shadows match their individual footprints.
- Shadows are subtle, pixelated, and dark green.
- All individual sprites remain transparent `96×96` PNGs.
- The resource artwork and larger scale are preserved.

![Immagine generata: Atlante pixel-art con ombre aderenti](https://chatgpt.com/backend-api/estuary/content?id=file_0000000011088210b596393de707f4a5&ts=496862&p=fs&cid=1&sig=49ceb626de2144b67eabd6ca85a3bdfbbd79710eda21bd536a497bf660fac5ad&v=0)

![](https://chatgpt.com/backend-api/estuary/content?id=file_0000000011088210b596393de707f4a5&ts=496862&p=fs&cid=1&sig=49ceb626de2144b67eabd6ca85a3bdfbbd79710eda21bd536a497bf660fac5ad&v=0)

![](https://chatgpt.com/backend-api/estuary/content?id=file_0000000011088210b596393de707f4a5&ts=496862&p=fs&cid=1&sig=49ceb626de2144b67eabd6ca85a3bdfbbd79710eda21bd536a497bf660fac5ad&v=0)