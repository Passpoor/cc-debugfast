#!/usr/bin/env bash
set -euo pipefail

# cc-debugfast 一键安装脚本
# 用法: bash install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo "=== cc-debugfast 安装 ==="
echo ""

# 1. 确保 ~/.claude 目录存在
mkdir -p "$CLAUDE_DIR"

# 2. 合并 hooks 到 ~/.claude/settings.json
echo "[1/3] 配置全局 hooks..."

if [ ! -f "$SETTINGS" ]; then
  # 无现有配置，直接创建
  cat > "$SETTINGS" <<JSONEOF
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_DIR/detect-errors.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_DIR/stop-check.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
JSONEOF
  echo "  ✓ 创建 $SETTINGS"
else
  # 已有配置，用 jq 合并 hooks
  if command -v jq >/dev/null 2>&1; then
    # 读取现有配置，追加 hooks
    TMP=$(mktemp)
    jq --arg detect "$HOOKS_DIR/detect-errors.sh" \
       --arg stop "$HOOKS_DIR/stop-check.sh" \
       '
       .hooks = (.hooks // {}) |
       .hooks.PostToolUse = (.hooks.PostToolUse // []) |
       .hooks.Stop = (.hooks.Stop // []) |
       # 移除旧的 cc-debugfast 条目（避免重复）
       .hooks.PostToolUse = [.hooks.PostToolUse[] | select(.hooks[0].command // "" | contains("cc-debugfast") | not)] |
       .hooks.Stop = [.hooks.Stop[] | select(.hooks[0].command // "" | contains("cc-debugfast") | not)] |
       # 追加新的 cc-debugfast 条目
       .hooks.PostToolUse += [{"matcher": "Edit|Write", "hooks": [{"type": "command", "command": $detect, "timeout": 60}]}] |
       .hooks.Stop += [{"matcher": "", "hooks": [{"type": "command", "command": $stop, "timeout": 120}]}]
       ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    echo "  ✓ 合并 hooks 到 $SETTINGS"
  else
    echo "  ⚠ 需要 jq 来合并配置，请手动添加以下内容到 $SETTINGS:"
    echo ""
    echo '  "hooks": {'
    echo '    "PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "'"$HOOKS_DIR"'/detect-errors.sh", "timeout": 60}]}],'
    echo '    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "'"$HOOKS_DIR"'/stop-check.sh", "timeout": 120}]}]'
    echo '  }'
    echo ""
  fi
fi

# 3. 追加错误处理规则到 ~/.claude/CLAUDE.md
echo "[2/3] 配置全局 CLAUDE.md 规则..."

RULE_MARKER="## cc-debugfast 错误检测规则"

if [ -f "$CLAUDE_MD" ] && grep -qF "$RULE_MARKER" "$CLAUDE_MD"; then
  echo "  ✓ 规则已存在，跳过"
else
  cat >> "$CLAUDE_MD" <<'RULEEOF'

## cc-debugfast 错误检测规则（全局生效）

cc-debugfast hooks 已全局配置在 `~/.claude/settings.json`，所有项目自动受监控。

### 自动机制
- **PostToolUse**: 每次编辑/写入文件后自动检测 Python/Shell/R/Node 语法错误，记录到项目目录下的 `ERROR_LOG.md`
- **Stop**: Claude 准备停止时自动验证，失败则阻止停止（exit 2），将错误反馈给 Claude 继续修复
- 手动修复命令：`/fix-errors`

### 编码完成前必须遵守
1. 检查当前项目的 `ERROR_LOG.md` 是否有 open 状态的错误
2. 如有，先修复错误再停止
3. 修复后在 `ERROR_LOG.md` 中记录 root cause、修改的文件、验证结果，标记 Status: fixed
RULEEOF
  echo "  ✓ 追加规则到 $CLAUDE_MD"
fi

# 4. 验证 hooks 脚本
echo "[3/3] 验证 hooks 脚本..."
if [ -x "$HOOKS_DIR/detect-errors.sh" ] && [ -x "$HOOKS_DIR/stop-check.sh" ]; then
  echo "  ✓ hooks 脚本权限正确"
else
  chmod +x "$HOOKS_DIR/detect-errors.sh" "$HOOKS_DIR/stop-check.sh"
  echo "  ✓ 已赋予执行权限"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "所有 Claude Code 项目现在自动受监控："
echo "  - 编辑文件后自动检测语法错误 → 写入 ERROR_LOG.md"
echo "  - Claude 停止前自动验证 → 有错则阻止停止并反馈修复"
echo "  - 项目中运行 /fix-errors 可手动触发修复"
echo ""
echo "卸载: bash $SCRIPT_DIR/uninstall.sh"
