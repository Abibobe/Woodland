Before adding more sounds, let’s organize them into audio buses. This makes future volume controls easy and prevents ambience, UI, and gameplay effects from becoming tangled.

Open Godot’s **Audio** panel at the bottom of the editor.

Keep `Master`, then add three buses:

```
Master
├── SFX
├── UI
└── Ambience
```

Each new bus should send to:

```
Master
```

### Assign the gameplay sounds to `SFX`

Set the **Bus** property to `SFX` on:

```
ResourceNode/GatherSound
Camp/BuildSound
Player/FootstepSound
```

### Assign interface sounds to `UI`

Set these to the `UI` bus:

```
Interface/UISound
Interface/UIDeniedSound
Interface/VictorySound
Interface/DefeatSound
```

### Assign environmental loops

Set these to `Ambience`:

```
ForestAmbience
NightAmbience
```

### Initial bus levels

Use these conservative starting values:

```
Master:    0 dB
SFX:       0 dB
UI:       -2 dB
Ambience: -3 dB
```

Keep the individual node volumes we already configured. The bus levels act as group controls on top of them.

Godot saves the bus layout in:

```
res://default_bus_layout.tres
```

Once this is configured, we can add Master, Effects, and Ambience volume sliders without modifying any individual sound node.