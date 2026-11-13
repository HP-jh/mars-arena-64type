extends Resource
class_name WeaponResource

## 武器资源配置

@export var weapon_name: String = "武器"
@export var damage: float = 20.0
@export var fire_rate: float = 0.1  # 射击间隔（秒）
@export var magazine_size: int = 30
@export var current_ammo: int = 30
@export var reserve_ammo: int = 90
@export var reload_time: float = 2.0
@export var recoil_amount: float = 0.02
@export var is_automatic: bool = true
@export var range: float = 100.0
@export var spread: float = 0.01  # 散射
