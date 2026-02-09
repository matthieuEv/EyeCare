#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="EyeCare"
APP_BUNDLE_NAME="${APP_NAME}.app"
SOURCE_APP="$ROOT_DIR/dist/$APP_BUNDLE_NAME"
INSTALL_DIR="/Applications"
SKIP_BUILD=0
OPEN_AFTER_INSTALL=1

usage() {
    cat <<EOF
Usage: ./scripts/reinstall-app.sh [--user] [--skip-build] [--no-open]

  --user        Install to ~/Applications instead of /Applications
  --skip-build  Skip packaging (use existing dist/EyeCare.app)
  --no-open     Do not open the app after install
EOF
}

for arg in "$@"; do
    case "$arg" in
        --user)
            INSTALL_DIR="$HOME/Applications"
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        --no-open)
            OPEN_AFTER_INSTALL=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage
            exit 1
            ;;
    esac
done

TARGET_APP="$INSTALL_DIR/$APP_BUNDLE_NAME"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
    "$ROOT_DIR/scripts/package-app.sh"
fi

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "Source bundle not found: $SOURCE_APP" >&2
    exit 1
fi

echo "Stopping app if currently running..."
pkill -x "EyeCare" >/dev/null 2>&1 || true
pkill -x "EyeCareMenubar" >/dev/null 2>&1 || true

echo "Removing previous installations..."
for path in \
    "/Applications/EyeCare.app" \
    "$HOME/Applications/EyeCare.app" \
    "/Applications/EyeCareMenubar.app" \
    "$HOME/Applications/EyeCareMenubar.app"; do
    if [[ -d "$path" ]]; then
        if rm -rf "$path"; then
            echo "  - Removed: $path"
        else
            echo "  - Failed to remove: $path" >&2
        fi
    fi
done

mkdir -p "$INSTALL_DIR"

if [[ ! -w "$INSTALL_DIR" ]]; then
    echo "No write permission on $INSTALL_DIR" >&2
    echo "Use --user (~/Applications) or run with sudo." >&2
    exit 1
fi

echo "Installing new version to $TARGET_APP..."
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Installation complete."

if [[ "$OPEN_AFTER_INSTALL" -eq 1 ]]; then
    open "$TARGET_APP"
fi
