extends Node

## 人格追踪器 - 全局Autoload单例
## 持续采集战斗行为事件和对话选择，映射到16细分认知功能

# 引用
const CF = preload("res://personality_64/cognitive_functions.gd")
const P64 = preload("res://personality_64/personality_64types.gd")

# 权重配置
const BATTLE_WEIGHT := 0.6   # 战斗行为数据权重
const DIALOGUE_WEIGHT := 0.4 # 对话选择数据权重

# 16功能原始得分
var battle_scores := {}      # 战斗行为累计分
var dialogue_scores := {}    # 对话选择累计分
var final_scores := {}       # 加权归一化最终分

# 行为日志
var behavior_log := []       # 完整行为事件日志
var dialogue_log := []       # 对话选择日志

# 统计计数器
var stats := {
	"charge_count": 0,       # 冲锋次数
	"hold_position_count": 0, # 架点次数
	"flank_count": 0,        # 绕后次数
	"retreat_count": 0,      # 后撤次数
	"headshot_count": 0,     # 爆头次数
	"team_heal_count": 0,    # 治疗队友次数
	"cover_reuse_count": 0,  # 重复使用掩体次数
	"weapon_switch_count": 0,# 切换武器次数
	"total_kills": 0,        # 总击杀
	"total_damage_dealt": 0.0,
	"total_damage_taken": 0.0,
	"total_shots": 0,
	"total_hits": 0,
	"dialogues_answered": 0
}

# 时间追踪
var match_start_time := 0.0
var current_time := 0.0

func _ready() -> void:
	_init_scores()

func _init_scores() -> void:
	for func_id in CF.FUNCTION_NAMES.keys():
		battle_scores[func_id] = 0.0
		dialogue_scores[func_id] = 0.0
		final_scores[func_id] = 0.0

func reset() -> void:
	_init_scores()
	behavior_log.clear()
	dialogue_log.clear()
	for key in stats:
		stats[key] = 0
	match_start_time = 0.0
	current_time = 0.0

func start_match() -> void:
	reset()
	match_start_time = Time.get_ticks_msec() / 1000.0

func get_elapsed_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - match_start_time

## 记录战斗行为事件
## event_type: 事件类型标识
## func_weights: Dictionary {CF.Function16.XXX: weight_value}
## context: 上下文描述字符串
func record_battle_event(event_type: String, func_weights: Dictionary, context: String = "") -> void:
	current_time = get_elapsed_time()
	
	var log_entry := {
		"time": current_time,
		"type": event_type,
		"context": context,
		"weights": func_weights
	}
	behavior_log.append(log_entry)
	
	# 累加到战斗分数
	for func_id in func_weights:
		if battle_scores.has(func_id):
			battle_scores[func_id] += func_weights[func_id]

## 记录对话选择
## dialogue_id: 对话节点ID
## choice_index: 选择的选项索引
## func_weights: Dictionary {CF.Function16.XXX: weight_value}
## choice_text: 选项文本
func record_dialogue_choice(dialogue_id: String, choice_index: int, func_weights: Dictionary, choice_text: String = "") -> void:
	current_time = get_elapsed_time()
	
	var log_entry := {
		"time": current_time,
		"dialogue_id": dialogue_id,
		"choice_index": choice_index,
		"choice_text": choice_text,
		"weights": func_weights
	}
	dialogue_log.append(log_entry)
	stats["dialogues_answered"] += 1
	
	# 累加到对话分数
	for func_id in func_weights:
		if dialogue_scores.has(func_id):
			dialogue_scores[func_id] += func_weights[func_id]

## 更新统计
func update_stat(stat_name: String, value: float = 1.0) -> void:
	if stats.has(stat_name):
		stats[stat_name] += value

## 计算最终得分并推导64型人格
func calculate_result() -> Dictionary:
	# 1. 归一化战斗分数到0-100
	var normalized_battle := _normalize_scores(battle_scores)
	# 2. 归一化对话分数到0-100
	var normalized_dialogue := _normalize_scores(dialogue_scores)
	
	# 3. 加权合并
	for func_id in CF.FUNCTION_NAMES.keys():
		final_scores[func_id] = normalized_battle.get(func_id, 0) * BATTLE_WEIGHT + \
		                         normalized_dialogue.get(func_id, 0) * DIALOGUE_WEIGHT
	
	# 4. 排序找主导/辅助/第三/第四
	var sorted_funcs := _sort_functions(final_scores)
	
	# 5. 推导64型
	var type_id := _derive_64type(sorted_funcs)
	
	return {
		"final_scores": final_scores.duplicate(),
		"battle_scores_normalized": normalized_battle,
		"dialogue_scores_normalized": normalized_dialogue,
		"sorted_functions": sorted_funcs,
		"dominant": sorted_funcs[0] if sorted_funcs.size() > 0 else -1,
		"auxiliary": sorted_funcs[1] if sorted_funcs.size() > 1 else -1,
		"tertiary": sorted_funcs[2] if sorted_funcs.size() > 2 else -1,
		"inferior": sorted_funcs[3] if sorted_funcs.size() > 3 else -1,
		"type_id": type_id,
		"type_code": P64.get_type_code(type_id),
		"type_keywords": P64.get_type_keywords(type_id),
		"behavior_log": behavior_log.duplicate(),
		"dialogue_log": dialogue_log.duplicate(),
		"stats": stats.duplicate()
	}

