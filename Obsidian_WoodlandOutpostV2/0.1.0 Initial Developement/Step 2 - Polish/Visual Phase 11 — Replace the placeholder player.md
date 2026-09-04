Next we’ll tackle the player carefully. We’ll start with one exact 32×32 idle frame and configure `AnimatedSprite2D` immediately—even though it has only one frame—so later walking animations can be added without changing the scene structure again.

### 1. Import it
![[player_idle_down_01.png]]
Place it in:

```
res://assets/player/player_idle_down_01.png
```

Verify:

```
Size: 32 × 32
Compress Mode: Lossless
Mipmaps: Off
```

### 2. Replace the rectangle

Open:

```
res://scenes/player/player.tscn
```

Delete the existing `PlayerVisual` `Polygon2D`.

Add an `AnimatedSprite2D` beneath `Player` and name it:

```
PlayerVisual
```

Keep the existing `CollisionShape2D` and `PlayerInteraction` unchanged.

### 3. Create the animation resource

Select `PlayerVisual`.

For **Sprite Frames**:

1. Choose **New SpriteFrames**.
2. Click the new resource to open the SpriteFrames panel.
3. Rename the default animation to:

```
idle_down
```

4. Drag player_idle_down_01.png into the animation frame area.
5. Set `PlayerVisual → Animation` to `idle_down`.

Since there is only one frame, autoplay and animation speed don’t matter yet.

### 4. Align it

Keep **Centered** enabled and set:

```
Position X: 0
Position Y: -2
```

The sprite’s feet should now align with the bottom of the existing collision shape.

Run the game. The player should move exactly as before, but the yellow rectangle should be replaced by the new settler sprite.

We now have the correct animation structure. Next, we can create walking frames individually at the same 32×32 size and verify their alignment before combining them into animations.