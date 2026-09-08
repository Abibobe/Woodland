A resource should appear as one object whose size communicates its weight:

```
Food:   [ berries ]

Wood:   [       log       ]

Stone:  [          large rock          ]
```

## Change the grid to `6 × 2`

A six-column grid is better for this because all current weights divide naturally into a row of six:

- Food spans `1` cell.
- Wood spans `2` horizontal cells.
- Stone spans `3` horizontal cells.

For example:

```
┌─────────────┬─────────────┬───────────────────────────┐
│    STONE ICON ×3 cells    │      LOG ICON ×2 cells   │ FOOD │
├─────────────────────────────────────────────────────────────┤
│ FOOD │                    EMPTY SPACE                       │
└─────────────────────────────────────────────────────────────┘
```

Two pieces of wood would appear as two separate horizontal logs, each covering two cells.

## Important Godot limitation

A `GridContainer` cannot make one child span multiple cells. Changing a control’s minimum width inside it will not reliably produce the intended result.

Instead, we should replace `SlotGrid` with a custom `BackpackGrid` control that:

1. Draws twelve empty square backgrounds.
2. Calculates where each resource item fits.
3. Draws one resource block across the required cells.
4. Draws a single icon over the complete block.
5. Keeps the summary underneath for exact quantities.

This gives us the visual you want without fighting Godot’s container layout.

## Recommended inventory icons

We should create three dedicated sprites:

- **Food:** a small cluster of berries, fitting one square.
- **Wood:** one horizontal log, designed to span two squares.
- **Stone:** one broad rock or group of rocks, spanning three squares.

These should not reuse the world-resource sprites. Inventory icons need:

- A flatter, more horizontal composition
- No ground shadow
- Transparent backgrounds
- Strong, simplified silhouettes
- Consistent pixel density
- Enough internal padding to avoid touching slot borders

The item background can retain its resource colour, but the icon should provide the primary identification:

- Dark red for Food
- Warm brown for Wood
- Cool grey for Stone

The result will feel much more physical:

```
BACKPACK                               9 / 12 KG

[      LARGE ROCK      ][    LOG    ][BERRIES]
[    LOG    ][BERRIES][      EMPTY SPACE      ]

Food 2  •  Wood 2  •  Stone 1
TAB — Close    F — Eat Food
```

This is the right direction. The next step should be creating the three inventory sprites, followed by replacing `GridContainer` with the custom drawn grid.

Downloads:
![[backpack_icons_pack.zip]]

![[backpack_view.gd]]
- Updated backpack_view.gd
- Complete icon pack
- Food icon
- Wood icon
- Stone icon

Before using the new script:

1. Change `SlotGrid` from `GridContainer` to a normal `Control`.
2. Replace your existing `backpack_view.gd` with the updated file.
3. Copy the PNGs into:

```
res://assets/ui/backpack/
```

4. Select `BackpackView` and assign:

```
Food Icon:  backpack_food.png
Wood Icon:  backpack_wood.png
Stone Icon: backpack_stone.png
```

The new renderer uses a `6 × 2` grid and row-aware packing:

- Berries cover one cell.
- A log spans two cells as one object.
- A rock formation spans three cells.
- Items are rearranged automatically so they never split between rows.

The icons were generated separately with the existing resource atlas as their style reference, then standardized to the exact cell dimensions using transparent canvases.

I couldn’t save these new versions to persistent storage due to an authentication issue, but the downloads above are complete and ready to use.