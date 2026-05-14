# cc-debugfast

Claude Code 实时错误检测与自修复系统。

## 核心机制

- **PostToolUse hook**: 每次编辑/写入文件后自动检测语法错误和测试失败，记录到 ERROR_LOG.md
- **Stop hook**: Claude 准备停止时自动验证，如果测试或编译失败则阻止停止（exit 2），将错误反馈给 Claude 继续修复
- **ERROR_LOG.md**: 长期错误记录与修复轨迹
- **/fix-errors 命令**: 手动触发修复流程

## 错误处理规则

Before finishing any coding task, always inspect ERROR_LOG.md.

If ERROR_LOG.md contains an open error:
1. Read the latest error block.
2. Identify the root cause.
3. Modify the code.
4. Re-run the failing command.
5. Append the fix summary to ERROR_LOG.md.
6. Do not stop until the latest validation passes.

## 架构

```
Claude Code
   ↓
Bash / Edit / Write / Stop hooks
   ↓
捕获错误、测试失败、lint 失败、traceback
   ↓
写入 ERROR_LOG.md
   ↓
触发 Claude Code 自己继续修复
```

## 项目结构

```
cc-debugfast/
├── .claude/
│   ├── settings.json          # hooks 配置
│   ├── hooks/
│   │   ├── detect-errors.sh   # PostToolUse 错误检测
│   │   └── stop-check.sh      # Stop 前验证
│   └── commands/
│       └── fix-errors.md      # /fix-errors 自定义命令
├── ERROR_LOG.md               # 错误记录（自动维护）
├── CLAUDE.md
└── pixi.toml
```
