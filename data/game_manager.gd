extends Node

## 游戏管理器 - 全局Autoload单例
## 管理游戏状态、得分、流程控制

signal game_started()
signal game_over(victory: bool)
signal score_changed(new_score: int)
signal state_changed(new_state: String)

enum GameState {
	MENU,
	PLAYING,
	DIALOGUE,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var score: int = 0
var kills: int = 0
var match_time: float = 0.0
var match_start_time: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		match_time = (Time.get_ticks_msec() / 1000.0) - match_start_time

func start_game() -> void:
	current_state = GameState.PLAYING
	score = 0
	kills = 0
	match_start_time = Time.get_ticks_msec() / 1000.0
	game_started.emit()
	state_changed.emit("playing")

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func add_kill() -> void:
	kills += 1
	add_score(100)

func enter_dialogue() -> void:
	current_state = GameState.DIALOGUE
	state_changed.emit("dialogue")

func exit_dialogue() -> void:
	current_state = GameState.PLAYING
	state_changed.emit("playing")

func end_game(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	game_over.emit(victory)
	state_changed.emit("game_over")

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		state_changed.emit("paused")

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		state_changed.emit("playing")

func get_game_info() -> Dictionary:
	return {
		"state": current_state,
		"score": score,
		"kills": kills,
		"match_time": match_time
	}

func reset() -> void:
	current_state = GameState.MENU
	score = 0
	kills = 0
	match_time = 0.0