func _normalize_scores(scores: Dictionary) -> Dictionary:
	var max_val := 0.0
	for func_id in scores:
		max_val = max(max_val, scores[func_id])
	
	var normalized := {}
	if max_val <= 0.0:
		for func_id in scores:
			normalized[func_id] = 0.0
		return normalized
	
	for func_id in scores:
		normalized[func_id] = clampf((scores[func_id] / max_val) * 100.0, 0.0, 100.0)
	return normalized

func _sort_functions(scores: Dictionary) -> Array:
	var pairs := []
	for func_id in scores:
		pairs.append({"func": func_id, "score": scores[func_id]})
	pairs.sort_custom(func(a, b): return a["score"] > b["score"])
	var result := []
	for p in pairs:
		result.append(p["func"])
	return result

## 根据主导+辅助细分功能组合推导64型
func _derive_64type(sorted_funcs: Array) -> int:
	if sorted_funcs.size() < 2:
		return P64.Type64.SE_EXP_NE_DIV  # 默认
	
	var dominant = sorted_funcs[0]
	var auxiliary = sorted_funcs[1]
	
	# 映射表：主导+辅助 -> 64型
	var mapping := _build_type_mapping()
	var key := [dominant, auxiliary]
	
	if mapping.has(key):
		return mapping[key]
	
	# 如果精确匹配不到，找最接近的
	return _find_closest_type(dominant, auxiliary)

