# cc-debugfast

Claude Code 实时错误检测与自修复系统。通过 hooks 在编码过程中自动检测错误、记录日志、阻止带错停止。

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

## 两种部署方式

### 方式一：全局部署（推荐，一次配置所有项目生效）

将 hooks 配置写入 `~/.claude/settings.json`，所有 Claude Code 项目自动受监控。

**配置步骤：**

1. 克隆本仓库：
   ```bash
   cd ~
   git clone https://github.com/Passpoor/cc-debugfast.git
   ```

2. 在 `~/.claude/settings.json` 中添加 hooks 配置：
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Edit|Write",
           "hooks": [
             {
               "type": "command",
               "command": "/home/$USER/cc-debugfast/hooks/detect-errors.sh",
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
               "command": "/home/$USER/cc-debugfast/hooks/stop-check.sh",
               "timeout": 120
             }
           ]
         }
       ]
     }
   }
   ```
   > 注意：将 `$USER` 替换为你的实际用户名，或将 command 路径改为 cc-debugfast 的实际绝对路径。

3. 在 `~/.claude/CLAUDE.md` 中添加错误处理规则（可选但推荐）：
   ```markdown
   ## cc-debugfast 错误检测规则

   编码完成前必须检查 ERROR_LOG.md 是否有 open 状态的错误。
   如有，先修复错误再停止。
   ```

**效果：**
- 在任意项目目录下运行 Claude Code 时，hooks 自动生效
- 每个项目的错误记录在该项目目录的 `ERROR_LOG.md` 中
- 无需逐个配置

### 方式二：项目级部署（适合需要自定义的项目）

在需要深度配置的特定项目中单独安装。

**在 cc-debugfast 项目目录下运行 Claude Code 时：**
```
/init-debugfast
```
会自动将 hooks、commands、ERROR_LOG.md 模板复制到当前项目。

**也可手动配置：**
1. 复制 hooks 脚本到项目：
   ```bash
   mkdir -p your-project/.claude/hooks
   cp ~/cc-debugfast/.claude/hooks/*.sh your-project/.claude/hooks/
   chmod +x your-project/.claude/hooks/*.sh
   ```

2. 在项目的 `.claude/settings.json` 中配置 hooks（参考方式一中的 JSON）

3. 复制 `/fix-errors` 命令（可选）：
   ```bash
   mkdir -p your-project/.claude/commands
   cp ~/cc-debugfast/.claude/commands/fix-errors.md your-project/.claude/commands/
   ```

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
2. 每次编辑文件后，hooks 自动检测语法错误并记录
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
├── hooks/                      # 全局 hooks 脚本
│   ├── detect-errors.sh        # PostToolUse: 文件编辑后检测
│   └── stop-check.sh           # Stop: 停止前验证
├── .claude/
│   ├── settings.json           # cc-debugfast 自身的 hooks 配置
│   ├── hooks/                  # 项目级 hooks（同上，用于 init）
│   │   ├── detect-errors.sh
│   │   └── stop-check.sh
│   └── commands/
│       ├── fix-errors.md       # /fix-errors 修复命令
│       └── init-debugfast.md  # /init-debugfast 安装命令
├── ERROR_LOG.md                # 错误记录（自动维护）
├── CLAUDE.md                   # 项目指令
├── pixi.toml
└── README.md
```

## 注意事项

- Stop hook 使用 exit 2 阻止停止，内置防循环机制（`stop_hook_active` 标记）
- PostToolUse hook 只记录不阻断（exit 0），避免干扰正常编码流程
- 所有检测自动跳过 `.pixi/`、`node_modules/`、`__pycache__/`、`venv/` 等依赖目录
- hooks 超时设置：PostToolUse 60秒，Stop 120秒
