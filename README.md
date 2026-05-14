# cc-debugfast

Claude Code 实时错误检测与自修复系统。通过 hooks 在编码过程中自动检测错误、记录日志、阻止带错停止。

## 快速开始

```bash
git clone https://github.com/Passpoor/cc-debugfast.git ~/cc-debugfast
bash ~/cc-debugfast/install.sh
```

完成。所有 Claude Code 项目自动受监控。

卸载：`bash ~/cc-debugfast/uninstall.sh`

## 工作原理

```
Claude Code 编辑/写入文件
        ↓
  PostToolUse hook 自动触发
        ↓
  检测 Python / Shell / R / Node.js 语法错误
        ↓
  写入当前项目的 ERROR_LOG.md
        ↓
  Claude 准备停止时 → Stop hook 验证
        ↓
  失败 → exit 2 → 错误反馈给 Claude → 继续修复
  成功 → 正常结束
```

## install.sh 做了什么

| 步骤 | 操作 |
|---|---|
| 1 | 自动合并 hooks 到 `~/.claude/settings.json`（不覆盖现有配置） |
| 2 | 追加错误处理规则到 `~/.claude/CLAUDE.md`（不重复追加） |
| 3 | 验证 hooks 脚本执行权限 |

已有 `~/.claude/settings.json`？放心，脚本用 `jq` 智能合并，不会丢失你的配置。

## 支持的语言检测

| 语言 | 检测方式 | 触发条件 |
|---|---|---|
| Python | `python3 -m compileall` | 项目中存在 `.py` 文件 |
| Shell | `bash -n` | 项目中存在 `.sh` 文件 |
| R | `Rscript parse()` | 项目中存在 `.R/.r` 文件 |
| Node.js | `npm test` | 项目中存在 `package.json` |

## 使用说明

### 自动流程（无需操作）

1. 正常用 Claude Code 写代码
2. 每次编辑文件后，hooks 自动检测语法错误并记录到 `ERROR_LOG.md`
3. Claude 准备停止时自动验证，有错则阻止停止并继续修复

### 手动修复命令

在 Claude Code 中运行：
```
/fix-errors
```
会读取 ERROR_LOG.md，定位最新的 open 错误，自动修复并验证。

### ERROR_LOG.md 格式

```markdown
# Error Log

## 2026-05-14 11:30:00 PostToolUse check

### Python compile check
./src/main.py
SyntaxError: invalid syntax

**Status:** open
```

错误修复后会追加：
```markdown
## 2026-05-14 11:31:00 Fix applied

- **root cause:** 缺少冒号
- **files changed:** src/main.py
- **validation:** pass
- **Status:** fixed
```

## 项目结构

```
cc-debugfast/
├── install.sh                  # 一键安装
├── uninstall.sh                # 一键卸载
├── hooks/                      # 全局 hooks 脚本（被 settings.json 引用）
│   ├── detect-errors.sh        # PostToolUse: 文件编辑后检测
│   └── stop-check.sh           # Stop: 停止前验证
├── .claude/
│   ├── settings.json           # cc-debugfast 自身的 hooks 配置
│   ├── hooks/                  # 项目级 hooks（/init-debugfast 复制用）
│   └── commands/
│       ├── fix-errors.md       # /fix-errors 修复命令
│       └── init-debugfast.md  # /init-debugfast 项目级安装命令
├── ERROR_LOG.md
├── CLAUDE.md
├── pixi.toml
└── README.md
```

## 注意事项

- Stop hook 使用 exit 2 阻止停止，内置防循环机制
- PostToolUse hook 只记录不阻断（exit 0），避免干扰正常编码流程
- 自动跳过 `.pixi/`、`node_modules/`、`__pycache__/`、`venv/` 等依赖目录
- hooks 超时：PostToolUse 60秒，Stop 120秒
- 安装需要 `jq`（用于合并 JSON 配置），如未安装会提示手动操作
