#!/usr/bin/env bash
set -u

# cc-debugfast: Stop 全局验证
# Claude 准备停止时自动跑验证，失败则 exit 2 阻止停止
# 错误会反馈给 Claude 让它继续修复

INPUT="$(cat)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/ERROR_LOG.md"

cd "$PROJECT_DIR" || exit 0

# 防止 Stop hook 无限循环
if echo "$INPUT" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

ERROR_FOUND=0
TMP_LOG="$(mktemp)"

echo "" >> "$LOG_FILE"
echo "## $(date '+%Y-%m-%d %H:%M:%S') Stop check" >> "$LOG_FILE"

# Node.js 项目检测
if [ -f "package.json" ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "### npm test" >> "$LOG_FILE"
    npm test > "$TMP_LOG" 2>&1 || ERROR_FOUND=1
    cat "$TMP_LOG" >> "$LOG_FILE"
  fi
fi

# Python 编译检测
if find . -maxdepth 3 -name "*.py" \
  -not -path "./.pixi/*" \
  -not -path "./node_modules/*" \
  -not -path "./__pycache__/*" \
  -not -path "./venv/*" \
  -not -path "./.venv/*" | grep -q .; then
  echo "### Python compile check" >> "$LOG_FILE"
  python3 -m compileall . > "$TMP_LOG" 2>&1 || ERROR_FOUND=1
  cat "$TMP_LOG" >> "$LOG_FILE"
fi

# Shell 脚本语法检测
if find . -maxdepth 3 -name "*.sh" \
  -not -path "./.pixi/*" | grep -q .; then
  echo "### Shell script check" >> "$LOG_FILE"
  find . -maxdepth 3 -name "*.sh" -not -path "./.pixi/*" -exec bash -n {} \; > "$TMP_LOG" 2>&1 || ERROR_FOUND=1
  cat "$TMP_LOG" >> "$LOG_FILE"
fi

# R 脚本语法检测
if command -v Rscript >/dev/null 2>&1; then
  if find . -maxdepth 3 \( -name "*.R" -o -name "*.r" \) | grep -q .; then
    echo "### R script check" >> "$LOG_FILE"
    find . -maxdepth 3 \( -name "*.R" -o -name "*.r" \) -exec Rscript -e "tryCatch(parse(file=commandArgs(trailingOnly=TRUE)[1]), error=function(e) { cat(e\$message, '\n'); quit(status=1) })" {} \; > "$TMP_LOG" 2>&1 || ERROR_FOUND=1
    cat "$TMP_LOG" >> "$LOG_FILE"
  fi
fi

if [ "$ERROR_FOUND" -eq 1 ]; then
  echo "" >> "$LOG_FILE"
  echo "**Status:** open" >> "$LOG_FILE"

  echo "Blocking stop: tests or compile checks failed. Read ERROR_LOG.md, fix the errors, then rerun validation." >&2
  cat "$TMP_LOG" >&2
  rm -f "$TMP_LOG"
  exit 2
fi

echo "No blocking error detected." >> "$LOG_FILE"
rm -f "$TMP_LOG"
exit 0
