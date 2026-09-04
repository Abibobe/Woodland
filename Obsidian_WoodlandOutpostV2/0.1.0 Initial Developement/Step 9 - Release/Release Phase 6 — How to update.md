## 1. Update the version

In Godot:

```
Project → Project Settings → Application → Config → Version
```

Change:

```
0.1.0 → 0.1.1
```

Keep the application name exactly the same so existing `user://` preferences continue using the same location.

Update `README.txt` too:

```
Version 0.1.1
```

## 2. Export a fresh release

Export again using:

```
Project → Export → Windows Release → Export Project
```

Ensure:

```
Export With Debug: Off
```

Create a clean folder:

```
WoodlandOutpost-v0.1.1-Windows-x86_64
├── WoodlandOutpost.exe
├── WoodlandOutpost.pck
└── README.txt
```

Compress it as:

```
WoodlandOutpost-v0.1.1-Windows-x86_64.zip
```

Extract and test that ZIP before uploading.

## 3. Upload it to the existing itch.io page

Open:

```
Dashboard → Woodland Outpost → Edit game
```

In **Uploads**:

1. Upload the new `v0.1.1` ZIP.
2. Mark it for **Windows**.
3. Save the page.
4. Download and test the new upload.
5. Only after confirming it works, delete the old `v0.1.0` ZIP.

Do not create another itch.io project page. Future versions should remain on the same page.

## 4. Publish a devlog

Create a short itch.io devlog titled:

```
Woodland Outpost v0.1.1 — UI Polish
```

Suggested text:

> A small Woodland Outpost update is now available!
> 
> This patch removes the obsolete Audio button from the in-game top bar. Audio and display options remain available through the Settings menu on the title screen and pause menu.
> 
> Thanks for playing!

Players downloading directly must download the updated ZIP again. If you eventually use itch.io’s `butler` tool, pushing repeatedly to the same Windows channel will update the existing build slot and provide smaller patch downloads through the itch app. [itch.io butler updates](https://itch.io/docs/butler/pushing?utm_source=chatgpt.com)