func _build_type_mapping() -> Dictionary:
	var F = CF.Function16
	var T = P64.Type64
	return {
		# Se主导
		[F.SE_EXPLORATORY, F.NE_DIVERGENT]: T.SE_EXP_NE_DIV,
		[F.SE_EXPLORATORY, F.NE_INTEGRATIVE]: T.SE_EXP_NE_INT,
		[F.SE_EXPLORATORY, F.NI_PROPHETIC]: T.SE_EXP_NI_PRO,
		[F.SE_EXPLORATORY, F.NI_SYNTHESIZING]: T.SE_EXP_NI_SYN,
		[F.SE_STABILIZING, F.NE_DIVERGENT]: T.SE_ST_NE_DIV,
		[F.SE_STABILIZING, F.NE_INTEGRATIVE]: T.SE_ST_NE_INT,
		[F.SE_STABILIZING, F.NI_PROPHETIC]: T.SE_ST_NI_PRO,
		[F.SE_STABILIZING, F.NI_SYNTHESIZING]: T.SE_ST_NI_SYN,
		# Si主导
		[F.SI_RECOLLECTIVE, F.SE_EXPLORATORY]: T.SI_REC_SE_EXP,
		[F.SI_RECOLLECTIVE, F.SE_STABILIZING]: T.SI_REC_SE_ST,
		[F.SI_RECOLLECTIVE, F.TE_EXECUTIVE]: T.SI_REC_TE_EXE,
		[F.SI_RECOLLECTIVE, F.TE_EMPIRICAL]: T.SI_REC_TE_EMP,
		[F.SI_HOMEOSTATIC, F.SE_EXPLORATORY]: T.SI_HOM_SE_EXP,
		[F.SI_HOMEOSTATIC, F.SE_STABILIZING]: T.SI_HOM_SE_ST,
		[F.SI_HOMEOSTATIC, F.TE_EXECUTIVE]: T.SI_HOM_TE_EXE,
		[F.SI_HOMEOSTATIC, F.TE_EMPIRICAL]: T.SI_HOM_TE_EMP,
		# Ne主导
		[F.NE_DIVERGENT, F.SE_EXPLORATORY]: T.NE_DIV_SE_EXP,
		[F.NE_DIVERGENT, F.SE_STABILIZING]: T.NE_DIV_SE_ST,
		[F.NE_DIVERGENT, F.SI_RECOLLECTIVE]: T.NE_DIV_SI_REC,
		[F.NE_DIVERGENT, F.SI_HOMEOSTATIC]: T.NE_DIV_SI_HOM,
		[F.NE_INTEGRATIVE, F.SE_EXPLORATORY]: T.NE_INT_SE_EXP,
		[F.NE_INTEGRATIVE, F.SE_STABILIZING]: T.NE_INT_SE_ST,
		[F.NE_INTEGRATIVE, F.SI_RECOLLECTIVE]: T.NE_INT_SI_REC,
		[F.NE_INTEGRATIVE, F.SI_HOMEOSTATIC]: T.NE_INT_SI_HOM,
		# Ni主导
		[F.NI_PROPHETIC, F.SE_EXPLORATORY]: T.NI_PRO_SE_EXP,
		[F.NI_PROPHETIC, F.SE_STABILIZING]: T.NI_PRO_SE_ST,
		[F.NI_PROPHETIC, F.SI_RECOLLECTIVE]: T.NI_PRO_SI_REC,
		[F.NI_PROPHETIC, F.SI_HOMEOSTATIC]: T.NI_PRO_SI_HOM,
		[F.NI_SYNTHESIZING, F.SE_EXPLORATORY]: T.NI_SYN_SE_EXP,
		[F.NI_SYNTHESIZING, F.SE_STABILIZING]: T.NI_SYN_SE_ST,
		[F.NI_SYNTHESIZING, F.SI_RECOLLECTIVE]: T.NI_SYN_SI_REC,
		[F.NI_SYNTHESIZING, F.SI_HOMEOSTATIC]: T.NI_SYN_SI_HOM,
		# Te主导
		[F.TE_EXECUTIVE, F.NE_DIVERGENT]: T.TE_EXE_NE_DIV,
		[F.TE_EXECUTIVE, F.NE_INTEGRATIVE]: T.TE_EXE_NE_INT,
		[F.TE_EXECUTIVE, F.NI_PROPHETIC]: T.TE_EXE_NI_PRO,
		[F.TE_EXECUTIVE, F.NI_SYNTHESIZING]: T.TE_EXE_NI_SYN,
		[F.TE_EMPIRICAL, F.NE_DIVERGENT]: T.TE_EMP_NE_DIV,
		[F.TE_EMPIRICAL, F.NE_INTEGRATIVE]: T.TE_EMP_NE_INT,
		[F.TE_EMPIRICAL, F.NI_PROPHETIC]: T.TE_EMP_NI_PRO,
		[F.TE_EMPIRICAL, F.NI_SYNTHESIZING]: T.TE_EMP_NI_SYN,
		# Ti主导
		[F.TI_ANALYTICAL, F.NE_DIVERGENT]: T.TI_ANA_NE_DIV,
		[F.TI_ANALYTICAL, F.NE_INTEGRATIVE]: T.TI_ANA_NE_INT,
		[F.TI_ANALYTICAL, F.NI_PROPHETIC]: T.TI_ANA_NI_PRO,
		[F.TI_ANALYTICAL, F.NI_SYNTHESIZING]: T.TI_ANA_NI_SYN,
		[F.TI_PRECISION, F.NE_DIVERGENT]: T.TI_PRE_NE_DIV,
		[F.TI_PRECISION, F.NE_INTEGRATIVE]: T.TI_PRE_NE_INT,
		[F.TI_PRECISION, F.NI_PROPHETIC]: T.TI_PRE_NI_PRO,
		[F.TI_PRECISION, F.NI_SYNTHESIZING]: T.TI_PRE_NI_SYN,
		# Fe主导
		[F.FE_HARMONIZING, F.TE_EXECUTIVE]: T.FE_HAR_TE_EXE,
		[F.FE_HARMONIZING, F.TE_EMPIRICAL]: T.FE_HAR_TE_EMP,
		[F.FE_HARMONIZING, F.TI_ANALYTICAL]: T.FE_HAR_TI_ANA,
		[F.FE_HARMONIZING, F.TI_PRECISION]: T.FE_HAR_TI_PRE,
		[F.FE_INFLUENCING, F.TE_EXECUTIVE]: T.FE_INF_TE_EXE,
		[F.FE_INFLUENCING, F.TE_EMPIRICAL]: T.FE_INF_TE_EMP,
		[F.FE_INFLUENCING, F.TI_ANALYTICAL]: T.FE_INF_TI_ANA,
		[F.FE_INFLUENCING, F.TI_PRECISION]: T.FE_INF_TI_PRE,
		# Fi主导
		[F.FI_AUTHENTICATING, F.TE_EXECUTIVE]: T.FI_AUT_TE_EXE,
		[F.FI_AUTHENTICATING, F.TE_EMPIRICAL]: T.FI_AUT_TE_EMP,
		[F.FI_AUTHENTICATING, F.TI_ANALYTICAL]: T.FI_AUT_TI_ANA,
		[F.FI_AUTHENTICATING, F.TI_PRECISION]: T.FI_AUT_TI_PRE,
		[F.FI_INDIVIDUATING, F.TE_EXECUTIVE]: T.FI_IND_TE_EXE,
		[F.FI_INDIVIDUATING, F.TE_EMPIRICAL]: T.FI_IND_TE_EMP,
		[F.FI_INDIVIDUATING, F.TI_ANALYTICAL]: T.FI_IND_TI_ANA,
		[F.FI_INDIVIDUATING, F.TI_PRECISION]: T.FI_IND_TI_PRE
	}

