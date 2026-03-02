#!/usr/bin/env bash
# install.sh — Deploy stems module to Move device
#
# Usage:
#   ./scripts/install.sh              # Deploy to Move via SSH
#   ./scripts/install.sh <host>       # Deploy to specific host

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE_ID="stems"
DIST_DIR="$PROJECT_DIR/dist/$MODULE_ID"
MOVE_HOST="${1:-move.local}"
MOVE_USER="root"
REMOTE_DIR="/data/UserData/move-anything/modules/tools/$MODULE_ID"

if [ ! -d "$DIST_DIR" ]; then
    echo "Error: Build output not found at $DIST_DIR"
    echo "Run ./scripts/build.sh first"
    exit 1
fi

echo "==> Deploying stems module to $MOVE_HOST..."

# Create remote directory
ssh "$MOVE_USER@$MOVE_HOST" "mkdir -p $REMOTE_DIR/engine"

# Copy files
echo "  Copying module files..."
scp "$DIST_DIR/module.json"  "$MOVE_USER@$MOVE_HOST:$REMOTE_DIR/"
scp "$DIST_DIR/separate"     "$MOVE_USER@$MOVE_HOST:$REMOTE_DIR/"

echo "  Copying SpleeterRT engine..."
scp "$DIST_DIR/engine/spleeter"          "$MOVE_USER@$MOVE_HOST:$REMOTE_DIR/engine/"

echo "  Copying libraries..."
scp "$DIST_DIR/engine/libopenblas.so.0"  "$MOVE_USER@$MOVE_HOST:$REMOTE_DIR/engine/"
scp "$DIST_DIR/engine/libgfortran.so.5"  "$MOVE_USER@$MOVE_HOST:$REMOTE_DIR/engine/"

# Ensure executables are marked
ssh "$MOVE_USER@$MOVE_HOST" "chmod +x $REMOTE_DIR/separate $REMOTE_DIR/engine/spleeter"

echo ""
echo "Deploy complete!"
echo "  Installed to: $REMOTE_DIR"
echo ""
echo "The stem separation tool will appear in the Tools menu (Shift+Vol+Step13)"
