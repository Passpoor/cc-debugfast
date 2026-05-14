#!/usr/bin/env bash
set -euo pipefail

# cc-debugfast 卸载脚本
# 用法: bash uninstall.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo "=== cc-debugfast 卸载 ==="
echo ""

# 1. 从 settings.json 移除 hooks
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  echo "[1/2] 移除 hooks 配置..."
  TMP=$(mktemp)
  jq '
  if .hooks then
    .hooks.PostToolUse = (.hooks.PostToolUse // [] | map(select(.hooks[0].command // "" | contains("cc-debugfast") | not))) |
    .hooks.Stop = (.hooks.Stop // [] | map(select(.hooks[0].command // "" | contains("cc-debugfast") | not))) |
    # 如果 hooks 为空则移除整个 hooks 字段
    if (.hooks.PostToolUse | length == 0) and (.hooks.Stop | length == 0) then
      del(.hooks)
    else . end
  else . end
  ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  echo "  ✓ 已移除"
else
  echo "[1/2] 跳过 (无 settings.json 或 jq 不可用，请手动移除 hooks 配置)"
fi

# 2. 从 CLAUDE.md 移除规则
if [ -f "$CLAUDE_MD" ]; then
  echo "[2/2] 移除 CLAUDE.md 规则..."
  # 删除从标记行到文件末尾的内容
  sed -i '/^## cc-debugfast 错误检测规则/,$ d' "$CLAUDE_MD"
  # 清理末尾空行
  sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$CLAUDE_MD"
  echo "  ✓ 已移除"
else
  echo "[2/2] 跳过 (无 CLAUDE.md)"
fi

echo ""
echo "=== 卸载完成 ==="
echo ""
echo "cc-debugfast hooks 已从全局配置中移除。"
echo "项目目录 $SCRIPT_DIR 保留，如需彻底删除: rm -rf $SCRIPT_DIR"
