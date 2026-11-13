# 🎮 火星竞技场64型人格评价系统

## 🚀 快速开始（3步获得EXE）

### 方法1：一键构建（推荐）

```cmd
1. 安装Godot 4.2+ (https://godotengine.org/download)
2. 将godot.exe添加到系统PATH
3. 双击运行 "一键构建.bat"
```

构建完成后，EXE文件在 `build\MarsArena64Type.exe`

### 方法2：手动构建

1. 打开Godot编辑器
2. 导入项目（选择project.godot）
3. 项目 → 导出 → Windows Desktop → 导出项目
4. EXE文件生成在build目录

---

## 📦 文件说明

### 构建工具
- `一键构建.bat` - 一键构建EXE（最简单）
- `build_windows.bat` - 详细构建脚本
- `构建说明.md` - 完整构建指南
- `export_presets.cfg` - 导出配置

### 游戏文件
- `project.godot` - Godot项目文件
- `README.md` - 项目详细说明
- `PROJECT_SUMMARY.md` - 技术总结

### 游戏代码
- `player/` - 玩家控制器
- `enemy/` - 敌人AI
- `weapon/` - 武器系统
- `ui/` - 用户界面
- `personality_64/` - 人格评价系统
- `scenario/` - 场景和流程
- `data/` - 全局数据管理
- `docs/` - 文档

---

## 🎯 游戏特色

### 核心玩法
- **3D第一人称射击** - 火星殖民地竞技场
- **3波敌人挑战** - 难度递增
- **无线电对话** - 战术决策影响人格评分

### 创新系统
- **荣格斯二代16功能评价** - 不是传统MBTI
- **64型人格原型** - 基于主导+辅助功能组合
- **双数据源采集** - 战斗行为60% + 对话选择40%
- **个性化解读** - 引用实际游戏行为

---

## 🎮 操作说明

| 按键 | 功能 |
|-----|------|
| WASD | 移动 |
| 鼠标 | 视角控制 |
| 左键 | 射击 |
| Shift | 冲刺 |
| 空格 | 跳跃 |
| R | 换弹 |
| Q | 切换武器 |
| ESC | 暂停 |

---

## 📋 系统要求

### 运行EXE
- Windows 10 64位+
- 4GB RAM
- OpenGL 3.3+显卡
- 200MB磁盘空间

### 构建EXE
- Windows 10/11
- Godot 4.2+
- 2GB磁盘空间
- 网络连接（首次下载模板）

---

## 🔧 故障排除

### Q: 构建脚本找不到Godot
**A:** 将godot.exe复制到项目目录，或添加到系统PATH

### Q: 提示缺少导出模板
**A:** 在Godot编辑器中：编辑器 → 管理导出模板 → 下载

### Q: EXE无法运行
**A:** 安装Visual C++ Redistributable
https://aka.ms/vs/17/release/vc_redist.x64.exe

---

## 📚 详细文档

- `README.md` - 完整项目说明
- `PROJECT_SUMMARY.md` - 技术实现细节
- `docs/personality_64_model.md` - 人格系统理论
- `docs/gameplay_flow.md` - 游戏流程说明
- `构建说明.md` - 详细构建指南

---

## 🎓 人格系统简介

### 16细分认知功能
每个荣格原始功能分化为2个子形态：
- Se探索 / Se稳定
- Si回忆 / Si稳态
- Ne发散 / Ne整合
- Ni预见 / Ni综合
- Te执行 / Te实证
- Ti分析 / Ti精确
- Fe和谐 / Fe影响
- Fi真实 / Fi个体

### 64型人格
基于主导+辅助功能组合，例如：
- Se探索 + Ne发散 = **探险家**
- Ni预见 + Te执行 = **决策者**
- Ti分析 + Ne整合 = **理论家**

### 个性化解读
结算时引用实际游戏行为：
> "你在本局中多次选择主动冲锋（Se-探索 +8分），波次1后选择'立即突击'，最终人格类型为【探险家】"

---

## 📞 获取帮助

遇到问题？
1. 查看 `构建说明.md`
2. 检查Godot版本是否为4.2+
3. 确认导出模板已安装
4. 尝试在Godot编辑器中手动导出

---

## 🎉 开始游戏

```cmd
双击 "一键构建.bat"
等待构建完成
运行 build\MarsArena64Type.exe
```

**祝你游戏愉快！**

---

**版本**: 1.0.0  
**Godot版本**: 4.2+  
**最后更新**: 2026-11-13
