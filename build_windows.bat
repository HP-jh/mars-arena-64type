@echo off
chcp 65001 >nul
echo ========================================
echo  火星竞技场64型 - Windows EXE构建工具
echo ========================================
echo.

REM 检查Godot是否在PATH中
where godot >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到Godot命令
    echo.
    echo 请确保：
    echo 1. 已安装Godot 4.2或更高版本
    echo 2. Godot已添加到系统PATH环境变量
    echo    或将godot.exe复制到当前目录
    echo.
    pause
    exit /b 1
)

echo [1/4] 检查Godot版本...
godot --version
echo.

echo [2/4] 创建构建目录...
if not exist "build" mkdir build
echo 完成
echo.

echo [3/4] 开始导出Windows EXE...
echo 这可能需要几分钟时间，请耐心等待...
echo.

REM 执行导出
godot --headless --export-release "Windows Desktop" "build/MarsArena64Type.exe"

if %errorlevel% neq 0 (
    echo.
    echo [错误] 导出失败！
    echo.
    echo 可能的原因：
    echo 1. 缺少Windows导出模板
    echo    解决方法：在Godot编辑器中 编辑器 - 管理导出模板 - 下载
    echo 2. 项目配置错误
    echo    解决方法：检查export_presets.cfg文件
    echo.
    pause
    exit /b 1
)

echo.
echo [4/4] 验证导出文件...
if exist "build/MarsArena64Type.exe" (
    echo ✓ 导出成功！
    echo.
    echo 可执行文件位置: build\MarsArena64Type.exe
    echo.
    
    REM 获取文件大小
    for %%A in ("build\MarsArena64Type.exe") do set size=%%~zA
    set /a sizeMB=%size% / 1048576
    echo 文件大小: %sizeMB% MB
    echo.
    
    echo ========================================
    echo 构建完成！
    echo ========================================
    echo.
    echo 运行游戏: 双击 build\MarsArena64Type.exe
    echo.
    echo 操作说明:
    echo   WASD - 移动
    echo   鼠标 - 视角
    echo   左键 - 射击
    echo   Shift - 冲刺
    echo   空格 - 跳跃
    echo   R - 换弹
    echo   Q - 切换武器
    echo   ESC - 暂停
    echo.
    pause
) else (
    echo [错误] 未找到导出文件
    pause
    exit /b 1
)
