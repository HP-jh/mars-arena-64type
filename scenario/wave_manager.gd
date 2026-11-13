extends Node

## 波次管理器 - 控制敌人波次生成

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal dialogue_phase_started()

@export var enemy_scene: PackedScene
@export var spawn_points: Array[NodePath] = []

var current_wave: int = 0
var total_waves: int = 3
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_dialogue_phase: bool = false

# 对象池引用
var enemy_pool: Node = null

# 波次配置
var wave_configs := [
	{"enemy_count": 5, "enemy_health_mult": 1.0, "enemy_damage_mult": 1.0},
	{"enemy_count": 8, "enemy_health_mult": 1.3, "enemy_damage_mult": 1.2},
	{"enemy_count": 12, "enemy_health_mult": 1.6, "enemy_damage_mult": 1.5}
]

func _ready() -> void:
	# 获取生成点
	if spawn_points.is_empty():
		_find_spawn_points()
	
	# 初始化对象池
	_init_enemy_pool()

func _init_enemy_pool() -> void:
	# 创建对象池节点
	enemy_pool = preload("res://enemy/enemy_pool.gd").new()
	enemy_pool.enemy_scene = enemy_scene
	enemy_pool.initial_pool_size = 10
	add_child(enemy_pool)

func _find_spawn_points() -> void:
	var spawns := get_tree().get_nodes_in_group("enemy_spawn_points")
	for spawn in spawns:
		spawn_points.append(spawn.get_path())

func start_waves() -> void:
	current_wave = 0
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= total_waves:
		all_waves_completed.emit()
		return
	
	current_wave += 1
	is_wave_active = true
	
	var config: Dictionary = wave_configs[min(current_wave - 1, wave_configs.size() - 1)]
	_spawn_wave_enemies(config)
	
	wave_started.emit(current_wave)

func _spawn_wave_enemies(config: Dictionary) -> void:
	var count: int = config["enemy_count"]
	enemies_alive = count
	
	for i in range(count):
		var spawn_pos := _get_spawn_position(i)
		
		# 使用对象池获取敌人实例
		var enemy: Node3D = enemy_pool.acquire()
		enemy.global_position = spawn_pos
		
		# 应用波次加成
		if enemy.has_method("set_health_multiplier"):
			enemy.set_health_multiplier(config["enemy_health_mult"])
		else:
			enemy.max_health *= config["enemy_health_mult"]
			enemy.health = enemy.max_health
		
		enemy.damage *= config["enemy_damage_mult"]
		enemy.score_value = 100 * current_wave
		
		# 连接信号
		if not enemy.enemy_died.is_connected(_on_enemy_died):
			enemy.enemy_died.connect(_on_enemy_died)
		
		# 设置玩家引用
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			enemy.set_player(players[0])

func _get_spawn_position(index: int) -> Vector3:
	if spawn_points.is_empty():
		# 默认生成位置
		var angle := index * PI * 2.0 / 8.0
		return Vector3(cos(angle) * 15.0, 0, sin(angle) * 15.0)
	
	var spawn_node := get_node(spawn_points[index % spawn_points.size()])
	return spawn_node.global_position

func _on_enemy_died(_enemy: Node, _score: int) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and is_wave_active:
		_complete_wave()

func _complete_wave() -> void:
	is_wave_active = false
	wave_completed.emit(current_wave)
	
	# 检查是否还有下一波
	if current_wave >= total_waves:
		all_waves_completed.emit()
	else:
		# 进入对话阶段
		_start_dialogue_phase()

func _start_dialogue_phase() -> void:
	is_dialogue_phase = true
	dialogue_phase_started.emit()

func end_dialogue_phase() -> void:
	is_dialogue_phase = false
	_start_next_wave()

func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_wave,
		"total_waves": total_waves,
		"enemies_alive": enemies_alive,
		"is_active": is_wave_active
	}
