![[README.txt]]Create this folder:

```
WoodlandOutpost-v0.1.0-Windows-x86_64
├── WoodlandOutpost.exe
├── WoodlandOutpost.pck
└── README.txt
```

Copy the new README beside the exported game files.

### Create the ZIP

Compress the folder and name the archive:

```
WoodlandOutpost-v0.1.0-Windows-x86_64.zip
```

Do not include:

- Godot project source files
- `.godot`
- `.git`
- Scripts or raw assets
- Previous builds
- `export_presets.cfg`

### Final clean-build test

Before uploading:

1. Move the ZIP somewhere outside the project.
2. Extract it into a new empty folder.
3. Launch `WoodlandOutpost.exe`.
4. Verify the icon appears.
5. Test Settings from the title menu and gameplay.
6. Complete at least one short run.
7. Confirm Return to Title and Quit work.
8. Ensure no debugger window or Godot editor is required.

If that extracted copy works, the ZIP is ready to upload to itch.io as a Windows download.