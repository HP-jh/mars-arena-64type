extends CanvasLayer

## 无线电对话UI - 波次间隙弹出

var panel: PanelContainer
var title_label: Label
var speaker_label: Label
var text_label: Label
var options_container: VBoxContainer
var hint_label: Label

var current_dialogue: Dictionary = {}
var option_buttons: Array = []

signal dialogue_closed()

func _ready() -> void:
	_build_ui()
	visible = false
	# 连接对话管理器信号
	if DialogueManager:
		DialogueManager.dialogue_started.connect(_on_dialogue_started)
		DialogueManager.dialogue_completed.connect(_on_dialogue_completed)

func _build_ui() -> void:
	# 背景遮罩
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	add_child(bg)
	
	panel = PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -200
	panel.offset_right = 350
	panel.offset_bottom = 200
	add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	# 标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# 说话者
	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(speaker_label)
	
	# 对话文本
	text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text_label)
	
	vbox.add_child(HSeparator.new())
	
	# 选项容器
	options_container = VBoxContainer.new()
	options_container.name = "OptionsContainer"
	vbox.add_child(options_container)
	
	# 提示
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "你的选择将影响人格评价（占40%权重）"
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	hint_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint_label)

func show_dialogue(dialogue_data: Dictionary) -> void:
	current_dialogue = dialogue_data
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	title_label.text = dialogue_data.get("title", "无线电通讯")
	speaker_label.text = "【%s】" % dialogue_data.get("speaker", "未知")
	text_label.text = dialogue_data.get("text", "")
	
	# 清空旧选项
	for child in options_container.get_children():
		child.queue_free()
	option_buttons.clear()
	
	# 创建选项按钮
	var options: Array = dialogue_data.get("options", [])
	for i in range(options.size()):
		var option = options[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, option["text"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)
		option_buttons.append(btn)
	
	# 高亮人格倾向选项（可选反馈）
	_highlight_tendency(options)

func _highlight_tendency(options: Array) -> void:
	# 根据当前人格分数，轻微高亮与玩家倾向一致的选项
	var scores := PersonalityTracker.final_scores
	if scores.is_empty():
		return
	
	# 找出当前最高功能
	var max_func := -1
	var max_score := 0.0
	for func_id in scores:
		if scores[func_id] > max_score:
			max_score = scores[func_id]
			max_func = func_id
	
	if max_func < 0:
		return
	
	# 检查每个选项是否包含最高功能的权重
	for i in range(options.size()):
		var weights: Dictionary = options[i].get("weights", {})
		if weights.has(max_func) and weights[max_func] > 5.0:
			if i < option_buttons.size():
				option_buttons[i].add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
				option_buttons[i].text += " [倾向]"

func _on_option_pressed(index: int) -> void:
	if DialogueManager:
		DialogueManager.select_option(index)

func _on_dialogue_started(dialogue_data: Dictionary) -> void:
	show_dialogue(dialogue_data)

func _on_dialogue_completed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dialogue_closed.emit()
