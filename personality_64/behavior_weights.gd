extends RefCounted
class_name BehaviorWeights

## 战斗行为事件 → 16细分认知功能 映射权重配置
## 所有权重参数集中管理，方便后期调参

const CF = preload("res://personality_64/cognitive_functions.gd")

# 行为类型常量
const EVENT_CHARGE_ATTACK := "charge_attack"          # 主动冲锋贴脸
const EVENT_HOLD_POSITION := "hold_position"          # 固守掩体架点
const EVENT_FLANK_MANEUVER := "flank_maneuver"        # 绕后/侧翼机动
const EVENT_RETREAT := "retreat"                       # 后撤/战术撤退
const EVENT_HEADSHOT := "headshot"                     # 爆头精准射击
const EVENT_PREAIME_POSITION := "preaime_position"    # 预判卡位
const EVENT_WEAPON_SWITCH := "weapon_switch"          # 切换武器
const EVENT_COVER_REUSE := "cover_reuse"              # 重复使用同一掩体
const EVENT_ROUTE_CHANGE := "route_change"            # 更换进攻路线
const EVENT_HIGH_PRIORITY_KILL := "high_priority_kill" # 优先击杀高威胁目标
const EVENT_TEAM_SUPPORT := "team_support"            # 支援队友
const EVENT_SOLO_PLAY := "solo_play"                  # 独自行动
const EVENT_TRADE_CALCULATION := "trade_calculation"  # 计算交换比
const EVENT_RISK_TAKE := "risk_take"                  # 高风险决策
const EVENT_CONSERVATIVE_PLAY := "conservative_play"  # 保守打法

