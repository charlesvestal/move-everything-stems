# CLAUDE.md — Stem Separation Module

External tool module for Move Everything. Separates audio into stems using SpleeterRT.

## Module Structure

```
src/
  module.json       # Module metadata (component_type: "tool")
  separate          # Shell script that invokes spleeter engine
  help.json         # On-device help content
  engine/
    spleeter        # SpleeterRT binary (pre-built ARM64)
    libgfortran.so.5
    libopenblas.so.0
```

## Build & Deploy

```bash
./scripts/build.sh        # Package to dist/stems/
./scripts/install.sh      # Deploy to Move device
```

No cross-compilation needed — ships pre-built binaries.

## Release

1. Update version in `src/module.json`
2. `git commit -am "bump to vX.Y.Z"`
3. `git tag vX.Y.Z && git push --tags`
4. GitHub Actions builds and creates release

## How It Works

The `separate` script:
1. Receives input WAV path and output directory from shadow_ui.js
2. Runs SpleeterRT in 3-stem mode
3. Renames outputs to `drums.wav`, `vocals.wav`, `accompaniment.wav`
4. Creates `.done` marker on success or `.error` on failure

The shadow UI's tool framework handles file browsing, progress display, and stem review.
