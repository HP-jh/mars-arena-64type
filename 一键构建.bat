@echo off
chcp 65001 >nul
title 火星竞技场64型 - 快速构建工具
color 0A

echo.
echo   ╔════════════════════════════════════════╗
echo   ║  火星竞技场64型人格评价系统           ║
echo   ║  Windows EXE 一键构建工具             ║
echo   ╚════════════════════════════════════════╝
echo.

REM 检查Godot
where godot >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo   [错误] 未检测到Godot引擎
    echo.
    echo   请按以下步骤操作：
    echo.
    echo   1. 下载Godot 4.2+
    echo      https://godotengine.org/download
    echo.
    echo   2. 将godot.exe添加到系统PATH
    echo      或复制到当前目录
    echo.
    echo   3. 重新运行此脚本
    echo.
    pause
    exit /b 1
)

echo   [✓] Godot引擎检测成功
godot --version
echo.

REM 检查导出模板
echo   [检查] 导出模板...
if not exist "%APPDATA%\Godot\export_templates" (
    color 0E
    echo   [警告] 未检测到导出模板
    echo.
    echo   即将打开Godot编辑器以下载模板...
    echo   请在编辑器中：编辑器 - 管理导出模板 - 下载
    echo.
    pause
    godot --editor
    echo.
    echo   模板下载完成后，请重新运行此脚本
    pause
    exit /b 0
)

echo   [✓] 导出模板已安装
echo.

REM 创建构建目录
if not exist "build" mkdir build
echo   [✓] 构建目录已创建
echo.

REM 开始导出
echo   ════════════════════════════════════════
echo   开始构建 Windows EXE
echo   ════════════════════════════════════════
echo.
echo   这可能需要2-5分钟，请耐心等待...
echo.

godot --headless --export-release "Windows Desktop" "build/MarsArena64Type.exe" 2>&1

if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo   [错误] 构建失败！
    echo.
    echo   可能的解决方案：
    echo   1. 在Godot编辑器中手动导出
    echo   2. 检查export_presets.cfg配置
    echo   3. 查看上方的错误信息
    echo.
    pause
    exit /b 1
)

REM 验证文件
if not exist "build\MarsArena64Type.exe" (
    color 0C
    echo   [错误] 未找到生成的EXE文件
    pause
    exit /b 1
)

REM 获取文件信息
for %%A in ("build\MarsArena64Type.exe") do (
    set size=%%~zA
    set date=%%~tA
)
set /a sizeMB=%size% / 1048576

color 0A
echo.
echo   ╔════════════════════════════════════════╗
echo   ║         ✓ 构建成功！                   ║
echo   ╚════════════════════════════════════════╝
echo.
echo   文件位置: build\MarsArena64Type.exe
echo   文件大小: %sizeMB% MB
echo   创建时间: %date%
echo.
echo   ════════════════════════════════════════
echo   操作说明
echo   ════════════════════════════════════════
echo.
echo   WASD    - 移动
echo   鼠标    - 视角控制
echo   左键    - 射击
echo   Shift   - 冲刺
echo   空格    - 跳跃
echo   R       - 换弹
echo   Q       - 切换武器
echo   ESC     - 暂停/继续
echo.
echo   ════════════════════════════════════════
echo.

REM 询问是否立即运行
set /p run="是否立即运行游戏？(Y/N): "
if /i "%run%"=="Y" (
    echo.
    echo   正在启动游戏...
    start "" "build\MarsArena64Type.exe"
) else (
    echo.
    echo   稍后可以双击 build\MarsArena64Type.exe 运行
)

echo.
pause