# 每个行为事件对16功能的权重加成
# 格式: {事件类型: {功能ID: 权重值}}
static func get_event_weights() -> Dictionary:
	var F = CF.Function16
	return {
		EVENT_CHARGE_ATTACK: {
			F.SE_EXPLORATORY: 8.0,   # 探索型享受冲锋刺激
			F.NE_DIVERGENT: 3.0,     # 发散型喜欢即兴行动
			F.TE_EXECUTIVE: 2.0,     # 执行型快速决策
			F.FI_INDIVIDUATING: -2.0 # 个体型倾向内省而非冲动
		},
		EVENT_HOLD_POSITION: {
			F.SE_STABILIZING: 6.0,   # 稳定型享受维持现状
			F.SI_HOMEOSTATIC: 7.0,   # 稳态型遵循既定防御
			F.TE_EMPIRICAL: 3.0,     # 实证型依赖已验证的位置
			F.NE_DIVERGENT: -3.0     # 发散型不喜欢固守
		},
		EVENT_FLANK_MANEUVER: {
			F.NE_INTEGRATIVE: 6.0,   # 整合型发现隐藏路线
			F.NE_DIVERGENT: 5.0,     # 发散型探索多路径
			F.SE_EXPLORATORY: 4.0,   # 探索型喜欢新路线
			F.TI_ANALYTICAL: 3.0,    # 分析型计算侧翼角度
			F.SI_HOMEOSTATIC: -3.0   # 稳态型不喜欢偏离
		},
		EVENT_RETREAT: {
			F.SI_RECOLLECTIVE: 5.0,  # 回忆型基于过去经验撤退
			F.SI_HOMEOSTATIC: 4.0,   # 稳态型维护安全
			F.NI_PROPHETIC: 3.0,     # 预见型预判危险
			F.TI_ANALYTICAL: 3.0,    # 分析型评估形势
			F.SE_EXPLORATORY: -4.0   # 探索型不喜欢后撤
		},
		EVENT_HEADSHOT: {
			F.TI_PRECISION: 8.0,     # 精确型追求精准
			F.SE_STABILIZING: 3.0,   # 稳定型稳定瞄准
			F.TE_EMPIRICAL: 3.0,     # 实证型依赖精确数据
			F.NE_DIVERGENT: -2.0     # 发散型不太注重精确
		},
		EVENT_PREAIME_POSITION: {
			F.NI_PROPHETIC: 7.0,     # 预见型预判敌人行动
			F.NI_SYNTHESIZING: 5.0,  # 综合型整合信息预判
			F.TI_ANALYTICAL: 4.0,    # 分析型推理敌人路线
			F.SE_EXPLORATORY: -2.0   # 探索型更倾向即时反应
		},
		EVENT_WEAPON_SWITCH: {
			F.NE_DIVERGENT: 5.0,     # 发散型喜欢尝试
			F.SE_EXPLORATORY: 4.0,   # 探索型寻求变化
			F.NE_INTEGRATIVE: 3.0,   # 整合型适应不同情况
			F.SI_HOMEOSTATIC: -3.0   # 稳态型偏好固定配置
		},
		EVENT_COVER_REUSE: {
			F.SI_HOMEOSTATIC: 6.0,   # 稳态型重复已验证的安全位置
			F.SI_RECOLLECTIVE: 5.0,  # 回忆型依赖过去成功的掩体
			F.SE_STABILIZING: 4.0,   # 稳定型享受熟悉位置
			F.NE_DIVERGENT: -4.0     # 发散型不喜欢重复
		},
		EVENT_ROUTE_CHANGE: {
			F.NE_DIVERGENT: 7.0,     # 发散型喜欢探索新路线
			F.SE_EXPLORATORY: 5.0,   # 探索型寻求新体验
			F.NE_INTEGRATIVE: 4.0,   # 整合型尝试新联系
			F.SI_HOMEOSTATIC: -4.0   # 稳态型不喜欢改变
		},
		EVENT_HIGH_PRIORITY_KILL: {
			F.TE_EXECUTIVE: 6.0,     # 执行型优先处理关键目标
			F.TE_EMPIRICAL: 5.0,     # 实证型基于威胁评估
			F.TI_ANALYTICAL: 4.0,    # 分析型计算优先级
			F.NI_SYNTHESIZING: 3.0,  # 综合型把握全局
			F.FE_HARMONIZING: -2.0   # 和谐型可能更关注团队而非效率
		},
		EVENT_TEAM_SUPPORT: {
			F.FE_HARMONIZING: 8.0,   # 和谐型照顾队友
			F.FE_INFLUENCING: 4.0,   # 影响型引导团队
			F.FI_AUTHENTICATING: 3.0,# 真实型基于价值观帮助
			F.TI_ANALYTICAL: -2.0,   # 分析型可能更关注逻辑
			F.FI_INDIVIDUATING: -3.0 # 个体型更关注自我
		},
		EVENT_SOLO_PLAY: {
			F.FI_INDIVIDUATING: 6.0, # 个体型独立行动
			F.FI_AUTHENTICATING: 4.0,# 真实型坚持自我方式
			F.TI_PRECISION: 3.0,     # 精确型独立分析
			F.FE_HARMONIZING: -4.0,  # 和谐型不喜欢脱离团队
		},
		EVENT_TRADE_CALCULATION: {
			F.TI_ANALYTICAL: 7.0,    # 分析型计算交换比
			F.TI_PRECISION: 5.0,     # 精确型精确计算
			F.TE_EMPIRICAL: 4.0,     # 实证型基于数据评估
			F.NE_INTEGRATIVE: 3.0,   # 整合型综合评估
			F.SE_EXPLORATORY: -3.0   # 探索型不太计算
		},
		EVENT_RISK_TAKE: {
			F.SE_EXPLORATORY: 7.0,   # 探索型享受风险
			F.NE_DIVERGENT: 5.0,     # 发散型喜欢不确定性
			F.FI_INDIVIDUATING: 3.0, # 个体型追随内心
			F.SI_HOMEOSTATIC: -5.0,  # 稳态型规避风险
			F.SI_RECOLLECTIVE: -3.0  # 回忆型基于过去规避
		},
		EVENT_CONSERVATIVE_PLAY: {
			F.SI_HOMEOSTATIC: 6.0,   # 稳态型保守
			F.SI_RECOLLECTIVE: 5.0,  # 回忆型依赖经验
			F.TE_EMPIRICAL: 4.0,     # 实证型依赖验证方法
			F.SE_EXPLORATORY: -5.0,  # 探索型不喜欢保守
			F.NE_DIVERGENT: -4.0     # 发散型不喜欢保守
		}
	}

# 根据事件类型获取权重
static func get_weights_for_event(event_type: String) -> Dictionary:
	var all_weights := get_event_weights()
	return all_weights.get(event_type, {})
