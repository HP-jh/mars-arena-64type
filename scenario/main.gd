extends Node3D

## 主场景控制器
## 管理游戏流程：开始 → 波次 → 对话 → 结算

@onready var player: CharacterBody3D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var result_screen: CanvasLayer = $ResultScreen

var game_started := false
var match_ended := false

func _ready() -> void:
	# 连接信号
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	wave_manager.dialogue_phase_started.connect(_on_dialogue_phase)
	
	if dialogue_ui.has_signal("dialogue_closed"):
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
	
	if player:
		player.player_died.connect(_on_player_died)
	
	# 启动游戏
	_start_game()

func _start_game() -> void:
	game_started = true
	match_ended = false
	
	if GameManager:
		GameManager.start_game()
	
	# 延迟启动波次，让玩家准备
	await get_tree().create_timer(2.0).timeout
	wave_manager.start_waves()

func _on_wave_started(wave_number: int) -> void:
	print("波次 %d 开始!" % wave_number)
	_update_hud()

func _on_wave_completed(wave_number: int) -> void:
	print("波次 %d 完成!" % wave_number)

func _on_dialogue_phase() -> void:
	# 进入对话阶段
	if GameManager:
		GameManager.enter_dialogue()
	
	# 获取当前对话
	var dialogue_id := DialogueManager.get_dialogue_for_wave(wave_manager.current_wave)
	if dialogue_id != "":
		DialogueManager.start_dialogue(dialogue_id)

func _on_dialogue_closed() -> void:
	# 对话结束，继续下一波
	if GameManager:
		GameManager.exit_dialogue()
	wave_manager.end_dialogue_phase()

func _on_all_waves_completed() -> void:
	print("所有波次完成!")
	_end_match(true)

func _on_player_died() -> void:
	print("玩家死亡")
	# 给一点时间让玩家看到死亡效果
	await get_tree().create_timer(1.5).timeout
	_end_match(false)

func _end_match(victory: bool) -> void:
	if match_ended:
		return
	match_ended = true
	
	if GameManager:
		GameManager.end_game(victory)
	
	# 计算人格结果
	var result := PersonalityTracker.calculate_result()
	
	# 显示结算界面
	await get_tree().create_timer(1.0).timeout
	result_screen.show_result(result)

func _update_hud() -> void:
	var info: Dictionary = wave_manager.get_wave_info()
	hud.update_wave_info(info["current_wave"], info["total_waves"], info["enemies_alive"])

func _process(_delta: float) -> void:
	# 持续更新HUD
	if game_started and not match_ended:
		_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	# ESC暂停/退出
	if event.is_action_pressed("ui_cancel"):
		if match_ended:
			return
		if GameManager:
			if GameManager.current_state == GameManager.GameState.PAUSED:
				GameManager.resume_game()
			else:
				GameManager.pause_game()
