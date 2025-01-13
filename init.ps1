param (
    [string]$selectedMatch = $env:ONE_CLICK_RUN_PORTABLE_CONDA_SELECTEDMATCH
)

$ErrorActionPreference = "Stop"

# 如果没有传入版本，则获取可选版本并弹出选择界面
if (-not $selectedMatch) {
    Write-Output "获取可选择的版本..."
    $url = "https://github.com/one-click-run/portable-conda/releases/expanded_assets/conda"
    $response = Invoke-WebRequest -Uri $url
    $htmlContent = $response.Content
    $pattern = 'Miniconda3-py.*?-Windows-x86_64.exe'
    $matches = [regex]::Matches($htmlContent, $pattern)
    $uniqueMatches = @{}
    foreach ($match in $matches) {
        $uniqueMatches[$match.Value] = $true
    }

    # 弹出选择界面
    $selectedMatch = $uniqueMatches.Keys | Out-GridView -Title "Select a match" -OutputMode Single

    # 如果用户没有选择任何版本，退出脚本
    if ([string]::IsNullOrEmpty($selectedMatch)) {
        Write-Output "用户没有选择任何版本, 脚本将退出..."
        exit
    }
}

Write-Output "用户选择了: $selectedMatch"

# 下载 Conda 安装包
Write-Output "开始下载 Conda 安装包..."
$downloadUrl = "https://github.com/one-click-run/portable-conda/releases/download/conda/$selectedMatch"
$localFileName = "$selectedMatch"

# 检查文件是否已经存在
if (-Not (Test-Path $localFileName)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $localFileName
    Write-Output "下载完成..."
} else {
    Write-Output "文件已存在，跳过下载。"
}

# 检查是否存在 OCR-portable-conda 文件夹
$condaFolder = "$PWD\OCR-portable-conda"
$installDir = "$PWD\OCR-portable-conda"

if (Test-Path $condaFolder) {
    Write-Output "发现 OCR-portable-conda 文件夹，进行修复..."

    # 重命名原有 Conda 文件夹
    $oldInstallDir = "$PWD\OCR-portable-conda-old"

    # 如果 OCR-portable-conda-old 文件夹存在，先删除它
    if (Test-Path $oldInstallDir) {
        Remove-Item -Recurse -Force $oldInstallDir
        Write-Output "已删除旧的 OCR-portable-conda-old 文件夹。"
    }

    # 重命名原有 Conda 文件夹
    Rename-Item -Path $installDir -NewName "OCR-portable-conda-old"
    Write-Output "原有 Conda 文件夹已重命名为 OCR-portable-conda-old"

    # 执行静默安装 Conda
    Write-Output "开始执行静默安装..."
    Start-Process -FilePath $localFileName -ArgumentList "/InstallationType=JustMe", "/AddToPath=0", "/RegisterPython=0", "/NoRegistry=1", "/S", "/D=$installDir" -Wait
    Write-Output "Conda 安装完成..."

    # 恢复原有库文件
    Write-Output "开始恢复原有库文件..."
    $oldLibDir = "$oldInstallDir"
    $newLibDir = "$installDir"

    # 检查是否有原有的库文件夹
    if (Test-Path $oldLibDir) {
        # 获取旧目录中的所有文件和子目录
        $items = Get-ChildItem -Path $oldLibDir -Recurse
        foreach ($item in $items) {
            $destPath = $item.FullName.Replace($oldLibDir, $newLibDir)
            # 如果目标文件不存在，才进行移动操作
            if (-not (Test-Path $destPath)) {
                Write-Output "准备移动文件: $($item.FullName)"
                Move-Item -Path $item.FullName -Destination $destPath
            } else {
                # Write-Output "目标文件已存在，跳过: $destPath"
            }
        }
        Write-Output "库文件已恢复..."
    } else {
        Write-Output "没有找到原有的库文件，跳过恢复步骤..."
    }

    # 删除原有的 Conda 文件夹
    Write-Output "删除原有的 Conda 文件夹..."
    Remove-Item -Path $oldInstallDir -Recurse -Force
    Write-Output "原有 Conda 文件夹已删除..."
} else {
    # 如果没有 OCR-portable-conda 文件夹，则进行正常安装
    Write-Output "没有找到 OCR-portable-conda 文件夹，进行常规 Conda 安装..."

    # 执行静默安装 Conda
    Start-Process -FilePath $localFileName -ArgumentList "/InstallationType=JustMe", "/AddToPath=0", "/RegisterPython=0", "/NoRegistry=1", "/S", "/D=$installDir" -Wait
    Write-Output "Conda 安装完成..."
}

# 删除安装包
Remove-Item -Path $localFileName -Force
Write-Output "安装包已删除..."

# 创建修复脚本
Write-Output "创建修复脚本..."
$scriptPath = $PWD.Path
$scriptContent = @"
@echo off
powershell -ExecutionPolicy Bypass -NoProfile -Command "`$env:ONE_CLICK_RUN_PORTABLE_CONDA_SELECTEDMATCH = '$selectedMatch'; irm 'https://raw.githubusercontent.com/one-click-run/portable-conda/main/init.ps1' | iex"
pause
"@
$scriptFilePath = Join-Path $scriptPath "OCR-portable-conda-fix.cmd"
[System.IO.File]::WriteAllLines($scriptFilePath, $scriptContent)

# 创建启动脚本
Write-Output "创建启动脚本..."
$scriptPath = $PWD.Path
$activateScriptPath = Join-Path $scriptPath "OCR-portable-conda\Scripts\activate.bat"
$scriptContent = @"
@echo off
start .\OCR-portable-conda\Scripts\activate.bat
"@
$scriptFilePath = Join-Path $scriptPath "OCR-portable-conda.cmd"
[System.IO.File]::WriteAllLines($scriptFilePath, $scriptContent)

Write-Output "完成"
