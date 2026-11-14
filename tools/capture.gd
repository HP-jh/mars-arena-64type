extends Node3D

## 调试截图工具：加载主场景，等待若干帧后保存 PNG

@export var main_scene_path: String = "res://scenario/main.tscn"
@export var wait_seconds: float = 4.0
@export var out_path: String = "user://shot.png"

func _ready() -> void:
	var ps: PackedScene = load(main_scene_path)
	var scene := ps.instantiate()
	add_child(scene)
	await get_tree().create_timer(wait_seconds).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(out_path)
	img.save_png(abs_path)
	print("CAPTURED: ", abs_path, " ", img.get_width(), "x", img.get_height())
	get_tree().quit()
