#!/usr/bin/env bash
# build.sh — Build stems module package for Move
#
# Expects the SpleeterRT engine to already be built. Either:
#   1. Pre-built output in engine/spleeter-move/ (from Docker build)
#   2. Or run the Docker build inline (requires QEMU)
#
# Usage:
#   ./scripts/build.sh                    # Package from pre-built engine
#   ./scripts/build.sh --docker           # Build engine via Docker first

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE_ID="stems"
ENGINE_DIR="$PROJECT_DIR/engine/spleeter-move"
DIST_DIR="$PROJECT_DIR/dist/$MODULE_ID"

# Check for --docker flag
if [ "${1:-}" = "--docker" ]; then
    echo "==> Building SpleeterRT engine via Docker..."
    SPLEETERRT_DIR="$PROJECT_DIR/engine/SpleeterRT"
    if [ ! -f "$SPLEETERRT_DIR/Dockerfile.move" ]; then
        echo "Error: No Dockerfile.move found in engine/SpleeterRT/"
        echo "Clone SpleeterRT repo and add Dockerfile.move"
        exit 1
    fi
    cd "$SPLEETERRT_DIR"
    # Register QEMU if needed
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 2>/dev/null || true
    docker build --platform linux/arm64 -f Dockerfile.move -t spleeter-move-builder .
    docker rm -f spleeter-extract 2>/dev/null || true
    docker create --name spleeter-extract spleeter-move-builder
    mkdir -p "$ENGINE_DIR"
    docker cp spleeter-extract:/output/spleeter-move/. "$ENGINE_DIR/"
    docker rm spleeter-extract
    cd "$PROJECT_DIR"
fi

# Verify engine exists
if [ ! -d "$ENGINE_DIR" ]; then
    echo "Error: Engine not found at $ENGINE_DIR"
    echo ""
    echo "Either:"
    echo "  1. Copy pre-built SpleeterRT output: cp -r /path/to/spleeter-move engine/"
    echo "  2. Run with --docker flag: ./scripts/build.sh --docker"
    exit 1
fi

echo "==> Packaging stems module..."

# Clean and create dist directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/engine"

# Copy module metadata
cp "$PROJECT_DIR/src/module.json" "$DIST_DIR/"

# Copy engine binary and libraries
cp "$ENGINE_DIR/spleeter"          "$DIST_DIR/engine/"
cp "$ENGINE_DIR/libopenblas.so.0"  "$DIST_DIR/engine/"
cp "$ENGINE_DIR/libgfortran.so.5"  "$DIST_DIR/engine/"

# Create the 'separate' wrapper script (engine-agnostic interface)
cat > "$DIST_DIR/separate" << 'WRAPPER_EOF'
#!/bin/sh
# Generic stem separation interface (SpleeterRT backend)
# Usage: separate <input.wav> <output-dir> [threads]
# Creates .done on success, .error on failure

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$1"
OUTPUT_DIR="$2"
THREADS="${3:-2}"

if [ -z "$INPUT" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: separate <input.wav> <output-dir> [threads]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Lower priority so Move UI stays responsive
renice 15 $$ >/dev/null 2>&1

export LD_LIBRARY_PATH="$SCRIPT_DIR/engine:$LD_LIBRARY_PATH"

# SpleeterRT uses full input filename (with ext) as output prefix
# e.g. input.wav -> input.wav_Drum.wav, input.wav_Vocal.wav, input.wav_Accompaniment.wav
FULLNAME=$(basename "$INPUT")

# SpleeterRT writes output files to CWD, so cd to output dir
cd "$OUTPUT_DIR"

# Run SpleeterRT in 3-stem mode (drums, vocals, accompaniment)
# Args: <threads> <timeStep> <binLimit> <stems> <audioFile>
# timeStep=256 + binLimit=2048 = full spectrum, finer time resolution
# ~0.5x realtime on Cortex-A72 (still fast, much better quality than 512/1024)
"$SCRIPT_DIR/engine/spleeter" "$THREADS" 256 2048 3 "$INPUT" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Rename outputs to consistent names
    [ -f "${FULLNAME}_Drum.wav" ]          && mv "${FULLNAME}_Drum.wav" "drums.wav"
    [ -f "${FULLNAME}_Vocal.wav" ]         && mv "${FULLNAME}_Vocal.wav" "vocals.wav"
    [ -f "${FULLNAME}_Accompaniment.wav" ] && mv "${FULLNAME}_Accompaniment.wav" "accompaniment.wav"
    touch "$OUTPUT_DIR/.done"
else
    echo "Exit code: $EXIT_CODE" > "$OUTPUT_DIR/.error"
fi

exit $EXIT_CODE
WRAPPER_EOF
chmod +x "$DIST_DIR/separate"

# Make engine binary executable
chmod +x "$DIST_DIR/engine/spleeter"

# Create tarball for release
echo "==> Creating tarball..."
cd "$PROJECT_DIR/dist"
tar -czvf "${MODULE_ID}-module.tar.gz" "$MODULE_ID/"
cd "$PROJECT_DIR"

echo ""
echo "Build complete!"
echo "  Package: dist/$MODULE_ID/"
echo "  Tarball: dist/${MODULE_ID}-module.tar.gz"
echo "  Size:    $(du -sh "dist/${MODULE_ID}-module.tar.gz" | cut -f1)"
