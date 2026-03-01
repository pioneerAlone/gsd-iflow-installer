#!/bin/bash

# GSD for iFlow CLI 更新脚本
# 用法: ~/.iflow/update-gsd.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  GSD for iFlow CLI Updater                                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 获取当前版本
CURRENT_VERSION=""
if [ -f ~/.iflow/get-shit-done/VERSION ]; then
    CURRENT_VERSION=$(cat ~/.iflow/get-shit-done/VERSION)
    echo "📌 当前版本: $CURRENT_VERSION"
fi

# 获取最新版本
echo "🔍 检查最新版本..."
LATEST_VERSION=$(npm view get-shit-done-cc version 2>/dev/null || echo "unknown")

if [ "$LATEST_VERSION" = "unknown" ]; then
    echo "❌ 无法检查最新版本（网络问题或 npm 不可用）"
    exit 1
fi

echo "🌐 最新版本: $LATEST_VERSION"
echo ""

# 检查是否需要更新
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ 已是最新版本，无需更新"
    exit 0
fi

# 确认更新
read -p "是否更新? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消更新"
    exit 0
fi

echo ""
echo "📦 正在更新..."
echo ""

# 1. 重新安装到 Gemini 目录
echo "  [1/4] 下载最新版本..."
npx get-shit-done-cc@latest --gemini --global

# 2. 备份现有配置
echo "  [2/4] 备份现有配置..."
BACKUP_DIR="$HOME/.iflow/backup.$(date +%Y%m%d%H%M%S)"
if [ -d ~/.iflow/commands/gsd ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r ~/.iflow/commands/gsd "$BACKUP_DIR/" 2>/dev/null || true
    echo "        备份位置: $BACKUP_DIR"
fi

# 3. 复制更新后的文件
echo "  [3/4] 复制新文件..."
cp -r ~/.gemini/commands/gsd ~/.iflow/commands/
cp -r ~/.gemini/agents ~/.iflow/
cp -r ~/.gemini/get-shit-done ~/.iflow/
cp -r ~/.gemini/hooks ~/.iflow/
cp ~/.gemini/gsd-file-manifest.json ~/.iflow/ 2>/dev/null || true
cp ~/.gemini/package.json ~/.iflow/ 2>/dev/null || true

# 4. 修复路径引用
echo "  [4/4] 修复路径引用..."
# shellcheck disable=SC2116
USER_HOME=$(echo ~)
# shellcheck disable=SC1090
sed -i '' "s|$USER_HOME/\.gemini/|$USER_HOME/\.iflow/|g" ~/.iflow/commands/gsd/*.toml 2>/dev/null || \
sed -i "s|$USER_HOME/\.gemini/|$USER_HOME/\.iflow/|g" ~/.iflow/commands/gsd/*.toml

# 完成
NEW_VERSION=$(cat ~/.iflow/get-shit-done/VERSION 2>/dev/null || echo "unknown")

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✅ GSD 更新完成！                                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "版本变化: $CURRENT_VERSION → $NEW_VERSION"
echo ""
echo "⚠️  请重启 iFlow CLI 以应用更新"
echo ""
