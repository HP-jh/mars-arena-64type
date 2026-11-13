extends CanvasLayer

## HUD - 战斗界面
## 显示血量、护甲、弹药、波次、得分

var health_bar: ProgressBar
var armor_bar: ProgressBar
var health_label: Label
var armor_label: Label
var ammo_label: Label
var wave_label: Label
var score_label: Label
var weapon_label: Label
var crosshair: TextureRect
var hit_indicator: ColorRect
var kill_feed: VBoxContainer

var player_ref: CharacterBody3D = null

# 缓存上次的值，避免每帧更新文本
var _last_health: int = -1
var _last_armor: int = -1
var _last_ammo: int = -1
var _last_reserve: int = -1
var _last_weapon_name: String = ""
var _last_is_reloading: bool = false

func _ready() -> void:
	# 创建HUD节点
	_build_ui()
	# 查找玩家
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		_connect_player_signals()
	
	# 连接全局信号
	if GameManager:
		GameManager.score_changed.connect(_on_score_changed)

func _build_ui() -> void:
	# 主容器
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)
	
	# 血量条
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: 100/100"
	vbox.add_child(health_label)
	
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(200, 20)
	vbox.add_child(health_bar)
	
	# 护甲条
	armor_label = Label.new()
	armor_label.name = "ArmorLabel"
	armor_label.text = "护甲: 0/50"
	vbox.add_child(armor_label)
	
	armor_bar = ProgressBar.new()
	armor_bar.name = "ArmorBar"
	armor_bar.max_value = 50
	armor_bar.value = 0
	armor_bar.custom_minimum_size = Vector2(200, 20)
	vbox.add_child(armor_bar)
	
	# 武器信息
	weapon_label = Label.new()
	weapon_label.name = "WeaponLabel"
	weapon_label.text = "武器: 突击步枪"
	vbox.add_child(weapon_label)
	
	# 弹药
	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "弹药: 30/30 | 备用: 90"
	vbox.add_child(ammo_label)
	
	# 波次
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "波次: 0/3"
	vbox.add_child(wave_label)
	
	# 得分
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "得分: 0"
	vbox.add_child(score_label)
	
	# 准星
	crosshair = TextureRect.new()
	crosshair.name = "Crosshair"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.custom_minimum_size = Vector2(20, 20)
	crosshair.position = Vector2(-10, -10)
	add_child(crosshair)
	
	# 受击指示器
	hit_indicator = ColorRect.new()
	hit_indicator.name = "HitIndicator"
	hit_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit_indicator.color = Color(1, 0, 0, 0)
	hit_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hit_indicator)
	
	# 击杀信息
	kill_feed = VBoxContainer.new()
	kill_feed.name = "KillFeed"
	kill_feed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kill_feed.position = Vector2(-200, 20)
	add_child(kill_feed)

func _process(_delta: float) -> void:
	if not player_ref:
		return
	
	# 只在数值变化时更新文本，避免每帧字符串格式化
	var current_health := int(player_ref.health)
	var current_armor := int(player_ref.armor)
	var weapon_info: Dictionary = player_ref.get_current_weapon_info()
	var current_ammo: int = weapon_info.get("ammo", 0)
	var current_reserve: int = weapon_info.get("reserve", 0)
	var current_weapon_name: String = weapon_info.get("name", "")
	var current_is_reloading: bool = weapon_info.get("is_reloading", false)
	
	# 血量更新
	if current_health != _last_health:
		health_bar.value = current_health
		health_label.text = "HP: %d/%d" % [current_health, int(player_ref.max_health)]
		_last_health = current_health
	
	# 护甲更新
	if current_armor != _last_armor:
		armor_bar.value = current_armor
		armor_label.text = "护甲: %d/%d" % [current_armor, int(player_ref.max_armor)]
		_last_armor = current_armor
	
	# 武器信息更新
	if current_weapon_name != _last_weapon_name:
		weapon_label.text = "武器: %s" % current_weapon_name
		_last_weapon_name = current_weapon_name
	
	# 弹药更新
	if current_is_reloading != _last_is_reloading:
		if current_is_reloading:
			ammo_label.text = "弹药: 换弹中..."
		_last_is_reloading = current_is_reloading
	elif not current_is_reloading and (current_ammo != _last_ammo or current_reserve != _last_reserve):
		ammo_label.text = "弹药: %d/%d | 备用: %d" % [current_ammo, int(weapon_info.get("magazine", 0)), current_reserve]
		_last_ammo = current_ammo
		_last_reserve = current_reserve

func _connect_player_signals() -> void:
	if player_ref:
		player_ref.health_changed.connect(_on_health_changed)
		player_ref.armor_changed.connect(_on_armor_changed)
		player_ref.weapon_changed.connect(_on_weapon_changed)
		player_ref.player_died.connect(_on_player_died)
		player_ref.player_shot.connect(_on_player_shot)
		player_ref.player_hit_enemy.connect(_on_player_hit_enemy)

func _on_health_changed(new_health: float) -> void:
	health_bar.value = new_health
	health_label.text = "HP: %d/%d" % [new_health, player_ref.max_health]
	_flash_hit_indicator(Color(1, 0, 0, 0.3))

func _on_armor_changed(new_armor: float) -> void:
	armor_bar.value = new_armor
	armor_label.text = "护甲: %d/%d" % [new_armor, player_ref.max_armor]

func _on_weapon_changed(_weapon_index: int) -> void:
	pass

func _on_player_died() -> void:
	pass

func _on_player_shot() -> void:
	pass

func _on_player_hit_enemy(damage: float, is_headshot: bool) -> void:
	# 击中反馈
	_flash_hit_indicator(Color(1, 0.5, 0, 0.2))
	# 击杀信息
	var label := Label.new()
	if is_headshot:
		label.text = "爆头! -%.0f" % damage
		label.add_theme_color_override("font_color", Color.RED)
	else:
		label.text = "命中 -%.0f" % damage
	kill_feed.add_child(label)
	# 淡出
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "得分: %d" % new_score

func update_wave_info(current: int, total: int, enemies_alive: int) -> void:
	wave_label.text = "波次: %d/%d | 剩余敌人: %d" % [current, total, enemies_alive]

func _flash_hit_indicator(color: Color) -> void:
	hit_indicator.color = color
	var tween := create_tween()
	tween.tween_property(hit_indicator, "color:a", 0.0, 0.3)
