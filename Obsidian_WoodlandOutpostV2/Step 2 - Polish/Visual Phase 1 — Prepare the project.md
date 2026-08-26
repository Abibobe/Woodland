### 1. Create asset folders

Inside `res://assets/`, create:

```
assets/
├── ground/
├── resources/
├── buildings/
├── player/
└── ui/
```

Their responsibilities are:

|Folder|Contents|
|---|---|
|`ground`|Grass, soil, and terrain tiles|
|`resources`|Trees, rocks, and berry bushes|
|`buildings`|Campfire, foundation, and cabin|
|`player`|Idle and walking animations|
|`ui`|Resource icons and interface graphics|

### 2. Configure pixel-art filtering

Open:

**Project → Project Settings**

Use the search field and search for:

```
default texture filter
```

Find:

```
Rendering → Textures → Default Filters → Use Nearest Mipmap Filter
```

If Godot instead shows **Default Texture Filter**, set it to:

```
Nearest
```

If you cannot find that setting, don’t worry—we can configure each imported asset individually.

### 3. Establish our asset rules

Every production asset we create will follow these rules:

```
Ground tile:     32 × 32 PNG, opaque
Resource sprite: transparent PNG
Player frame:    32 × 32 PNG, transparent
Filtering:       Nearest
Mipmaps:         Disabled
```

For animated characters, every frame will be exactly the same size and aligned to the same central point. We will avoid a large generated sprite sheet until individual frames have been verified.

### 4. Keep the current visuals

Do not remove:

- `_draw()` from `world_generator.gd`
- The temporary resource drawings
- The temporary player rectangle
- The temporary camp drawings

We will replace them one system at a time. This keeps the game playable throughout the visual phase.

That’s all for this step. Once these folders are ready, we’ll create **one real 32×32 grass tile**, import it, verify its sharpness, and only then modify `WorldGenerator` to display it.

