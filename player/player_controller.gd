extends CharacterBody3D

## 玩家FPS控制器
## WASD移动、鼠标视角、Shift冲刺、空格跳跃

const WeaponRes = preload("res://weapon/weapon_resource.gd")

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var deceleration: float = 8.0

@export_group("Combat")
@export var max_health: float = 100.0
@export var max_armor: float = 50.0
@export var health: float = 100.0
@export var armor: float = 0.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var camera_tilt_amount: float = 0.5

# 节点引用
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/WeaponHolder/MuzzleFlash

# 状态
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting: bool = false
var current_weapon_index: int = 0
var weapons: Array = []
var is_reloading: bool = false
var can_shoot: bool = true
var is_dead: bool = false

# 性能优化：移动事件节流
var _last_move_event_time: float = 0.0
var _move_event_interval: float = 0.5  # 每0.5秒最多记录一次移动事件

# 信号
signal health_changed(new_health: float)
signal armor_changed(new_armor: float)
signal weapon_changed(weapon_index: int)
signal player_died()
signal player_shot()
signal player_hit_enemy(damage: float, is_headshot: bool)
signal player_moved(direction: Vector3, is_sprinting: bool)
signal player_changed_position()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_init_weapons()
	health = max_health
	armor = 0.0
	# 通知人格系统游戏开始
	if PersonalityTracker:
		PersonalityTracker.start_match()

func _init_weapons() -> void:
	# 创建武器资源
	var rifle: WeaponRes = WeaponRes.new()
	rifle.weapon_name = "突击步枪"
	rifle.damage = 25.0
	rifle.fire_rate = 0.1
	rifle.magazine_size = 30
	rifle.current_ammo = 30
	rifle.reserve_ammo = 90
	rifle.reload_time = 2.0
	rifle.recoil_amount = 0.02
	rifle.is_automatic = true
	
	var pistol: WeaponRes = WeaponRes.new()
	pistol.weapon_name = "手枪"
	pistol.damage = 35.0
	pistol.fire_rate = 0.3
	pistol.magazine_size = 12
	pistol.current_ammo = 12
	pistol.reserve_ammo = 48
	pistol.reload_time = 1.5
	pistol.recoil_amount = 0.03
	pistol.is_automatic = false
	
	weapons = [rifle, pistol]

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	
	# 鼠标视角控制
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# 射击
	if event.is_action_pressed("shoot"):
		_start_shoot()
	elif event.is_action_released("shoot"):
		can_shoot = true
	
	# 换弹
	if event.is_action_pressed("reload"):
		_start_reload()
	
	# 切换武器
	if event.is_action_pressed("switch_weapon"):
		_switch_weapon()
	
	# 冲刺
	if event.is_action_pressed("sprint"):
		is_sprinting = true
	elif event.is_action_released("sprint"):
		is_sprinting = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# 移动方向
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 通知人格系统移动行为（节流：每0.5秒最多一次）
	if direction.length() > 0.1:
		var current_time := Time.get_ticks_msec() / 1000.0
		if current_time - _last_move_event_time >= _move_event_interval:
			player_moved.emit(direction, is_sprinting)
			_last_move_event_time = current_time
	
	# 速度
	var target_speed := sprint_speed if is_sprinting else walk_speed
	if direction:
		velocity.x = lerp(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, deceleration * delta)
	
	move_and_slide()

func _start_shoot() -> void:
	if not can_shoot or is_reloading:
		return
	var weapon: WeaponRes = _get_current_weapon()
	if not weapon:
		return
	if weapon.current_ammo <= 0:
		_start_reload()
		return
	
	_shoot()
	
	if weapon.is_automatic:
		can_shoot = false
		await get_tree().create_timer(weapon.fire_rate).timeout
		can_shoot = true
		if Input.is_action_pressed("shoot"):
			_start_shoot()

