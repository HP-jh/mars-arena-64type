@echo off
chcp 65001 >nul
echo ========================================
echo 火星竞技场64型 - 打包分发工具
echo ========================================
echo.

REM 检查必要文件
if not exist "project.godot" (
    echo [错误] 未找到project.godot
    echo 请确保在项目根目录运行此脚本
    pause
    exit /b 1
)

echo [1/3] 创建分发目录...
set DIST_NAME=MarsArena64Type_v1.0
if exist "%DIST_NAME%" rmdir /s /q "%DIST_NAME%"
mkdir "%DIST_NAME%"
echo 完成
echo.

echo [2/3] 复制项目文件...

REM 复制核心文件
copy "project.godot" "%DIST_NAME%\" >nul
copy "icon.svg" "%DIST_NAME%\" >nul
copy "README.md" "%DIST_NAME%\" >nul
copy "README_构建EXE.md" "%DIST_NAME%\" >nul
copy "PROJECT_SUMMARY.md" "%DIST_NAME%\" >nul
copy "构建说明.md" "%DIST_NAME%\" >nul

REM 复制构建工具
copy "一键构建.bat" "%DIST_NAME%\" >nul
copy "build_windows.bat" "%DIST_NAME%\" >nul
copy "export_presets.cfg" "%DIST_NAME%\" >nul

REM 复制代码目录
xcopy /s /e /q "player" "%DIST_NAME%\player\" >nul
xcopy /s /e /q "enemy" "%DIST_NAME%\enemy\" >nul
xcopy /s /e /q "weapon" "%DIST_NAME%\weapon\" >nul
xcopy /s /e /q "ui" "%DIST_NAME%\ui\" >nul
xcopy /s /e /q "personality_64" "%DIST_NAME%\personality_64\" >nul
xcopy /s /e /q "scenario" "%DIST_NAME%\scenario\" >nul
xcopy /s /e /q "data" "%DIST_NAME%\data\" >nul
xcopy /s /e /q "docs" "%DIST_NAME%\docs\" >nul

echo 完成
echo.

echo [3/3] 创建快速启动脚本...

REM 创建快速启动脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo title 火星竞技场64型 - 快速开始
echo color 0B
echo echo.
echo echo   ╔════════════════════════════════════════╗
echo echo   ║  火星竞技场64型人格评价系统           ║
echo echo   ║  快速开始向导                         ║
echo echo   ╚════════════════════════════════════════╝
echo echo.
echo echo   欢迎使用火星竞技场64型人格评价系统！
echo echo.
echo echo   ════════════════════════════════════════
echo echo   选择操作：
echo echo   ════════════════════════════════════════
echo echo.
echo echo   1. 构建Windows EXE（需要Godot）
echo echo   2. 查看游戏说明
echo echo   3. 在Godot编辑器中打开项目
echo echo   4. 退出
echo echo.
echo set /p choice=请输入选项（1-4）: 
echo.
echo if "%%choice%%"=="1" goto build
echo if "%%choice%%"=="2" goto readme
echo if "%%choice%%"=="3" goto editor
echo if "%%choice%%"=="4" goto end
echo goto start
echo.
echo :build
echo call 一键构建.bat
echo goto start
echo.
echo :readme
echo start "" "README_构建EXE.md"
echo goto start
echo.
echo :editor
echo where godot ^>nul 2^>nul
echo if %%ERRORLEVEL%% NEQ 0 ^(
echo     echo [错误] 未找到Godot
echo     echo 请先安装Godot 4.2+
echo     pause
echo     goto start
echo ^)
echo godot --editor
echo goto start
echo.
echo :end
echo exit
) > "%DIST_NAME%\快速开始.bat"

echo 完成
echo.

REM 创建ZIP压缩包
echo [打包] 创建ZIP压缩包...
where powershell >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    powershell -command "Compress-Archive -Path '%DIST_NAME%' -DestinationPath '%DIST_NAME%.zip' -Force"
    if exist "%DIST_NAME%.zip" (
        echo ✓ ZIP压缩包创建成功: %DIST_NAME%.zip
        for %%A in ("%DIST_NAME%.zip") do set size=%%~zA
        set /a sizeMB=%size% / 1048576
        echo   文件大小: %sizeMB% MB
    ) else (
        echo [警告] ZIP创建失败，但文件夹已准备好
    )
) else (
    echo [提示] 未找到PowerShell，跳过ZIP创建
    echo 你可以手动压缩 %DIST_NAME% 文件夹
)

echo.
echo ========================================
echo 打包完成！
echo ========================================
echo.
echo 分发内容：
echo   📁 %DIST_NAME%\          - 完整项目文件夹
echo   📦 %DIST_NAME%.zip       - ZIP压缩包（可选）
echo.
echo 使用说明：
echo   1. 将 %DIST_NAME% 文件夹或ZIP发给用户
echo   2. 用户需要安装Godot 4.2+
echo   3. 双击"一键构建.bat"生成EXE
echo   4. 运行生成的EXE即可游戏
echo.
echo 或者直接：
echo   1. 用Godot编辑器打开project.godot
echo   2. 按F5直接运行游戏（无需构建）
echo.
pause
