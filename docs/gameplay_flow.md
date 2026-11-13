# 对局流程文档

## 完整游戏链路

本文档描述从开局到结算的完整游戏流程，包括战斗、对话、人格评估的交互链路。

## 流程概览

```
游戏启动
  ↓
主场景加载
  ↓
初始化系统（人格追踪器、游戏管理器、对话管理器）
  ↓
玩家进入场景
  ↓
┌─────────────────────────────────────┐
│ 第1波战斗                           │
│ - 5个敌人                           │
│ - 基础血量和伤害                    │
│ - 实时行为采集                      │
└─────────────────────────────────────┘
  ↓
波次完成
  ↓
┌─────────────────────────────────────┐
│ 无线电对话1                         │
│ - 战术取舍抉择                      │
│ - 4个选项                           │
│ - 实时计入人格分数                  │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 第2波战斗                           │
│ - 8个敌人                           │
│ - 1.3x血量，1.2x伤害              │
│ - 继续行为采集                      │
└─────────────────────────────────────┘
  ↓
波次完成
  ↓
┌─────────────────────────────────────┐
│ 无线电对话2                         │
│ - 资源分配抉择                      │
│ - 4个选项                           │
│ - 实时计入人格分数                  │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 第3波战斗（最终波）                 │
│ - 12个敌人                          │
│ - 1.6x血量，1.5x伤害              │
│ - 继续行为采集                      │
└─────────────────────────────────────┘
  ↓
所有波次完成
  ↓
┌─────────────────────────────────────┐
│ 人格计算                            │
│ - 归一化战斗分数（0-100）           │
│ - 归一化对话分数（0-100）           │
│ - 加权合并（60%战斗 + 40%对话）     │
│ - 排序16功能                        │
│ - 推导64型人格                      │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 结算界面                            │
│ - 16功能雷达图                      │
│ - 人格类型卡片                      │
│ - 个性化解读                        │
│ - 战斗统计                          │
│ - 对话记录                          │
└─────────────────────────────────────┘
  ↓
玩家选择"重新开局"
  ↓
重置所有状态
  ↓
返回主场景
```

## 详细流程说明

### 1. 游戏启动

**触发条件**：玩家在Godot编辑器中按F5运行项目

**执行步骤**：
1. 加载 `scenario/main.tscn` 主场景
2. 初始化Autoload单例：
   - `PersonalityTracker`：人格追踪器
   - `GameManager`：游戏管理器
   - `DialogueManager`：对话管理器
3. 创建火星竞技场环境
4. 实例化玩家角色
5. 启动波次管理器

**代码位置**：`scenario/main.gd` - `_ready()`

### 2. 第1波战斗

**配置**：
- 敌人数量：5
- 血量倍率：1.0x
- 伤害倍率：1.0x
- 得分：100分/敌人

**行为采集**：
- 每次射击 → 记录弹药消耗
- 命中敌人 → 记录伤害输出
- 击杀敌人 → 记录击杀事件
- 冲锋/架点/绕后 → 记录战术行为

**示例行为日志**：
```
[00:15.2] charge_attack: 主动冲锋贴脸作战
[00:23.7] headshot: 精准爆头击杀
[00:45.1] hold_position: 固守掩体架点
[01:02.3] flank_maneuver: 绕后侧翼机动
```

**代码位置**：
- 波次管理：`scenario/wave_manager.gd`
- 行为记录：`player/player_controller.gd`

### 3. 无线电对话1

**触发条件**：第1波所有敌人被消灭

**对话内容**：
```
指挥官：干员，第一波敌人已清除。前方侦察显示有更强的敌军集结。你建议如何推进？

选项1：立即突击，趁他们还没完全集结
  → Se探索 +8, Ne发散 +4, Te执行 +3

选项2：先侦察敌情，制定详细计划再行动
  → Ni预见 +7, Ti分析 +5, Si回忆 +3

选项3：呼叫支援，等待增援到达
  → Fe和谐 +6, Si稳态 +4, Te实证 +3

选项4：绕到侧翼，寻找薄弱点突破
  → Ne整合 +6, Ne发散 +5, Ti分析 +4
```

**人格反馈**：
- 系统根据当前人格分数，高亮与玩家倾向一致的选项
- 例如：如果Se探索分数最高，选项1会显示"[倾向]"标记

**代码位置**：
- 对话触发：`scenario/main.gd` - `_on_dialogue_phase()`
- 对话数据：`scenario/dialogue_manager.gd`
- 对话UI：`ui/dialogue_ui.gd`

### 4. 第2波战斗

**配置**：
- 敌人数量：8
- 血量倍率：1.3x
- 伤害倍率：1.2x
- 得分：200分/敌人

