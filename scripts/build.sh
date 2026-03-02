#!/usr/bin/env bash
# Build Stem Separation module for Move Anything
#
# This module ships pre-built binaries — no cross-compilation needed.
# The build script packages src/ files into dist/ for release.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODULE_ID="stems"

cd "$REPO_ROOT"

echo "=== Building Stem Separation Module ==="

# Create dist directory
rm -rf "dist/$MODULE_ID"
mkdir -p "dist/$MODULE_ID/engine"

# Copy module files
echo "Packaging..."
cp src/module.json "dist/$MODULE_ID/"
[ -f src/help.json ] && cp src/help.json "dist/$MODULE_ID/"
cp src/separate "dist/$MODULE_ID/"
chmod +x "dist/$MODULE_ID/separate"

# Copy engine binaries
cp src/engine/spleeter "dist/$MODULE_ID/engine/"
cp src/engine/libgfortran.so.5 "dist/$MODULE_ID/engine/"
cp src/engine/libopenblas.so.0 "dist/$MODULE_ID/engine/"
chmod +x "dist/$MODULE_ID/engine/spleeter"

# Create tarball for release
cd dist
tar -czvf "$MODULE_ID-module.tar.gz" "$MODULE_ID/"
cd ..

echo ""
echo "=== Build Complete ==="
echo "Output: dist/$MODULE_ID/"
echo "Tarball: dist/$MODULE_ID-module.tar.gz"
echo ""
echo "To install on Move:"
echo "  ./scripts/install.sh"
