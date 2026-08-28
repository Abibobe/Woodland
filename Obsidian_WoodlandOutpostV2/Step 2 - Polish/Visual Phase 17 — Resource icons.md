### 1. Import the strip
![[hud_resource_icons.png]]
Place it here:

```
res://assets/ui/hud_resource_icons.png
```

Use lossless compression and disable mipmaps.

### 2. Add three `TextureRect` nodes

Inside your HUD’s `ResourceRow`, arrange the children like this:

```
ResourceRow
├── WoodIcon
├── WoodLabel
├── FoodIcon
├── FoodLabel
├── StoneIcon
└── StoneLabel
```

Set each icon to:

```
Custom Minimum Size: 16 × 16
Expand Mode: Ignore Size
Stretch Mode: Keep Aspect Centered
Mouse Filter: Ignore
```

### 3. Create the wood atlas texture

Select `WoodIcon`. Beside **Texture**, choose:

```
New AtlasTexture
```

Open that resource and configure:

```
Atlas:  hud_resource_icons.png
Region: x 0, y 0, width 16, height 16
```

### 4. Configure food and stone

Repeat with separate `AtlasTexture` resources:

```
FoodIcon
Region: x 16, y 0, width 16, height 16
```

```
StoneIcon
Region: x 32, y 0, width 16, height 16
```

### 5. Preserve sharp pixels

In `game_hud.gd`, add this line to your existing `_ready()` function:

```
texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

Run the game. Each resource number should now have a compact, recognizable pixel-art icon beside it without changing any inventory logic.