func _find_closest_type(dominant, auxiliary) -> int:
	# 降级：只根据主导功能返回第一个匹配
	var F = CF.Function16
	var T = P64.Type64
	var dominant_first := {
		F.SE_EXPLORATORY: T.SE_EXP_NE_DIV,
		F.SE_STABILIZING: T.SE_ST_NE_DIV,
		F.SI_RECOLLECTIVE: T.SI_REC_SE_EXP,
		F.SI_HOMEOSTATIC: T.SI_HOM_SE_EXP,
		F.NE_DIVERGENT: T.NE_DIV_SE_EXP,
		F.NE_INTEGRATIVE: T.NE_INT_SE_EXP,
		F.NI_PROPHETIC: T.NI_PRO_SE_EXP,
		F.NI_SYNTHESIZING: T.NI_SYN_SE_EXP,
		F.TE_EXECUTIVE: T.TE_EXE_NE_DIV,
		F.TE_EMPIRICAL: T.TE_EMP_NE_DIV,
		F.TI_ANALYTICAL: T.TI_ANA_NE_DIV,
		F.TI_PRECISION: T.TI_PRE_NE_DIV,
		F.FE_HARMONIZING: T.FE_HAR_TE_EXE,
		F.FE_INFLUENCING: T.FE_INF_TE_EXE,
		F.FI_AUTHENTICATING: T.FI_AUT_TE_EXE,
		F.FI_INDIVIDUATING: T.FI_IND_TE_EXE
	}
	return dominant_first.get(dominant, T.SE_EXP_NE_DIV)

## 生成本局个性化解读文本
func generate_interpretation(result: Dictionary) -> String:
	var text := ""
	text += "【人格类型：%s】\n" % result["type_code"]
	text += "主导功能：%s | 辅助功能：%s\n" % [
		CF.get_function_name(result["dominant"]),
		CF.get_function_name(result["auxiliary"])
	]
	text += "\n【本局行为分析】\n"
	
	# 引用实际行为日志
	var log = result["behavior_log"]
	var dlg = result["dialogue_log"]
	
	if log.size() > 0:
		text += "\n战斗行为记录（共%d条）：\n" % log.size()
		var shown := 0
		for entry in log:
			if shown >= 5:
				break
			text += "  - [%.1fs] %s：%s\n" % [entry["time"], entry["type"], entry["context"]]
			shown += 1
	
	if dlg.size() > 0:
		text += "\n对话选择记录（共%d条）：\n" % dlg.size()
		for entry in dlg:
			text += "  - [%.1fs] 对话%s 选择%d：%s\n" % [
				entry["time"], entry["dialogue_id"], entry["choice_index"], entry["choice_text"]
			]
	
	# 统计摘要
	var s = result["stats"]
	text += "\n【战斗统计】\n"
	text += "击杀：%d | 冲锋：%d | 架点：%d | 绕后：%d\n" % [
		s["total_kills"], s["charge_count"], s["hold_position_count"], s["flank_count"]
	]
	text += "命中率：%.1f%%\n" % (
		(float(s["total_hits"]) / max(s["total_shots"], 1)) * 100.0
	)
	
	# 功能倾向解读
	text += "\n【认知功能倾向】\n"
	var sorted = result["sorted_functions"]
	for i in range(min(4, sorted.size())):
		var func_id = sorted[i]
		var score = result["final_scores"][func_id]
		text += "%d. %s (%.1f分) - %s\n" % [
			i + 1, CF.get_function_name(func_id), score,
			CF.get_function_description(func_id)
		]
	
	return text
