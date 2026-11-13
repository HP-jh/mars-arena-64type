extends Node

## 无线电对话管理器 - 全局Autoload
## 管理波次间隙的对话抉择节点

signal dialogue_started(dialogue_data: Dictionary)
signal dialogue_option_selected(option_index: int)
signal dialogue_completed()

const CF = preload("res://personality_64/cognitive_functions.gd")

# 对话数据库
var dialogues := {}
var current_dialogue_id: String = ""
var current_dialogue_index: int = 0
var answered_dialogues: Array = []

func _ready() -> void:
	_init_dialogues()

func _init_dialogues() -> void:
	var F = CF.Function16
	
	# 对话1：波次1后 - 战术取舍
	dialogues["wave1_post"] = {
		"id": "wave1_post",
		"title": "指挥台通讯",
		"speaker": "指挥官",
		"text": "干员，第一波敌人已清除。前方侦察显示有更强的敌军集结。你建议如何推进？",
		"options": [
			{
				"text": "立即突击，趁他们还没完全集结",
				"weights": {F.SE_EXPLORATORY: 8.0, F.NE_DIVERGENT: 4.0, F.TE_EXECUTIVE: 3.0}
			},
			{
				"text": "先侦察敌情，制定详细计划再行动",
				"weights": {F.NI_PROPHETIC: 7.0, F.TI_ANALYTICAL: 5.0, F.SI_RECOLLECTIVE: 3.0}
			},
			{
				"text": "呼叫支援，等待增援到达",
				"weights": {F.FE_HARMONIZING: 6.0, F.SI_HOMEOSTATIC: 4.0, F.TE_EMPIRICAL: 3.0}
			},
			{
				"text": "绕到侧翼，寻找薄弱点突破",
				"weights": {F.NE_INTEGRATIVE: 6.0, F.NE_DIVERGENT: 5.0, F.TI_ANALYTICAL: 4.0}
			}
		]
	}
	
	# 对话2：波次2后 - 资源分配
	dialogues["wave2_post"] = {
		"id": "wave2_post",
		"title": "补给频道",
		"speaker": "后勤官",
		"text": "干员，我们发现了一批补给。但队友受伤需要医疗用品，弹药也需要补充。资源有限，你怎么分配？",
		"options": [
			{
				"text": "优先补充弹药，火力最重要",
				"weights": {F.TE_EXECUTIVE: 7.0, F.SE_EXPLORATORY: 4.0, F.TE_EMPIRICAL: 3.0}
			},
			{
				"text": "先治疗队友，团队生存最重要",
				"weights": {F.FE_HARMONIZING: 8.0, F.FI_AUTHENTICATING: 4.0, F.FE_INFLUENCING: 3.0}
			},
			{
				"text": "平均分配，保持平衡",
				"weights": {F.SI_HOMEOSTATIC: 6.0, F.TE_EMPIRICAL: 5.0, F.FE_HARMONIZING: 3.0}
			},
			{
				"text": "保留部分资源作为储备，以防意外",
				"weights": {F.NI_PROPHETIC: 6.0, F.SI_RECOLLECTIVE: 5.0, F.TI_ANALYTICAL: 4.0}
			}
		]
	}
	
	# 对话3：最终波次前 - 信念抉择
	dialogues["final_wave_pre"] = {
		"id": "final_wave_pre",
		"title": "加密频道",
		"speaker": "神秘联络人",
		"text": "干员，最后的情报：敌方首领在核心区域。但你的队友报告发现平民被困。时间只够做一个选择。",
		"options": [
			{
				"text": "直取敌方首领，完成任务优先",
				"weights": {F.TE_EXECUTIVE: 8.0, F.NI_PROPHETIC: 5.0, F.FI_INDIVIDUATING: -3.0}
			},
			{
				"text": "先救平民，人命关天",
				"weights": {F.FI_AUTHENTICATING: 9.0, F.FE_HARMONIZING: 6.0, F.FE_INFLUENCING: 3.0}
			},
			{
				"text": "分兵两路，同时执行两个任务",
				"weights": {F.NE_DIVERGENT: 7.0, F.NE_INTEGRATIVE: 5.0, F.TE_EXECUTIVE: 3.0}
			},
			{
				"text": "分析局势，寻找两全其美的方案",
				"weights": {F.TI_ANALYTICAL: 7.0, F.NI_SYNTHESIZING: 6.0, F.NE_INTEGRATIVE: 4.0}
			}
		]
	}

func start_dialogue(dialogue_id: String) -> void:
	if not dialogues.has(dialogue_id):
		push_warning("Dialogue not found: " + dialogue_id)
		return
	
	current_dialogue_id = dialogue_id
	current_dialogue_index = 0
	var dialogue: Dictionary = dialogues[dialogue_id]
	dialogue_started.emit(dialogue)

func select_option(option_index: int) -> void:
	if not dialogues.has(current_dialogue_id):
		return
	
	var dialogue: Dictionary = dialogues[current_dialogue_id]
	if option_index < 0 or option_index >= dialogue["options"].size():
		return
	
	var option: Dictionary = dialogue["options"][option_index]
	
	# 记录到人格系统
	if PersonalityTracker:
		PersonalityTracker.record_dialogue_choice(
			current_dialogue_id,
			option_index,
			option["weights"],
			option["text"]
		)
	
	answered_dialogues.append({
		"dialogue_id": current_dialogue_id,
		"option_index": option_index,
		"option_text": option["text"]
	})
	
	dialogue_option_selected.emit(option_index)
	dialogue_completed.emit()

func get_current_dialogue() -> Dictionary:
	if dialogues.has(current_dialogue_id):
		return dialogues[current_dialogue_id]
	return {}

func get_dialogue_for_wave(wave_number: int) -> String:
	match wave_number:
		1: return "wave1_post"
		2: return "wave2_post"
		3: return "final_wave_pre"
		_: return ""

func get_answered_dialogues() -> Array:
	return answered_dialogues

func reset() -> void:
	current_dialogue_id = ""
	current_dialogue_index = 0
	answered_dialogues.clear()
