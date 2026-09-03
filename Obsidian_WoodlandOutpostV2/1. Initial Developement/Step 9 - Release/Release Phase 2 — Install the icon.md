### 1. Import both files
![[woodland_outpost_icon.png]]

![[woodland_outpost_icon.ico]]
Place them in:

```
res://assets/ui/application/
├── woodland_outpost_icon.png
└── woodland_outpost_icon.ico
```

### 2. Set the general project icon

Open:

```
Project → Project Settings → Application → Config
```

Set:

```
Icon: woodland_outpost_icon.png
```

This controls the general project and window icon.

### 3. Set the Windows native icon

Enable **Advanced Settings**, then find:

```
Application → Config → Windows Native Icon
```

Assign:

```
woodland_outpost_icon.ico
```

### 4. Set the exported executable icon

Open:

```
Project → Export → Windows Release
```

Under:

```
Application → Icon
```

assign:

```
woodland_outpost_icon.ico
```

Godot can automatically convert the configured project PNG, but the prepared ICO gives explicit control over all standard Windows icon sizes. [Godot Windows icon documentation](https://docs.godotengine.org/en/latest/tutorials/export/changing_application_icon_for_windows.html?utm_source=chatgpt.com)

Export `WoodlandOutpost.exe` again. Windows sometimes caches executable icons; if the old Godot icon remains, export with a slightly different filename or clear the Windows icon cache.