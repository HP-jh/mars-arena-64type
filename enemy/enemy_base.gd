extends CharacterBody3D

## 敌人AI基础类
## 状态机：巡逻-追击-攻击-受击-死亡

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT,
	DEAD
}

@export var enemy_name: String = "敌人"
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 3.0
@export var detection_range: float = 30.0
@export var score_value: int = 100

# 状态
var current_state: State = State.PATROL
var player_ref: CharacterBody3D = null
var is_dead: bool = false
var can_attack: bool = true
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# 性能优化：视线检测节流
var _last_sight_check: float = 0.0
var _sight_check_interval: float = 0.3  # 每0.3秒检测一次
var _can_see_player_cached: bool = false

# 缓存材质避免重复创建
var _flash_material: StandardMaterial3D = null
var _original_material: Material = null

# 节点引用
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var head: Node3D = $Head
@onready var raycast: RayCast3D = $RayCast3D
@onready var detection_area: Area3D = $DetectionArea

# 信号
signal enemy_died(enemy: Node, score: int)
signal enemy_damaged(enemy: Node, damage: float)

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	
	# 设置导航代理
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
	
	# 初始巡逻点
	_setup_patrol_points()

## 重置敌人状态（对象池复用时调用）
func reset() -> void:
	health = max_health
	is_dead = false
	current_state = State.PATROL
	current_patrol_index = 0
	can_attack = true
	_last_sight_check = 0.0
	_can_see_player_cached = false
	
	# 重置旋转
	rotation = Vector3.ZERO
	
	# 重新设置巡逻点
	_setup_patrol_points()

func _setup_patrol_points() -> void:
	# 在敌人周围生成随机巡逻点
	var origin := global_position
	for i in range(4):
		var angle := i * PI * 0.5
		var point := origin + Vector3(cos(angle) * 5.0, 0, sin(angle) * 5.0)
		patrol_points.append(point)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 状态机
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HIT:
			pass  # 受击状态由计时器控制
	
	move_and_slide()

func _state_idle(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	# 检测玩家
	if _can_see_player():
		_change_state(State.CHASE)

func _state_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(State.IDLE)
		return
	
	# 检测玩家
	if _can_see_player():
		_change_state(State.CHASE)
		return
	
	# 移动到巡逻点
	var target := patrol_points[current_patrol_index]
	nav_agent.target_position = target
	
	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return
	
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed * 0.5
	velocity.z = direction.z * move_speed * 0.5
	
	# 朝向移动方向
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _state_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_find_player()
		if not player_ref:
			_change_state(State.PATROL)
			return
	
	var distance := global_position.distance_to(player_ref.global_position)
	
	# 超出追击范围
	if distance > detection_range * 1.5:
		_change_state(State.PATROL)
		return
	
	# 在攻击范围内且可以看到玩家
	if distance <= attack_range and _can_see_player():
		_change_state(State.ATTACK)
		return
	
	# 移动到玩家位置
	nav_agent.target_position = player_ref.global_position
	
	if nav_agent.is_navigation_finished():
		return
	
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# 朝向玩家
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _state_attack(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.CHASE)
		return
	
	var distance := global_position.distance_to(player_ref.global_position)
	
	# 玩家离开攻击范围
	if distance > attack_range * 1.2:
		_change_state(State.CHASE)
		return
	
	velocity.x = 0
	velocity.z = 0
	
	# 朝向玩家
	var direction := (player_ref.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)
	
	# 攻击
	if can_attack and _can_see_player():
		_perform_attack()

func _state_hit(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	# 受击硬直后恢复
	await get_tree().create_timer(0.3).timeout
	if health > 0:
		_change_state(State.CHASE)

func _can_see_player() -> bool:
	if not player_ref or not is_instance_valid(player_ref):
		return false
	
	var distance := global_position.distance_to(player_ref.global_position)
	if distance > detection_range:
		return false
	
	# 节流检查：避免每帧执行射线检测
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_sight_check < _sight_check_interval:
		return _can_see_player_cached
	
	_last_sight_check = current_time
	
	# 射线检测视线
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		head.global_position,
		player_ref.global_position + Vector3(0, 1, 0),
		1  # 环境层
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	
	# 缓存结果
	_can_see_player_cached = result.is_empty() or result["collider"].is_in_group("player")
	return _can_see_player_cached

func _perform_attack() -> void:
	can_attack = false
	
	# 射击效果
	_shoot_at_player()
	
	# 对玩家造成伤害
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)
	
	# 攻击冷却
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _shoot_at_player() -> void:
	# 简单的射击视觉效果
	# TODO: 添加子弹轨迹效果
	pass

func take_damage(amount: float, hit_point: Vector3 = Vector3.ZERO, hit_normal: Vector3 = Vector3.UP) -> void:
	if is_dead:
		return
	
	health -= amount
	enemy_damaged.emit(self, amount)
	
	# 受击效果
	_flash_hit_effect(hit_point, hit_normal)
	
	if health <= 0:
		_die()
	else:
		_change_state(State.HIT)
		# 被攻击后追击玩家
		if not player_ref:
			_find_player()

func _flash_hit_effect(hit_point: Vector3, _normal: Vector3) -> void:
	# 受击闪烁效果 - 使用缓存材质避免重复创建
	var mesh := $EnemyBody if has_node("EnemyBody") else null
	if mesh and mesh is MeshInstance3D:
		# 首次调用时缓存原始材质和创建闪烁材质
		if _flash_material == null:
			_original_material = mesh.get_surface_override_material(0)
			_flash_material = StandardMaterial3D.new()
			_flash_material.albedo_color = Color.RED
		
		mesh.set_surface_override_material(0, _flash_material)
		await get_tree().create_timer(0.1).timeout
		mesh.set_surface_override_material(0, _original_material)

func _die() -> void:
	is_dead = true
	current_state = State.DEAD
	enemy_died.emit(self, score_value)
	
	# 通知人格系统击杀
	if PersonalityTracker:
		PersonalityTracker.update_stat("total_kills")
		# 根据击杀情况记录行为
		var BW = preload("res://personality_64/behavior_weights.gd")
		var weights = BW.get_weights_for_event(BW.EVENT_HIGH_PRIORITY_KILL)
		PersonalityTracker.record_battle_event("kill", weights, "击杀敌人: " + enemy_name)
	
	# 死亡效果
	_death_effect()
	
	# 延迟后归还到对象池（而不是销毁）
	await get_tree().create_timer(1.0).timeout
	
	# 查找对象池并归还
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_node("EnemyPool"):
		wave_manager.get_node("EnemyPool").release(self)
	else:
		# 如果找不到对象池，直接销毁
		queue_free()

func _death_effect() -> void:
	# 简单的倒塌效果
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:x", 90.0, 0.3)
	tween.parallel().tween_property(self, "position:y", position.y - 0.5, 0.3)

func _change_state(new_state: State) -> void:
	current_state = new_state

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func set_player(player: CharacterBody3D) -> void:
	player_ref = player
