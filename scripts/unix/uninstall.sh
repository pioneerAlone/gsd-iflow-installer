#!/bin/bash

# GSD for iFlow CLI 卸载脚本
# 用法: ~/.iflow/uninstall-gsd.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  GSD for iFlow CLI Uninstaller                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "⚠️  即将删除以下内容:"
echo "  - ~/.iflow/commands/gsd/"
echo "  - ~/.iflow/agents/"
echo "  - ~/.iflow/get-shit-done/"
echo "  - ~/.iflow/hooks/"
echo "  - ~/.iflow/gsd-file-manifest.json"
echo "  - ~/.iflow/package.json"
echo "  - ~/.iflow/update-gsd.sh"
echo "  - ~/.iflow/uninstall-gsd.sh"
echo ""

# 确认卸载
read -p "确认卸载? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消卸载"
    exit 0
fi

echo ""
echo "🗑️  正在卸载..."

# 删除 GSD 相关文件
rm -rf ~/.iflow/commands/gsd
rm -rf ~/.iflow/agents
rm -rf ~/.iflow/get-shit-done
rm -rf ~/.iflow/hooks
rm -f ~/.iflow/gsd-file-manifest.json
rm -f ~/.iflow/package.json
rm -f ~/.iflow/update-gsd.sh
rm -f ~/.iflow/uninstall-gsd.sh

# 清理 settings.json 中的 GSD 配置
SETTINGS_FILE="$HOME/.iflow/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo "  清理 settings.json..."
    node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));

delete settings.experimental;
delete settings.hooks;
delete settings.statusLine;

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
" 2>/dev/null || echo "  请手动清理 settings.json"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✅ GSD 已卸载                                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
