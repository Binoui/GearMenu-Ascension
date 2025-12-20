#!/bin/bash
# Script to run luacheck on the GearMenu addon
# Usage: ./lint.sh [file or directory]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if luacheck is installed
if ! command -v luacheck &> /dev/null; then
    echo "Error: luacheck is not installed."
    echo ""
    echo "To install luacheck:"
    echo "  - On Arch Linux: sudo pacman -S lua51-luacheck"
    echo "  - On Ubuntu/Debian: sudo apt-get install lua5.1-luacheck"
    echo "  - Or via luarocks: luarocks install luacheck"
    echo ""
    exit 1
fi

# If a file or directory is provided as argument, lint only that
if [ $# -gt 0 ]; then
    TARGET="$1"
else
    TARGET="."
fi

# Run luacheck
echo "Running luacheck on: $TARGET"
echo ""

luacheck "$TARGET" \
    --config .luacheckrc \
    --codes \
    --formatter plain

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✓ No linting errors found!"
else
    echo ""
    echo "✗ Linting found issues. Please review the output above."
fi

exit $EXIT_CODE

