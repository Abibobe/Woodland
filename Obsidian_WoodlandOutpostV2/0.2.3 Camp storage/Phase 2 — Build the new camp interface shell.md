For now, keep the existing `Panel` completely unchanged. We’ll build the new interface beside it so the current camp menu continues working.

Under `CampMenu`, add:

```
CampMenu
├── Panel                         ← keep existing
├── Background (ColorRect)
└── CenterContainer
    └── CampWorkspace (PanelContainer)
        └── MarginContainer
            └── MainRow (HBoxContainer)
                ├── BackpackSide (VBoxContainer)
                ├── Divider (VSeparator)
                └── CampSide (VBoxContainer)
```

Move `Background` above `CenterContainer` but below the existing `Panel`.

### Background

Configure:

```
Layout: Full Rect
Color: #08100cd9
Mouse Filter: Stop
Visible: Off
```

### CenterContainer

Configure:

```
Layout: Full Rect
Mouse Filter: Ignore
Visible: Off
```

### CampWorkspace

Configure:

```
Custom Minimum Size: 940 × 430
Mouse Filter: Stop
```

### MarginContainer

Set all four margins to:

```
20
```

### MainRow

Set:

```
Separation: 22
```

### BackpackSide

Configure:

```
Custom Minimum Size X: 390
Size Flags Horizontal: Expand + Fill
Separation: 12
```

Add these children:

```
BackpackSide
├── BackpackHeader (HBoxContainer)
│   ├── BackpackTitle (Label)
│   ├── BackpackSpacer (Control)
│   └── CapacityLabel (Label)
├── BackpackGrid (Control)
├── BackpackSummary (Label)
└── DepositAllButton (Button)
```

Text:

```
BackpackTitle:     BACKPACK
CapacityLabel:     0 / 12 KG
BackpackSummary:   Food 0 • Wood 0 • Stone 0
DepositAllButton:  DEPOSIT ALL →
```

Set `BackpackSpacer` to **Expand + Fill** horizontally.

Attach:

```
res://scripts/ui/backpack_grid.gd
```

to this new `BackpackGrid`, then assign the same food, wood, and stone icons used by the normal backpack.

### Divider

Set:

```
Custom Minimum Size X: 2
```

### CampSide

Configure:

```
Custom Minimum Size X: 430
Size Flags Horizontal: Expand + Fill
Separation: 12
```

Add:

```
CampSide
├── CampHeader (HBoxContainer)
│   ├── CampTitle (Label)
│   ├── CampSpacer (Control)
│   └── StageLabel (Label)
├── StorageTitle (Label)
├── StorageRows (VBoxContainer)
│   ├── FoodRow (HBoxContainer)
│   │   ├── FoodLabel (Label)
│   │   ├── FoodSpacer (Control)
│   │   └── FoodAmount (Label)
│   ├── WoodRow (HBoxContainer)
│   │   ├── WoodLabel (Label)
│   │   ├── WoodSpacer (Control)
│   │   └── WoodAmount (Label)
│   └── StoneRow (HBoxContainer)
│       ├── StoneLabel (Label)
│       ├── StoneSpacer (Control)
│       └── StoneAmount (Label)
├── ConstructionSeparator (HSeparator)
├── NextBuildTitle (Label)
├── CostLabel (Label)
├── MessageLabel (Label)
└── Buttons (HBoxContainer)
    ├── BuildButton (Button)
    └── CloseButton (Button)
```

Suggested text:

```
CampTitle:       CAMP STORAGE
StageLabel:      SITE
StorageTitle:    STORED RESOURCES
FoodLabel:       Berries
WoodLabel:       Wood
StoneLabel:      Stone
FoodAmount:      ×0
WoodAmount:      ×0
StoneAmount:     ×0
NextBuildTitle:  NEXT BUILD — CAMPFIRE
CostLabel:       Wood 0 / 5
BuildButton:     BUILD CAMPFIRE
CloseButton:     CLOSE
```

Give each spacer in the storage rows **Expand + Fill** horizontally.

Set both new `Background` and `CenterContainer` to hidden. The old menu should continue appearing normally during this phase.

Once this hierarchy is saved without node warnings, the next step is connecting live backpack, storage, stage, and construction values to it.