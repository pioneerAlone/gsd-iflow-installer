# GSD (Get Shit Done) for iFlow CLI 安装指南

[![Test Installation Scripts](https://github.com/pioneerAlone/gsd-iflow-installer/actions/workflows/test.yml/badge.svg)](https://github.com/pioneerAlone/gsd-iflow-installer/actions/workflows/test.yml)
[![Release](https://github.com/pioneerAlone/gsd-iflow-installer/actions/workflows/release.yml/badge.svg)](https://github.com/pioneerAlone/gsd-iflow-installer/actions/workflows/release.yml)

本指南帮助你在 **iFlow CLI** 中安装和配置 GSD (Get Shit Done) 插件。

## 📋 目录

- [前置要求](#前置要求)
- [快速安装](#快速安装)
- [手动安装](#手动安装)
- [配置 settings.json](#配置-settingsjson)
- [验证安装](#验证安装)
- [更新 GSD](#更新-gsd)
- [常用命令](#常用命令)
- [故障排除](#故障排除)

---

## 前置要求

- Node.js 18+
- npm 或 npx
- **iFlow CLI 已安装**

### 安装 iFlow CLI

**macOS / Linux:**
```bash
bash -c "$(curl -fsSL https://gitee.com/iflow-ai/iflow-cli/raw/main/install.sh)"
```

**Windows:**
> 请访问 [iFlow CLI 官网](https://iflow.cn) 获取 Windows 安装指南

---

## 快速安装

### 方法一：使用安装脚本（推荐）

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/unix/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/install.ps1 | iex
```

### 方法二：手动安装

**macOS / Linux:**
```bash
# 1. 安装 GSD 到 Gemini CLI 目录
npx get-shit-done-cc@latest --gemini --global

# 2. 创建 iFlow 配置目录
mkdir -p ~/.iflow/commands

# 3. 复制 GSD 文件到 iFlow 目录
cp -r ~/.gemini/commands/gsd ~/.iflow/commands/
cp -r ~/.gemini/agents ~/.iflow/
cp -r ~/.gemini/get-shit-done ~/.iflow/
cp -r ~/.gemini/hooks ~/.iflow/
cp ~/.gemini/gsd-file-manifest.json ~/.iflow/
cp ~/.gemini/package.json ~/.iflow/

# 4. 修复路径引用
sed -i '' "s|/Users/$(whoami)/\.gemini/|/Users/$(whoami)/\.iflow/|g" ~/.iflow/commands/gsd/*.toml

# 5. 配置 settings.json（见下方说明）
```

**Windows (PowerShell):**
```powershell
# 1. 安装 GSD 到 Gemini CLI 目录
npx get-shit-done-cc@latest --gemini --global

# 2. 创建 iFlow 配置目录
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.iflow\commands"

# 3. 复制 GSD 文件到 iFlow 目录
Copy-Item -Path "$env:USERPROFILE\.gemini\commands\gsd" -Destination "$env:USERPROFILE\.iflow\commands\" -Recurse
Copy-Item -Path "$env:USERPROFILE\.gemini\agents" -Destination "$env:USERPROFILE\.iflow\" -Recurse
Copy-Item -Path "$env:USERPROFILE\.gemini\get-shit-done" -Destination "$env:USERPROFILE\.iflow\" -Recurse
Copy-Item -Path "$env:USERPROFILE\.gemini\hooks" -Destination "$env:USERPROFILE\.iflow\" -Recurse
Copy-Item -Path "$env:USERPROFILE\.gemini\gsd-file-manifest.json" -Destination "$env:USERPROFILE\.iflow\" -ErrorAction SilentlyContinue
Copy-Item -Path "$env:USERPROFILE\.gemini\package.json" -Destination "$env:USERPROFILE\.iflow\" -ErrorAction SilentlyContinue

# 4. 修复路径引用
$userHome = $env:USERPROFILE -replace '\\', '/'
Get-ChildItem "$env:USERPROFILE\.iflow\commands\gsd\*.toml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "$userHome/\.gemini/", "$userHome/\.iflow/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# 5. 配置 settings.json（见下方说明）
```

---

## 配置 settings.json

编辑 `~/.iflow/settings.json`，添加以下配置：

```json
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
```

### 完整 settings.json 示例

```json
{
  "selectedAuthType": "oauth-iflow",
  "baseUrl": "https://apis.iflow.cn/v1",
  "modelName": "glm-5",
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@iflow-mcp/context7-mcp@1.0.0"]
    }
  },
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
```

---

## 验证安装

重启 iFlow CLI 后执行：

```
/gsd:help
```

如果看到 GSD 命令列表，说明安装成功！

---

## 更新 GSD

### ⚠️ 重要说明

**不要直接使用 `/gsd:update`！**

原因：
- GSD 官方安装程序安装到 `~/.gemini/` 目录
- iFlow CLI 使用 `~/.iflow/` 目录
- `/gsd:update` 会更新 `~/.gemini/` 而不是 `~/.iflow/`

### 正确的更新方法

#### 方法一：使用更新脚本（推荐）

**macOS / Linux:**
```bash
# 下载更新脚本
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/unix/update.sh -o ~/.iflow/update-gsd.sh
chmod +x ~/.iflow/update-gsd.sh

# 运行更新
~/.iflow/update-gsd.sh
```

**Windows (PowerShell):**
```powershell
# 下载更新脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/update.ps1" -OutFile "$env:USERPROFILE\.iflow\update-gsd.ps1"

# 运行更新
& "$env:USERPROFILE\.iflow\update-gsd.ps1"
```

#### 方法二：手动更新

**macOS / Linux:**

```bash
# 1. 重新安装到 Gemini 目录
npx get-shit-done-cc@latest --gemini --global

# 2. 复制更新后的文件
cp -r ~/.gemini/commands/gsd ~/.iflow/commands/
cp -r ~/.gemini/agents ~/.iflow/
cp -r ~/.gemini/get-shit-done ~/.iflow/
cp -r ~/.gemini/hooks ~/.iflow/
cp ~/.gemini/gsd-file-manifest.json ~/.iflow/
cp ~/.gemini/package.json ~/.iflow/

# 3. 修复路径引用
sed -i '' "s|/Users/$(whoami)/\.gemini/|/Users/$(whoami)/\.iflow/|g" ~/.iflow/commands/gsd/*.toml

# 4. 重启 iFlow CLI
```

**Windows (PowerShell):**
```powershell
# 1. 重新安装到 Gemini 目录
npx get-shit-done-cc@latest --gemini --global

# 2. 复制更新后的文件
Copy-Item -Path "$env:USERPROFILE\.gemini\commands\gsd" -Destination "$env:USERPROFILE\.iflow\commands\" -Recurse -Force
Copy-Item -Path "$env:USERPROFILE\.gemini\agents" -Destination "$env:USERPROFILE\.iflow\" -Recurse -Force
Copy-Item -Path "$env:USERPROFILE\.gemini\get-shit-done" -Destination "$env:USERPROFILE\.iflow\" -Recurse -Force
Copy-Item -Path "$env:USERPROFILE\.gemini\hooks" -Destination "$env:USERPROFILE\.iflow\" -Recurse -Force
Copy-Item -Path "$env:USERPROFILE\.gemini\gsd-file-manifest.json" -Destination "$env:USERPROFILE\.iflow\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$env:USERPROFILE\.gemini\package.json" -Destination "$env:USERPROFILE\.iflow\" -Force -ErrorAction SilentlyContinue

# 3. 修复路径引用
$userHome = $env:USERPROFILE -replace '\\', '/'
Get-ChildItem "$env:USERPROFILE\.iflow\commands\gsd\*.toml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "$userHome/\.gemini/", "$userHome/\.iflow/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# 4. 重启 iFlow CLI
```

---

## 常用命令

| 命令 | 用途 |
|------|------|
| `/gsd:help` | 显示所有命令 |
| `/gsd:new-project` | 新项目初始化 |
| `/gsd:new-milestone` | 新里程碑 |
| `/gsd:plan-phase N` | 规划阶段 N |
| `/gsd:execute-phase N` | 执行阶段 N |
| `/gsd:progress` | 查看进度 |
| `/gsd:pause-work` | 暂停工作，创建恢复文件 |
| `/gsd:check-todos` | 检查待办事项 |

---

## 故障排除

### 问题：`/gsd:help` 命令不识别

**解决方案：**
1. 确认文件已复制到 `~/.iflow/commands/gsd/`
2. 确认 `~/.iflow/settings.json` 中 `experimental.enableAgents` 为 `true`
3. 重启 iFlow CLI

### 问题：路径引用错误

**解决方案：**
```bash
# 重新修复路径
sed -i '' "s|/Users/$(whoami)/\.gemini/|/Users/$(whoami)/\.iflow/|g" ~/.iflow/commands/gsd/*.toml
```

### 问题：Hooks 不生效

**解决方案：**
1. 确认 `~/.iflow/hooks/` 目录存在且包含 `.js` 文件
2. 确认 `settings.json` 中 hooks 配置正确
3. 检查 Node.js 是否在 PATH 中

### 问题：Windows 路径问题

**解决方案：**
- Windows 使用 `$env:USERPROFILE\.iflow\` 代替 `~/.iflow/`
- 确保使用 PowerShell 运行脚本，不要使用 CMD

---

## 卸载

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/unix/uninstall.sh | bash
```

**Windows (PowerShell):**
```powershell
& "$env:USERPROFILE\.iflow\uninstall-gsd.ps1"
```

---

## 仓库文件结构

```
gsd-iflow-installer/
├── .github/
│   └── workflows/
│       ├── test.yml       # CI 测试工作流
│       └── release.yml    # 发布工作流
├── scripts/
│   ├── unix/              # macOS/Linux 脚本
│   │   ├── install.sh
│   │   ├── update.sh
│   │   └── uninstall.sh
│   └── windows/           # Windows 脚本
│       ├── install.ps1
│       ├── update.ps1
│       └── uninstall.ps1
└── README.md
```

## 安装后目录结构

**macOS / Linux:**
```
~/.iflow/
├── commands/
│   └── gsd/           # GSD 命令文件
│       ├── help.toml
│       ├── new-project.toml
│       └── ...
├── agents/            # GSD 代理
│   ├── gsd-codebase-mapper.md
│   ├── gsd-debugger.md
│   └── ...
├── get-shit-done/     # GSD 工作流
│   ├── workflows/
│   ├── templates/
│   └── references/
├── hooks/             # GSD 钩子
│   ├── gsd-check-update.js
│   ├── gsd-context-monitor.js
│   └── gsd-statusline.js
├── settings.json      # iFlow 配置
├── gsd-file-manifest.json
├── package.json
└── update-gsd.sh      # 更新脚本
```

**Windows:**
```
C:\Users\<用户名>\.iflow\
├── commands\gsd\
├── agents\
├── get-shit-done\
├── hooks\
├── settings.json
├── gsd-file-manifest.json
├── package.json
└── update-gsd.ps1
```

---

## 相关链接

- [GSD 官方仓库](https://github.com/gsd-build/get-shit-done)
- [iFlow CLI](https://iflow.cn)
- [Claude Code](https://claude.ai/code)

---

## License

MIT