func _shoot() -> void:
	var weapon: WeaponRes = _get_current_weapon()
	if not weapon:
		return
	
	weapon.current_ammo -= 1
	player_shot.emit()
	
	# 更新人格统计
	if PersonalityTracker:
		PersonalityTracker.update_stat("total_shots")
	
	# 枪口闪光效果
	if muzzle_flash:
		muzzle_flash.visible = true
		await get_tree().create_timer(0.05).timeout
		muzzle_flash.visible = false
	
	# 射线检测
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var hit_point: Vector3 = raycast.get_collision_point()
		var hit_normal: Vector3 = raycast.get_collision_normal()
		
		if PersonalityTracker:
			PersonalityTracker.update_stat("total_hits")
		
		# 检查是否击中敌人
		if collider.is_in_group("enemies"):
			var is_headshot: bool = _check_headshot(collider, hit_point)
			var damage: float = weapon.damage * (3.0 if is_headshot else 1.0)
			
			if collider.has_method("take_damage"):
				collider.take_damage(damage, hit_point, hit_normal)
			
			player_hit_enemy.emit(damage, is_headshot)
			
			if PersonalityTracker:
				PersonalityTracker.update_stat("total_damage_dealt", damage)
				if is_headshot:
					PersonalityTracker.update_stat("headshot_count")
					# 记录爆头行为 - 精确型功能加分
					var BW = preload("res://personality_64/behavior_weights.gd")
					var weights: Dictionary = BW.get_weights_for_event(BW.EVENT_HEADSHOT)
					PersonalityTracker.record_battle_event("headshot", weights, "精准爆头击杀")
	
	# 后坐力
	_apply_recoil(weapon.recoil_amount)

func _check_headshot(collider: Node, hit_point: Vector3) -> bool:
	# 简单判断：击中点在敌人上半部分视为爆头
	if collider.has_node("Head"):
		var head_pos: Vector3 = collider.get_node("Head").global_position
		return hit_point.distance_to(head_pos) < 0.3
	return hit_point.y > collider.global_position.y + 0.5

func _apply_recoil(amount: float) -> void:
	head.rotate_x(amount * randf_range(0.5, 1.0))
	rotate_y(randf_range(-amount, amount) * 0.5)

func _start_reload() -> void:
	if is_reloading:
		return
	var weapon: WeaponRes = _get_current_weapon()
	if not weapon:
		return
	if weapon.current_ammo >= weapon.magazine_size:
		return
	if weapon.reserve_ammo <= 0:
		return
	
	is_reloading = true
	await get_tree().create_timer(weapon.reload_time).timeout
	
	var needed: int = weapon.magazine_size - weapon.current_ammo
	var available: int = min(needed, weapon.reserve_ammo)
	weapon.current_ammo += available
	weapon.reserve_ammo -= available
	is_reloading = false

func _switch_weapon() -> void:
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	weapon_changed.emit(current_weapon_index)
	
	if PersonalityTracker:
		PersonalityTracker.update_stat("weapon_switch_count")
		var BW = preload("res://personality_64/behavior_weights.gd")
		var weights: Dictionary = BW.get_weights_for_event(BW.EVENT_WEAPON_SWITCH)
		PersonalityTracker.record_battle_event("weapon_switch", weights, "切换武器")

func _get_current_weapon() -> WeaponRes:
	if weapons.size() > current_weapon_index:
		return weapons[current_weapon_index]
	return null

func take_damage(amount: float) -> void:
	if is_dead:
		return
	
	# 护甲吸收
	if armor > 0:
		var armor_absorb: float = min(armor, amount * 0.6)
		armor -= armor_absorb
		amount -= armor_absorb
		armor_changed.emit(armor)
	
	health -= amount
	health_changed.emit(health)
	
	if PersonalityTracker:
		PersonalityTracker.update_stat("total_damage_taken", amount)
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	player_died.emit()
	# 死亡后可以选择重新开始
	await get_tree().create_timer(2.0).timeout
	restart_match()

func restart_match() -> void:
	health = max_health
	armor = 0.0
	is_dead = false
	health_changed.emit(health)
	armor_changed.emit(armor)
	# 重置武器弹药
	for w in weapons:
		w.current_ammo = w.magazine_size
		w.reserve_ammo = w.magazine_size * 3
	# 重置人格追踪器
	if PersonalityTracker:
		PersonalityTracker.reset()
		PersonalityTracker.start_match()
	# 重新加载场景
	get_tree().reload_current_scene()

func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health)

func add_armor(amount: float) -> void:
	armor = min(armor + amount, max_armor)
	armor_changed.emit(armor)

func get_current_weapon_info() -> Dictionary:
	var weapon: WeaponRes = _get_current_weapon()
	if weapon:
		return {
			"name": weapon.weapon_name,
			"ammo": weapon.current_ammo,
			"magazine": weapon.magazine_size,
			"reserve": weapon.reserve_ammo,
			"is_reloading": is_reloading
		}
	return {}
