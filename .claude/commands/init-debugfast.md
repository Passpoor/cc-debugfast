在当前项目中安装 cc-debugfast 深度配置。

执行以下步骤：

1. 在当前项目创建 `.claude/hooks/` 和 `.claude/commands/` 目录（如不存在）
2. 从 `/home/huashu007/cc-debugfast/.claude/hooks/` 复制 `detect-errors.sh` 和 `stop-check.sh` 到当前项目的 `.claude/hooks/`
3. 从 `/home/huashu007/cc-debugfast/.claude/commands/` 复制 `fix-errors.md` 到当前项目的 `.claude/commands/`
4. 赋予 hooks 执行权限
5. 如果当前项目没有 `.claude/settings.json`，创建并写入 hooks 配置
6. 如果已有 `.claude/settings.json`，合并 hooks 配置（不覆盖现有配置）
7. 创建 `ERROR_LOG.md` 模板（如不存在）
8. 在当前项目的 `CLAUDE.md` 中追加 cc-debugfast 错误处理规则（如不存在）

完成后报告安装了哪些文件。
