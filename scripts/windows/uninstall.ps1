# GSD for iFlow CLI 卸载脚本 (Windows PowerShell)
# 用法:
#   本地执行: ~/.iflow/uninstall-gsd.ps1
#   远程执行: irm https://raw.githubusercontent.com/pioneerAlone/gsd-iflow-installer/main/scripts/windows/uninstall.ps1 | iex

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  GSD for iFlow CLI Uninstaller (Windows)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$iflowDir = "$env:USERPROFILE\.iflow"

Write-Host "⚠️  即将删除以下内容:" -ForegroundColor Yellow
Write-Host "  - $iflowDir\commands\gsd\"
Write-Host "  - $iflowDir\agents\"
Write-Host "  - $iflowDir\get-shit-done\"
Write-Host "  - $iflowDir\hooks\"
Write-Host "  - $iflowDir\gsd-file-manifest.json"
Write-Host "  - $iflowDir\package.json"
Write-Host "  - $iflowDir\update-gsd.ps1"
Write-Host "  - $iflowDir\uninstall-gsd.ps1"
Write-Host ""

# 确认卸载
$confirm = Read-Host "确认卸载? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消卸载"
    exit 0
}

Write-Host ""
Write-Host "🗑️  正在卸载..." -ForegroundColor Yellow

# 删除 GSD 相关文件
$pathsToRemove = @(
    "$iflowDir\commands\gsd",
    "$iflowDir\agents",
    "$iflowDir\get-shit-done",
    "$iflowDir\hooks",
    "$iflowDir\gsd-file-manifest.json",
    "$iflowDir\package.json",
    "$iflowDir\update-gsd.ps1",
    "$iflowDir\uninstall-gsd.ps1"
)

foreach ($path in $pathsToRemove) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 清理 settings.json 中的 GSD 配置
$settingsFile = "$iflowDir\settings.json"
if (Test-Path $settingsFile) {
    Write-Host "  清理 settings.json..." -ForegroundColor DarkGray
    try {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
        
        # 移除 GSD 相关配置
        $settings.PSObject.Properties.Remove("experimental")
        $settings.PSObject.Properties.Remove("hooks")
        $settings.PSObject.Properties.Remove("statusLine")
        
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
    } catch {
        Write-Host "  请手动清理 settings.json" -ForegroundColor DarkGray
    }
}

# 完成
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  GSD 已卸载" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
