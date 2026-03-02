# GSD for iFlow CLI 安装脚本 (Windows PowerShell)
# 用法: irm https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/install.ps1 | iex

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  GSD for iFlow CLI Installer (Windows)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js 未安装。请先安装 Node.js 18+" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Node.js 版本: $(node -v)" -ForegroundColor Green
Write-Host ""

# 步骤 1: 安装 GSD 到 Gemini CLI 目录
Write-Host "📦 步骤 1/5: 安装 GSD 到 Gemini CLI 目录..." -ForegroundColor Yellow
npx get-shit-done-cc@latest --gemini --global

# 步骤 2: 创建 iFlow 配置目录
Write-Host ""
Write-Host "📁 步骤 2/5: 创建 iFlow 配置目录..." -ForegroundColor Yellow
$iflowDir = "$env:USERPROFILE\.iflow"
$commandsDir = "$iflowDir\commands"
New-Item -ItemType Directory -Force -Path $commandsDir | Out-Null

# 步骤 3: 复制 GSD 文件到 iFlow 目录
Write-Host ""
Write-Host "📋 步骤 3/5: 复制 GSD 文件到 iFlow 目录..." -ForegroundColor Yellow
$geminiDir = "$env:USERPROFILE\.gemini"

Copy-Item -Path "$geminiDir\commands\gsd" -Destination "$commandsDir\gsd" -Recurse -Force
Copy-Item -Path "$geminiDir\agents" -Destination "$iflowDir\agents" -Recurse -Force
Copy-Item -Path "$geminiDir\get-shit-done" -Destination "$iflowDir\get-shit-done" -Recurse -Force
Copy-Item -Path "$geminiDir\hooks" -Destination "$iflowDir\hooks" -Recurse -Force

if (Test-Path "$geminiDir\gsd-file-manifest.json") {
    Copy-Item -Path "$geminiDir\gsd-file-manifest.json" -Destination $iflowDir -Force
}
if (Test-Path "$geminiDir\package.json") {
    Copy-Item -Path "$geminiDir\package.json" -Destination $iflowDir -Force
}

# 步骤 4: 修复路径引用
Write-Host ""
Write-Host "🔧 步骤 4/5: 修复路径引用..." -ForegroundColor Yellow
$userHome = $env:USERPROFILE -replace '\\', '/'
$oldPath = "$userHome/\.gemini/"
$newPath = "$userHome/\.iflow/"

Get-ChildItem -Path "$commandsDir\gsd\*.toml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace [regex]::Escape($oldPath), $newPath
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# 步骤 5: 更新 settings.json
Write-Host ""
Write-Host "⚙️  步骤 5/5: 配置 settings.json..." -ForegroundColor Yellow

$settingsFile = "$iflowDir\settings.json"

# 备份现有配置
if (Test-Path $settingsFile) {
    $backupFile = "$iflowDir\settings.json.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $settingsFile $backupFile
    Write-Host "   已备份现有配置到: $backupFile"
}

# 读取或创建 settings
if (Test-Path $settingsFile) {
    $settings = Get-Content $settingsFile | ConvertFrom-Json
} else {
    $settings = @{}
}

# 添加必要的配置
if (-not $settings.experimental) {
    $settings | Add-Member -NotePropertyName "experimental" -NotePropertyValue @{} -Force
}
$settings.experimental | Add-Member -NotePropertyName "enableAgents" -NotePropertyValue $true -Force

# 构建 hooks 路径（PowerShell 5.1 兼容：用 JSON 字符串构建复杂对象）
$hookBase = $env:USERPROFILE.Replace('\', '/') + '/.iflow/hooks'

$hooksJson = @"
{
    "SessionStart": [
        {
            "hooks": [
                {
                    "type": "command",
                    "command": "node \"$hookBase/gsd-check-update.js\""
                }
            ]
        }
    ],
    "PostToolUse": [
        {
            "hooks": [
                {
                    "type": "command",
                    "command": "node \"$hookBase/gsd-context-monitor.js\""
                }
            ]
        }
    ]
}
"@

$statusLineJson = @"
{
    "type": "command",
    "command": "node \"$hookBase/gsd-statusline.js\""
}
"@

# 解析 JSON 并添加到 settings
$hooks = $hooksJson | ConvertFrom-Json
$statusLine = $statusLineJson | ConvertFrom-Json

$settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $hooks -Force
$settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statusLine -Force

# 保存 settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile

# 下载更新和卸载脚本
Write-Host ""
Write-Host "下载管理脚本..." -ForegroundColor Yellow
$updateScriptUrl = "https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/update.ps1"
$uninstallScriptUrl = "https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/uninstall.ps1"
$updateScriptPath = "$iflowDir\update-gsd.ps1"
$uninstallScriptPath = "$iflowDir\uninstall-gsd.ps1"

try {
    Invoke-WebRequest -Uri $updateScriptUrl -OutFile $updateScriptPath -UseBasicParsing
    Write-Host "   update-gsd.ps1 已下载"
} catch {
    Write-Host "   跳过 update-gsd.ps1 下载" -ForegroundColor DarkGray
}

try {
    Invoke-WebRequest -Uri $uninstallScriptUrl -OutFile $uninstallScriptPath -UseBasicParsing
    Write-Host "   uninstall-gsd.ps1 已下载"
} catch {
    Write-Host "   跳过 uninstall-gsd.ps1 下载" -ForegroundColor DarkGray
}

# 统计命令数量
$commandCount = (Get-ChildItem "$commandsDir\gsd\*.toml" -ErrorAction SilentlyContinue).Count

# 完成
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  GSD 安装完成!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置: $iflowDir"
Write-Host "命令数量: $commandCount"
Write-Host ""
Write-Host "下一步:"
Write-Host "  1. 重启 iFlow CLI"
Write-Host "  2. 运行 /gsd:help 验证安装"
Write-Host ""
Write-Host "管理命令:"
Write-Host "  更新: $updateScriptPath"
Write-Host "  卸载: $uninstallScriptPath"
Write-Host ""