**新增挑战**：
- 敌人更多，需要更好的战术规划
- 敌人更强，需要更精准的射击
- 继续采集行为数据

### 5. 无线电对话2

**对话内容**：
```
后勤官：干员，我们发现了一批补给。但队友受伤需要医疗用品，弹药也需要补充。资源有限，你怎么分配？

选项1：优先补充弹药，火力最重要
  → Te执行 +7, Se探索 +4, Te实证 +3

选项2：先治疗队友，团队生存最重要
  → Fe和谐 +8, Fi真实 +4, Fe影响 +3

选项3：平均分配，保持平衡
  → Si稳态 +6, Te实证 +5, Fe和谐 +3

选项4：保留部分资源作为储备，以防意外
  → Ni预见 +6, Si回忆 +5, Ti分析 +4
```

### 6. 第3波战斗（最终波）

**配置**：
- 敌人数量：12
- 血量倍率：1.6x
- 伤害倍率：1.5x
- 得分：300分/敌人

**最终挑战**：
- 大量敌人涌入
- 考验玩家的极限战斗能力
- 所有行为数据持续采集

### 7. 人格计算

**触发条件**：所有波次完成或玩家死亡

**计算步骤**：

#### 步骤1：归一化战斗分数
```gdscript
# 找出战斗分数中的最大值
max_battle = max(battle_scores.values())

# 归一化到0-100
for func_id in battle_scores:
    normalized_battle[func_id] = (battle_scores[func_id] / max_battle) * 100.0
```

#### 步骤2：归一化对话分数
```gdscript
# 找出对话分数中的最大值
max_dialogue = max(dialogue_scores.values())

# 归一化到0-100
for func_id in dialogue_scores:
    normalized_dialogue[func_id] = (dialogue_scores[func_id] / max_dialogue) * 100.0
```

#### 步骤3：加权合并
```gdscript
for func_id in all_functions:
    final_scores[func_id] = normalized_battle[func_id] * 0.6 + 
                            normalized_dialogue[func_id] * 0.4
```

#### 步骤4：排序功能
```gdscript
# 对16个功能按分数降序排序
sorted_functions = sort(final_scores, descending=True)

# 提取前4名
dominant = sorted_functions[0]    # 主导功能
auxiliary = sorted_functions[1]   # 辅助功能
tertiary = sorted_functions[2]    # 第三功能
inferior = sorted_functions[3]    # 第四功能
```

#### 步骤5：推导64型
```gdscript
# 根据主导+辅助功能组合查找对应人格类型
type_id = type_mapping[dominant][auxiliary]
type_code = get_type_name(type_id)
```

**代码位置**：`personality_64/personality_tracker.gd` - `calculate_result()`

### 8. 结算界面

**显示内容**：

#### 8.1 16功能雷达图
- 使用自定义Control节点绘制
- 16个轴代表16个细分功能
- 多边形面积反映功能分布
- 颜色：蓝色填充，黄色数据点

#### 8.2 人格类型卡片
```
你的人格类型：探险家

主导：Se-探索 | 辅助：Ne-发散 | 第三：Ni-预见 | 第四：Ti-分析

行为关键词：冒险, 创新, 即兴, 灵活
```

#### 8.3 个性化解读
```
【本局行为分析】

战斗行为记录（共15条）：
  - [00:15.2] charge_attack：主动冲锋贴脸作战
  - [00:23.7] headshot：精准爆头击杀
  - [00:45.1] hold_position：固守掩体架点
  ...

对话选择记录（共2条）：
  - [01:30.0] 对话wave1_post 选择0：立即突击，趁他们还没完全集结
  - [03:45.0] 对话wave2_post 选择0：优先补充弹药，火力最重要

【认知功能倾向】
1. Se-探索 (85.3分) - 主动探索环境，寻求新奇的感官体验
2. Ne-发散 (72.1分) - 头脑风暴式思维，探索多种可能性
3. Ni-预见 (58.7分) - 预见未来趋势和结果
4. Ti-分析 (45.2分) - 逻辑推理和分析
```

#### 8.4 战斗统计
```
总击杀：25 | 冲锋：8 | 架点：5 | 绕后：3 | 后撤：2
爆头：6 | 武器切换：4 | 对话选择：2
命中率：68.5% | 总伤害输出：2450 | 总承受伤害：380
```

#### 8.5 对话记录
```
[01:30] 对话wave1_post - 选择0: 立即突击，趁他们还没完全集结
[03:45] 对话wave2_post - 选择0: 优先补充弹药，火力最重要
```

**代码位置**：`ui/result_screen.gd`

### 9. 重新开局

**触发条件**：玩家点击"重新开局"按钮

