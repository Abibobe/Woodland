We’ll first create a clean playable Windows build. We can add the application icon immediately afterward.

### 1. Set the project metadata

Open:

```
Project → Project Settings → Application → Config
```

Set:

```
Name:        Woodland Outpost
Description: Survive. Gather. Build.
Version:     0.1.0
```

Verify that **Run → Main Scene** points to:

```
res://scenes/game/game.tscn
```

Use your actual scene path if `game.tscn` is stored elsewhere.

### 2. Install the export templates

Open:

```
Editor → Manage Export Templates
```

Install the templates matching your exact Godot version. Godot cannot produce a playable export without them. [Godot export templates](https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html?utm_source=chatgpt.com)

You only need:

```
Windows x86_64
```

for the first build.

### 3. Create a Windows preset

Open:

```
Project → Export
```

Click:

```
Add… → Windows Desktop
```

Rename the preset:

```
Windows Release
```

Configure:

```
Architecture: x86_64
Embed PCK: Off
```

`x86_64` is the standard choice for modern Intel and AMD Windows computers. [Godot Windows export](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_windows.html?utm_source=chatgpt.com)

Keep code signing disabled for this first test build.

### 4. Choose exported resources

In the preset’s **Resources** section, select:

```
Export Mode: Export all resources in the project
```

This is the safest option for now because it prevents a required scene, sound, texture, or configuration resource from being accidentally excluded.

### 5. Create a build folder

Outside `res://`, create:

```
WoodlandOutpostBuild
└── Windows
```

Do not create the export folder inside the Godot project. Otherwise, exported files can accidentally appear in the FileSystem panel and be included in later exports.

### 6. Export the game

In the Export window:

1. Select `Windows Release`.
2. Click **Export Project**.
3. Disable:

```
Export With Debug
```

4. Export as:

```
WoodlandOutpost.exe
```

The result should normally contain:

```
Windows
├── WoodlandOutpost.exe
└── WoodlandOutpost.pck
```

Keep both files together. **Export PCK/ZIP** alone does not create a playable application; use **Export Project**. [Godot export workflow](https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html?utm_source=chatgpt.com)

### 7. Test the exported version

Close the editor or leave the game stopped, then launch:

```
WoodlandOutpost.exe
```

Test:

- Start Game
- Settings from the initial menu
- Settings from Pause
- Fullscreen and `Alt + Enter`
- VSync and Reset Defaults
- Tutorial
- Gathering and building
- Victory/defeat screen
- Return to title
- Quit

Also restart the executable once to confirm that audio, fullscreen, VSync, and tutorial preferences persist correctly in `user://`.

Once this standalone build passes, the next release step is creating and assigning the real Woodland Outpost application icon.