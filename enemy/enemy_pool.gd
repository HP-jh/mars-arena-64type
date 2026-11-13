extends Node

## 敌人对象池 - 复用敌人实例，避免频繁创建/销毁

var pool: Array[Node3D] = []
var enemy_scene: PackedScene
var initial_pool_size: int = 10

func _ready() -> void:
	# 预加载敌人场景
	enemy_scene = preload("res://enemy/enemy.tscn")
	
	# 预创建对象池
	for i in range(initial_pool_size):
		var enemy := enemy_scene.instantiate()
		enemy.set_process(false)
		enemy.set_physics_process(false)
		enemy.visible = false
		add_child(enemy)
		pool.append(enemy)

## 从对象池获取敌人实例
func acquire() -> Node3D:
	var enemy: Node3D
	
	if pool.size() > 0:
		# 从池中取出
		enemy = pool.pop_back()
	else:
		# 池为空，创建新实例
		enemy = enemy_scene.instantiate()
		add_child(enemy)
	
	# 重置状态
	enemy.visible = true
	enemy.set_process(true)
	enemy.set_physics_process(true)
	
	if enemy.has_method("reset"):
		enemy.reset()
	
	return enemy

## 归还敌人到对象池
func release(enemy: Node3D) -> void:
	if enemy == null:
		return
	
	# 禁用处理
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.visible = false
	
	# 重置位置到远处
	enemy.global_position = Vector3(0, -1000, 0)
	
	# 归还到池中
	pool.append(enemy)

## 获取池中可用数量
func get_available_count() -> int:
	return pool.size()

## 清空对象池
func clear_pool() -> void:
	for enemy in pool:
		if is_instance_valid(enemy):
			enemy.queue_free()
	pool.clear()
