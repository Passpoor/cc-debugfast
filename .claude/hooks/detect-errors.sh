#!/usr/bin/env bash
set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/ERROR_LOG.md"

cd "$PROJECT_DIR" || exit 0

echo "" >> "$LOG_FILE"
echo "## $(date '+%Y-%m-%d %H:%M:%S') PostToolUse check" >> "$LOG_FILE"

ERROR_FOUND=0

# Node.js 项目检测
if [ -f "package.json" ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "### npm test check" >> "$LOG_FILE"
    npm test >> "$LOG_FILE" 2>&1 || ERROR_FOUND=1
  fi
fi

# Python 编译检测
if find . -maxdepth 3 -name "*.py" -not -path "./.pixi/*" -not -path "./node_modules/*" | grep -q .; then
  echo "### Python compile check" >> "$LOG_FILE"
  python3 -m compileall . >> "$LOG_FILE" 2>&1 || ERROR_FOUND=1
fi

# Shell 脚本语法检测
if find . -maxdepth 3 -name "*.sh" -not -path "./.pixi/*" | grep -q .; then
  echo "### Shell script check" >> "$LOG_FILE"
  find . -maxdepth 3 -name "*.sh" -not -path "./.pixi/*" -exec bash -n {} \; >> "$LOG_FILE" 2>&1 || ERROR_FOUND=1
fi

if [ "$ERROR_FOUND" -eq 1 ]; then
  echo "" >> "$LOG_FILE"
  echo "**Status:** open" >> "$LOG_FILE"
else
  echo "No blocking error detected." >> "$LOG_FILE"
fi

exit 0