**执行步骤**：
1. 重置人格追踪器：
   ```gdscript
   PersonalityTracker.reset()
   ```
2. 重置游戏管理器：
   ```gdscript
   GameManager.reset()
   ```
3. 重置对话管理器：
   ```gdscript
   DialogueManager.reset()
   ```
4. 重新加载场景：
   ```gdscript
   get_tree().reload_current_scene()
   ```

**代码位置**：`ui/result_screen.gd` - `_on_restart()`

## 数据流向图

```
玩家行为 ──→ player_controller.gd
              ↓
         行为事件 ──→ PersonalityTracker.record_battle_event()
                         ↓
                    battle_scores[func_id] += weight

对话选择 ──→ dialogue_ui.gd
              ↓
         选择事件 ──→ DialogueManager.select_option()
                         ↓
                    PersonalityTracker.record_dialogue_choice()
                         ↓
                    dialogue_scores[func_id] += weight

对局结束 ──→ PersonalityTracker.calculate_result()
              ↓
         归一化 + 加权 + 排序 + 推导
              ↓
         result_data ──→ result_screen.show_result()
                            ↓
                       显示雷达图 + 人格卡片 + 解读
```

## 关键数据结构

### 行为日志条目
```gdscript
{
    "time": 15.2,              # 时间戳（秒）
    "type": "charge_attack",   # 事件类型
    "context": "主动冲锋贴脸作战",
    "weights": {
        CF.SE_EXPLORATORY: 8.0,
        CF.NE_DIVERGENT: 3.0
    }
}
```

### 对话日志条目
```gdscript
{
    "time": 90.0,
    "dialogue_id": "wave1_post",
    "choice_index": 0,
    "choice_text": "立即突击，趁他们还没完全集结",
    "weights": {
        CF.SE_EXPLORATORY: 8.0,
        CF.NE_DIVERGENT: 4.0,
        CF.TE_EXECUTIVE: 3.0
    }
}
```

### 结算结果
```gdscript
{
    "final_scores": {...},           # 16功能最终分数
    "sorted_functions": [...],       # 排序后的功能列表
    "dominant": CF.SE_EXPLORATORY,   # 主导功能
    "auxiliary": CF.NE_DIVERGENT,    # 辅助功能
    "tertiary": CF.NI_PROPHETIC,     # 第三功能
    "inferior": CF.TI_ANALYTICAL,    # 第四功能
    "type_id": P64.SE_EXP_NE_DIV,    # 64型ID
    "type_code": "探险家",            # 人格代号
    "type_keywords": ["冒险", "创新", "即兴", "灵活"],
    "behavior_log": [...],           # 行为日志
    "dialogue_log": [...],           # 对话日志
    "stats": {...}                   # 统计信息
}
```

## 调试技巧

### 查看实时分数
在 `personality_tracker.gd` 中添加：
```gdscript
func _process(delta: float) -> void:
    if Input.is_action_pressed("ui_page_down"):
        print("Battle scores: ", battle_scores)
        print("Dialogue scores: ", dialogue_scores)
```

### 强制触发结算
在 `main.gd` 中添加：
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_page_up"):
        _end_match(true)
```

### 跳过波次
在 `wave_manager.gd` 中修改：
```gdscript
func _start_next_wave() -> void:
    current_wave = total_waves  # 直接跳到最后一波
    # ...
```

## 扩展建议

### 添加新波次
编辑 `scenario/wave_manager.gd`：
```gdscript
var wave_configs := [
    {"enemy_count": 5, "enemy_health_mult": 1.0, "enemy_damage_mult": 1.0},
    {"enemy_count": 8, "enemy_health_mult": 1.3, "enemy_damage_mult": 1.2},
    {"enemy_count": 12, "enemy_health_mult": 1.6, "enemy_damage_mult": 1.5},
    # 添加新波次
    {"enemy_count": 15, "enemy_health_mult": 2.0, "enemy_damage_mult": 1.8}
]
```

### 添加新对话
编辑 `scenario/dialogue_manager.gd`：
```gdscript
dialogues["wave4_post"] = {
    "id": "wave4_post",
    "title": "紧急通讯",
    "speaker": "指挥官",
    "text": "新的对话内容...",
    "options": [...]
}
```

### 添加新行为事件
编辑 `personality_64/behavior_weights.gd`：
```gdscript
const EVENT_NEW_ACTION := "new_action"

static func get_event_weights() -> Dictionary:
    return {
        # ...
        EVENT_NEW_ACTION: {
            CF.SE_EXPLORATORY: 5.0,
            # ...
        }
    }
```

---

**文档版本**：1.0  
**最后更新**：2026-11-13
