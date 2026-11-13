# 火星竞技场 64型人格评价系统

## 项目概述

基于Godot 4.x开发的3D FPS枪战竞技场游戏，创新性地集成了**荣格斯二代16功能-64型人格评价系统**。通过战斗行为日志和无线电对话选择双数据源，实时评估玩家的认知功能倾向，对局结束后输出个性化人格报告。

## 环境要求

### Godot引擎
- **版本要求**：Godot 4.2 或更高版本
- **下载地址**：https://godotengine.org/download
- **推荐版本**：Godot 4.2.x stable

### 系统要求
- 操作系统：Windows 10+, macOS 10.15+, Linux
- 显卡：支持OpenGL 3.3+ 或 Vulkan
- 内存：4GB RAM 以上
- 存储：500MB 可用空间

## 安装步骤

### 1. 安装Godot 4

**Windows:**
1. 下载 Godot 4.2 Standard 版本
2. 解压到任意目录（无需安装）
3. 运行 `Godot_v4.2-stable_win64.exe`

**macOS:**
1. 下载 Godot 4.2 DMG 文件
2. 打开并将 Godot 拖入 Applications 文件夹
3. 从 Launchpad 启动 Godot

**Linux:**
```bash
# 下载
wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_x11.64.zip

# 解压
unzip Godot_v4.2-stable_x11.64.zip

# 运行
./Godot_v4.2-stable_x11.64
```

### 2. 打开项目

1. 启动 Godot 编辑器
2. 点击 "Import" 按钮
3. 选择项目目录 `mars-arena-64type/`
4. 点击 "Import & Edit" 进入编辑器

### 3. 运行游戏

- **F5** 或点击播放按钮启动游戏
- 首次运行会自动构建资源缓存

## 操作说明

### 基础操作

| 按键 | 功能 |
|-----|------|
| **W/A/S/D** | 移动 |
| **鼠标移动** | 视角控制 |
| **左键** | 射击 |
| **右键** | 瞄准（预留） |
| **Shift** | 冲刺 |
| **空格** | 跳跃 |
| **R** | 换弹 |
| **Q** | 切换武器 |
| **F** | 互动（预留） |
| **ESC** | 暂停/继续 |

### 游戏流程

1. **开始游戏**：进入场景，自动开始第1波敌人
2. **战斗阶段**：消灭所有敌人
3. **对话阶段**：波次间隙弹出无线电对话，做出选择
4. **循环**：重复战斗-对话，共3个波次
5. **结算**：显示16功能雷达图和64型人格报告

## Headless模式校验

在无GUI环境下进行脚本语法和场景校验：

```bash
# 进入项目目录
cd mars-arena-64type

# 执行脚本校验
godot --headless --check-only --script res://personality_64/personality_tracker.gd

# 场景加载校验
godot --headless --path . --quit
```

**注意**：完整游戏运行需要GUI版本的Godot编辑器。

## 项目结构

```
mars-arena-64type/
├── project.godot              # Godot项目配置
├── README.md                  # 本文件
│
├── player/                    # 玩家相关
│   ├── player.tscn           # 玩家场景
│   └── player_controller.gd  # 玩家控制器
│
├── enemy/                     # 敌人相关
│   ├── enemy.tscn            # 敌人场景
│   └── enemy_base.gd         # 敌人AI
│
├── weapon/                    # 武器相关
│   └── weapon_resource.gd    # 武器资源定义
│
├── ui/                        # UI界面
│   ├── hud.gd                # 战斗HUD
│   ├── dialogue_ui.gd        # 对话界面
│   └── result_screen.gd      # 结算界面（含雷达图）
│
├── personality_64/            # 人格系统核心
│   ├── cognitive_functions.gd      # 16功能定义
│   ├── personality_64types.gd      # 64型人格定义
│   ├── personality_tracker.gd      # 人格追踪器（Autoload）
│   └── behavior_weights.gd         # 行为权重配置
│
├── scenario/                  # 场景与流程
│   ├── main.tscn             # 主场景
│   ├── main.gd               # 主场景控制器
│   ├── wave_manager.gd       # 波次管理
│   └── dialogue_manager.gd   # 对话管理（Autoload）
│
├── data/                      # 全局数据
│   └── game_manager.gd       # 游戏管理器（Autoload）
│
└── docs/                      # 文档
    └── personality_64_model.md  # 人格系统理论文档
```

## 人格系统说明

### 核心机制

1. **双数据源采集**
   - 战斗行为（60%权重）：冲锋、架点、绕后、爆头等
   - 对话选择（40%权重）：战术决策、资源分配、信念抉择

2. **16细分认知功能**
   - 每个荣格原始功能分化为2个子形态
   - 例如：Se → Se探索型 + Se稳定型

3. **64型人格推导**
   - 基于主导+辅助细分功能组合
   - 输出人格代号、关键词、个性化解读

### 结算报告内容

- **16功能雷达图**：可视化展示各功能得分
- **人格类型**：64型之一（如"探险家"、"战略家"等）
- **功能栈**：主导/辅助/第三/第四功能
- **行为解读**：引用本局实际行为的个性化分析
- **战斗统计**：击杀、命中率、冲锋次数等

## 配置调整

### 修改人格权重

编辑 `personality_64/behavior_weights.gd`：

```gdscript
EVENT_CHARGE_ATTACK: {
    SE_EXPLORATORY: 8.0,   # 调整此值改变冲锋对Se探索的影响
    NE_DIVERGENT: 3.0,
    # ...
}
```

### 修改数据源权重

编辑 `personality_64/personality_tracker.gd`：

```gdscript
const BATTLE_WEIGHT := 0.6   # 战斗行为权重
const DIALOGUE_WEIGHT := 0.4 # 对话选择权重
```

### 添加新对话

编辑 `scenario/dialogue_manager.gd` 中的 `_init_dialogues()` 方法。

## 已知问题与未完成项

### 已实现功能
- ✅ 基础FPS移动和射击
- ✅ 敌人AI状态机（巡逻-追击-攻击）
- ✅ 3波敌人波次系统
- ✅ 无线电对话系统
- ✅ 16功能行为采集
- ✅ 64型人格推导
- ✅ 雷达图绘制
- ✅ 结算界面

### 已知问题
- ⚠️ 导航网格未烘焙，敌人寻路可能不完美
- ⚠️ 缺少音频资源（已预留接口）
- ⚠️ 武器模型为简单几何体
- ⚠️ 敌人死亡效果较简单

### 待完善功能
- 🔲 更精细的敌人AI（掩体利用、团队配合）
- 🔲 武器切换动画
- 🔲 音效系统
- 🔲 粒子特效（枪口火焰、击中效果）
- 🔲 存档系统
- 🔲 更多对话分支
- 🔲 人格倾向反馈机制优化

## 技术细节

### 使用的Godot 4特性
- CharacterBody3D：玩家和敌人控制器
- RayCast3D：射击判定
- NavigationAgent3D：敌人寻路
- SubResource：内联资源定义
- Autoload：全局单例
- Signal：事件驱动架构

### 性能优化
- 使用对象池管理敌人实例（待实现）
- 延迟加载非关键资源
- LOD系统（待实现）

## 许可证

本项目仅供学习和研究使用。

荣格斯人格理论参考自：https://www.jungus.cn/

## 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- 项目文档

---

**版本**：1.0.0  
**最后更新**：2026-11-13  
**Godot版本**：4.2+
