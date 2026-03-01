#!/bin/bash

# GSD for iFlow CLI 安装脚本
# 用法: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gsd-iflow-installer/main/install.sh | bash

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  GSD for iFlow CLI Installer                               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装。请先安装 Node.js 18+"
    exit 1
fi

echo "✓ Node.js 版本: $(node -v)"
echo ""

# 步骤 1: 安装 GSD 到 Gemini CLI 目录
echo "📦 步骤 1/5: 安装 GSD 到 Gemini CLI 目录..."
npx get-shit-done-cc@latest --gemini --global

# 步骤 2: 创建 iFlow 配置目录
echo ""
echo "📁 步骤 2/5: 创建 iFlow 配置目录..."
mkdir -p ~/.iflow/commands

# 步骤 3: 复制 GSD 文件到 iFlow 目录
echo ""
echo "📋 步骤 3/5: 复制 GSD 文件到 iFlow 目录..."
cp -r ~/.gemini/commands/gsd ~/.iflow/commands/
cp -r ~/.gemini/agents ~/.iflow/
cp -r ~/.gemini/get-shit-done ~/.iflow/
cp -r ~/.gemini/hooks ~/.iflow/
cp ~/.gemini/gsd-file-manifest.json ~/.iflow/ 2>/dev/null || true
cp ~/.gemini/package.json ~/.iflow/ 2>/dev/null || true

# 步骤 4: 修复路径引用
echo ""
echo "🔧 步骤 4/5: 修复路径引用..."
USER_HOME=$(echo ~)
sed -i '' "s|$USER_HOME/\.gemini/|$USER_HOME/\.iflow/|g" ~/.iflow/commands/gsd/*.toml 2>/dev/null || \
sed -i "s|$USER_HOME/\.gemini/|$USER_HOME/\.iflow/|g" ~/.iflow/commands/gsd/*.toml

# 步骤 5: 更新 settings.json
echo ""
echo "⚙️  步骤 5/5: 配置 settings.json..."

SETTINGS_FILE="$HOME/.iflow/settings.json"
BACKUP_FILE="$HOME/.iflow/settings.json.backup.$(date +%Y%m%d%H%M%S)"

# 备份现有配置
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "   已备份现有配置到: $BACKUP_FILE"
fi

# 检查是否已有 experimental.enableAgents
if [ -f "$SETTINGS_FILE" ] && grep -q '"enableAgents"' "$SETTINGS_FILE" 2>/dev/null; then
    echo "   settings.json 已包含 enableAgents 配置，跳过"
else
    # 添加必要的配置
    if [ -f "$SETTINGS_FILE" ]; then
        # 使用 node 来合并 JSON
        node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));

settings.experimental = settings.experimental || {};
settings.experimental.enableAgents = true;

settings.hooks = {
  SessionStart: [{
    hooks: [{
      type: 'command',
      command: 'node \"\$HOME/.iflow/hooks/gsd-check-update.js\"'
    }]
  }],
  PostToolUse: [{
    hooks: [{
      type: 'command',
      command: 'node \"\$HOME/.iflow/hooks/gsd-context-monitor.js\"'
    }]
  }]
};

settings.statusLine = {
  type: 'command',
  command: 'node \"\$HOME/.iflow/hooks/gsd-statusline.js\"'
};

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
console.log('   配置已更新');
"
    else
        # 创建新配置
        cat > "$SETTINGS_FILE" << 'EOF'
{
  "experimental": {
    "enableAgents": true
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOME/.iflow/hooks/gsd-check-update.js\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOME/.iflow/hooks/gsd-context-monitor.js\""
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node \"$HOME/.iflow/hooks/gsd-statusline.js\""
  }
}
EOF
        echo "   已创建新的 settings.json"
    fi
fi

# 下载更新脚本
echo ""
echo "📥 下载更新脚本..."
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/unix/update.sh -o ~/.iflow/update-gsd.sh 2>/dev/null && chmod +x ~/.iflow/update-gsd.sh || echo "   跳过更新脚本下载（可手动下载）"

# 完成
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✅ GSD 安装完成！                                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 安装位置: ~/.iflow/"
echo "📝 命令数量: $(ls ~/.iflow/commands/gsd/*.toml 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "下一步:"
echo "  1. 重启 iFlow CLI"
echo "  2. 运行 /gsd:help 验证安装"
echo ""
echo "更新 GSD: ~/.iflow/update-gsd.sh"
echo ""
