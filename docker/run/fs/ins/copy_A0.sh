#!/bin/bash
set -e

# Paths
SOURCE_DIR="/git/agent-zero"
TARGET_DIR="/a0"

# Copy repository files if run_ui.py is missing in /a0 (if the volume is mounted)
if [ ! -f "$TARGET_DIR/run_ui.py" ]; then
    echo "Copying files from $SOURCE_DIR to $TARGET_DIR..."
    cp -rn --no-preserve=ownership,mode "$SOURCE_DIR/." "$TARGET_DIR"
fi

# Generate VERSION metadata for Docker images (no .git available at runtime)
if [ ! -f "$TARGET_DIR/VERSION" ]; then
    echo "Generating VERSION file from git metadata..."
    cd "$SOURCE_DIR"
    _BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")
    _HASH=$(git rev-parse --short=12 HEAD 2>/dev/null || echo "unknown")
    _TIME=$(git log -1 --format=%cs 2>/dev/null || echo "unknown")
    _TAG=$(git describe --tags --always 2>/dev/null || echo "unknown")
    _SHORT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "$_TAG")
    _SINCE=$(git rev-list "${_SHORT_TAG}..HEAD" --count 2>/dev/null || echo "0")
    _VERSION="${_BRANCH:0:1} ${_SHORT_TAG}"
    if [ "$_SINCE" -gt 0 ] 2>/dev/null; then
        _VERSION="${_VERSION}+${_SINCE}"
    fi
    cat > "$TARGET_DIR/VERSION" << VERSIONJSON
{
  "branch": "$_BRANCH",
  "commit_hash": "$_HASH",
  "commit_time": "$_TIME",
  "tag": "$_TAG",
  "short_tag": "$_SHORT_TAG",
  "version": "$_VERSION"
}
VERSIONJSON
    echo "VERSION file generated:"
    cat "$TARGET_DIR/VERSION"
fi