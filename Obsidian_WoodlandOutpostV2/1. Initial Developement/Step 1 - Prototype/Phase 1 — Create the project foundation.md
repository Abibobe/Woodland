
For now, we will create only the folders and main scene—no gameplay code yet.

### 1. Create the project

In Godot’s Project Manager:

1. Click **Create**.
2. Name it `WoodlandOutpostSevenDays`.
3. Choose an empty folder.
4. Select the **Compatibility** renderer if you want maximum compatibility.
5. Click **Create & Edit**.

### 2. Create the folders

In the FileSystem panel, right-click `res://`, select **Create New → Folder**, and create:

```
res://
├── assets/
├── scenes/
└── scripts/
```

Inside `scenes`, create:

```
scenes/
├── buildings/
├── game/
├── player/
├── resources/
├── ui/
└── world/
```

Inside `scripts`, create the same functional categories:

```
scripts/
├── buildings/
├── game/
├── player/
├── resources/
├── ui/
└── world/
```

This separation means:

- `scenes` contains nodes and their configurations.
- `scripts` contains behaviours and rules.
- `assets` contains sprites, sounds, fonts, and tiles.

### 3. Create the main scene

Create a new **2D Scene** and rename the root node:

```
Game
```

Add the following children:

```
Game (Node2D)
├── World (Node2D)
├── Actors (Node2D)
└── Interface (CanvasLayer)
```

Their responsibilities will be:

|Node|Contains|
|---|---|
|`Game`|Coordinates the overall game|
|`World`|Generated terrain, trees, rocks and bushes|
|`Actors`|Player and future moving characters|
|`Interface`|HUD, menus and messages|

Save the scene as:

```
res://scenes/game/game.tscn
```

### 4. Set it as the main scene

Press **F6** once and Godot should ask you to select a main scene. Choose:

```
game.tscn
```

Alternatively, use:

**Project → Project Settings → Application → Run → Main Scene**

### 5. Test the foundation

Press **F6** or the play button.

You should see an empty grey game window. That is correct: the project structure is working, but we haven’t created a world yet.

Do not attach any scripts yet. Our next phase will create `world_generator.gd`, whose only job will be generating a simple random grass-and-soil map.