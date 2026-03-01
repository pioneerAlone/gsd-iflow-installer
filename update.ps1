# GSD for iFlow CLI 更新脚本 (Windows PowerShell)
# 用法: ~/.iflow/update-gsd.ps1

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GSD for iFlow CLI Updater (Windows)                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$iflowDir = "$env:USERPROFILE\.iflow"
$geminiDir = "$env:USERPROFILE\.gemini"
$versionFile = "$iflowDir\get-shit-done\VERSION"

# 获取当前版本
$currentVersion = "unknown"
if (Test-Path $versionFile) {
    $currentVersion = Get-Content $versionFile -Raw).Trim()
    Write-Host "📌 当前版本: $currentVersion"
}

# 获取最新版本
Write-Host "🔍 检查最新版本..." -ForegroundColor Yellow
try {
    $latestVersion = (npm view get-shit-done-cc version).Trim()
} catch {
    Write-Host "❌ 无法检查最新版本（网络问题或 npm 不可用）" -ForegroundColor Red
    exit 1
}

Write-Host "🌐 最新版本: $latestVersion"

# 检查是否需要更新
if ($currentVersion -eq $latestVersion) {
    Write-Host "✅ 已是最新版本，无需更新" -ForegroundColor Green
    exit 0
}

Write-Host ""

# 确认更新
$confirm = Read-Host "是否更新? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消更新"
    exit 0
}

Write-Host ""
Write-Host "📦 正在更新..." -ForegroundColor Yellow
Write-Host ""

# 1. 重新安装到 Gemini 目录
Write-Host "  [1/4] 下载最新版本..." -ForegroundColor DarkGray
npx get-shit-done-cc@latest --gemini --global

# 2. 备份现有配置
Write-Host "  [2/4] 备份现有配置..." -ForegroundColor DarkGray
$backupDir = "$iflowDir\backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
if (Test-Path "$iflowDir\commands\gsd") {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Copy-Item -Path "$iflowDir\commands\gsd" -Destination $backupDir -Recurse -Force
    Write-Host "        备份位置: $backupDir"
}

# 3. 复制更新后的文件
Write-Host "  [3/4] 复制新文件..." -ForegroundColor DarkGray
Copy-Item -Path "$geminiDir\commands\gsd" -Destination "$iflowDir\commands\gsd" -Recurse -Force
Copy-Item -Path "$geminiDir\agents" -Destination "$iflowDir\agents" -Recurse -Force
Copy-Item -Path "$geminiDir\get-shit-done" -Destination "$iflowDir\get-shit-done" -Recurse -Force
Copy-Item -Path "$geminiDir\hooks" -Destination "$iflowDir\hooks" -Recurse -Force

if (Test-Path "$geminiDir\gsd-file-manifest.json") {
    Copy-Item -Path "$geminiDir\gsd-file-manifest.json" -Destination $iflowDir -Force
}
if (Test-Path "$geminiDir\package.json") {
    Copy-Item -Path "$geminiDir\package.json" -Destination $iflowDir -Force
}

# 4. 修复路径引用
Write-Host "  [4/4] 修复路径引用..." -ForegroundColor DarkGray
$userHome = $env:USERPROFILE -replace '\\', '/'
$oldPath = "$userHome/.gemini/"
$newPath = "$userHome/.iflow/"

Get-ChildItem -Path "$iflowDir\commands\gsd\*.toml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace [regex]::Escape($oldPath), $newPath
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# 获取新版本
$newVersion = "unknown"
if (Test-Path $versionFile) {
    $newVersion = (Get-Content $versionFile -Raw).Trim()
}

# 完成
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ GSD 更新完成！                                         ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "版本变化: $currentVersion → $newVersion"
Write-Host ""
Write-Host "⚠️  请重启 iFlow CLI 以应用更新" -ForegroundColor Yellow
Write-Host ""
