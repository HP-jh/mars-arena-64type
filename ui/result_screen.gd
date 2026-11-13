extends CanvasLayer

## 结算界面 - 16功能雷达图 + 64型人格卡片

const CF = preload("res://personality_64/cognitive_functions.gd")

var panel: PanelContainer
var radar_chart: Control
var type_label: Label
var functions_label: Label
var keywords_label: Label
var interpretation_label: Label
var stats_label: Label
var restart_button: Button
var dialogue_history_label: Label

var result_data: Dictionary = {}

func _ready() -> void:
	_build_ui()
	restart_button.pressed.connect(_on_restart)
	visible = false

func _build_ui() -> void:
	# 背景遮罩
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	add_child(bg)
	
	# 主面板
	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -450
	panel.offset_top = -350
	panel.offset_right = 450
	panel.offset_bottom = 350
	add_child(panel)
	
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(860, 660)
	panel.add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# 标题
	var title := Label.new()
	title.text = "【对局结算 - 荣格斯二代16功能64型人格报告】"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	# 雷达图
	radar_chart = RadarChart.new()
	radar_chart.name = "RadarChart"
	radar_chart.custom_minimum_size = Vector2(500, 400)
	vbox.add_child(radar_chart)
	
	# 人格类型
	type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(type_label)
	
	# 功能栈
	functions_label = Label.new()
	functions_label.name = "FunctionsLabel"
	functions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(functions_label)
	
	# 关键词
	keywords_label = Label.new()
	keywords_label.name = "KeywordsLabel"
	keywords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keywords_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(keywords_label)
	
	# 分隔
	vbox.add_child(HSeparator.new())
	
	# 解读
	var interp_title := Label.new()
	interp_title.text = "【本局个性化解读】"
	interp_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(interp_title)
	
	interpretation_label = Label.new()
	interpretation_label.name = "InterpretationLabel"
	interpretation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(interpretation_label)
	
	# 分隔
	vbox.add_child(HSeparator.new())
	
	# 战斗统计
	var stats_title := Label.new()
	stats_title.text = "【战斗统计摘要】"
	stats_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(stats_title)
	
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	vbox.add_child(stats_label)
	
	# 对话记录
	vbox.add_child(HSeparator.new())
	var dlg_title := Label.new()
	dlg_title.text = "【关键对话选择记录】"
	dlg_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(dlg_title)
	
	dialogue_history_label = Label.new()
	dialogue_history_label.name = "DialogueHistoryLabel"
	dialogue_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(dialogue_history_label)
	
	# 重新开始按钮
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开局"
	restart_button.custom_minimum_size = Vector2(200, 40)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(restart_button)

## 显示结算结果
func show_result(result: Dictionary) -> void:
	result_data = result
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 雷达图数据
	var scores_array := []
	var labels_array := []
	for func_id in CF.FUNCTION_NAMES.keys():
		scores_array.append(result["final_scores"].get(func_id, 0.0))
		labels_array.append(CF.get_function_name(func_id))
	radar_chart.set_data(scores_array, labels_array)
	
	# 人格类型
	type_label.text = "你的人格类型：%s" % result["type_code"]
	
	# 功能栈
	functions_label.text = "主导：%s | 辅助：%s | 第三：%s | 第四：%s" % [
		CF.get_function_name(result["dominant"]),
		CF.get_function_name(result["auxiliary"]),
		CF.get_function_name(result["tertiary"]),
		CF.get_function_name(result["inferior"])
	]
	
	# 关键词
	var keywords: Array = result["type_keywords"]
	keywords_label.text = "行为关键词：" + ", ".join(keywords)
	
	# 个性化解读
	interpretation_label.text = PersonalityTracker.generate_interpretation(result)
	
	# 统计
	var s = result["stats"]
	stats_label.text = "总击杀：%d | 冲锋：%d | 架点：%d | 绕后：%d | 后撤：%d\n" % [
		s["total_kills"], s["charge_count"], s["hold_position_count"],
		s["flank_count"], s["retreat_count"]
	]
	stats_label.text += "爆头：%d | 换弹次数（武器切换）：%d | 对话选择：%d\n" % [
		s["headshot_count"], s["weapon_switch_count"], s["dialogues_answered"]
	]
	stats_label.text += "命中率：%.1f%% | 总伤害输出：%.0f | 总承受伤害：%.0f" % [
		(float(s["total_hits"]) / max(s["total_shots"], 1)) * 100.0,
		s["total_damage_dealt"], s["total_damage_taken"]
	]
	
	# 对话历史
	var dlg_text := ""
	for entry in result["dialogue_log"]:
		dlg_text += "[%s] 对话%s - 选择%d: %s\n" % [
			_format_time(entry["time"]), entry["dialogue_id"],
			entry["choice_index"], entry["choice_text"]
		]
	dialogue_history_label.text = dlg_text if dlg_text else "（本局未进行对话选择）"

func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%02d:%02d" % [m, s]

func _on_restart() -> void:
	# 重置所有状态
	PersonalityTracker.reset()
	GameManager.reset()
	DialogueManager.reset()
	visible = false
	get_tree().reload_current_scene()


## 雷达图自定义绘制控件
class RadarChart extends Control:
	var data: Array = []
	var labels: Array = []
	var max_value: float = 100.0
	
	func set_data(new_data: Array, new_labels: Array) -> void:
		data = new_data
		labels = new_labels
		queue_redraw()
	
	func _draw() -> void:
		if data.is_empty():
			return
		
		var center: Vector2 = size / 2.0
		var radius: float = min(size.x, size.y) * 0.4
		var count: int = data.size()
		if count < 3:
			return
		
		# 绘制背景网格（5层）
		for level in range(1, 6):
			var r: float = radius * level / 5.0
			var points: PackedVector2Array = PackedVector2Array()
			for i in range(count):
				var angle: float = (float(i) / count) * TAU - PI / 2
				var p: Vector2 = center + Vector2(cos(angle), sin(angle)) * r
				points.append(p)
			points.append(points[0])
			draw_polyline(points, Color(0.3, 0.3, 0.4, 0.5), 1.0)
		
		# 绘制轴线
		for i in range(count):
			var angle: float = (float(i) / count) * TAU - PI / 2
			var end: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
			draw_line(center, end, Color(0.4, 0.4, 0.5, 0.5), 1.0)
		
		# 绘制数据多边形
		var data_points: PackedVector2Array = PackedVector2Array()
		for i in range(count):
			var angle: float = (float(i) / count) * TAU - PI / 2
			var value: float = clampf(data[i] / max_value, 0.0, 1.0)
			var p: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * value
			data_points.append(p)
		
		# 填充
		draw_colored_polygon(data_points, Color(0.2, 0.6, 1.0, 0.3))
		# 边框
		var outline: PackedVector2Array = data_points.duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color(0.3, 0.8, 1.0, 1.0), 2.0)
		
		# 绘制数据点
		for p in data_points:
			draw_circle(p, 4.0, Color(1.0, 0.8, 0.2, 1.0))
		
		# 绘制标签
		for i in range(count):
			var angle: float = (float(i) / count) * TAU - PI / 2
			var label_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (radius + 25)
			var text: String = labels[i] if i < labels.size() else ""
			var font: Font = ThemeDB.fallback_font
			var font_size: int = 12
			var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var draw_pos: Vector2 = label_pos - text_size / 2.0
			draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
