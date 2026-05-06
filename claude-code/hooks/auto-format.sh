#!/usr/bin/env bash
# Claude Code PostToolUse hook — auto-format files after write/edit
# Detects file type and runs appropriate formatter
set -e

TOOL_NAME="$1"
FILE_PATH="$2"

# Only run after Write or Edit tools
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Get the actual file path from stdin if needed
if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(cat)
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Formatter dispatch by extension
case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx)
        npx prettier --write "$FILE_PATH" 2>/dev/null &
        ;;
    *.go)
        gofmt -w "$FILE_PATH" 2>/dev/null &
        ;;
    *.py|*.pyi)
        ruff format "$FILE_PATH" 2>/dev/null &
        ;;
    *.kt|*.kts)
        ktlint -F "$FILE_PATH" 2>/dev/null &
        ;;
    *.rs)
        rustfmt "$FILE_PATH" 2>/dev/null &
        ;;
esac

exit 0
