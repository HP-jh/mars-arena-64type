extends Node3D

## 调试截图工具：加载主场景，等待若干帧后保存 PNG
##
## 用法:
##   godot --path . tools/capture.tscn -- --quality=medium --shot=/tmp/a.png
##   godot --path . tools/capture.tscn -- --cam=0,8,14 --look=0,1,0

@export var main_scene_path: String = "res://scenario/main.tscn"
@export var wait_seconds: float = 4.0
@export var out_path: String = "user://shot.png"

var _cam_pos := Vector3.ZERO
var _look_at := Vector3.ZERO
var _has_cam := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			out_path = a.get_slice("=", 1)
		elif a.begins_with("--cam="):
			_cam_pos = _parse_vec(a.get_slice("=", 1))
			_has_cam = true
		elif a.begins_with("--look="):
			_look_at = _parse_vec(a.get_slice("=", 1))

	var ps: PackedScene = load(main_scene_path)
	var scene := ps.instantiate()
	add_child(scene)

	await get_tree().create_timer(wait_seconds).timeout

	if _has_cam:
		var cam := Camera3D.new()
		cam.name = "DebugCam"
		add_child(cam)
		cam.global_position = _cam_pos
		cam.look_at(_look_at)
		cam.current = true

	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(out_path) if out_path.begins_with("user://") else out_path
	img.save_png(abs_path)
	print("CAPTURED: ", abs_path, " ", img.get_width(), "x", img.get_height())
	get_tree().quit()

func _parse_vec(s: String) -> Vector3:
	var p := s.split(",")
	if p.size() < 3:
		return Vector3.ZERO
	return Vector3(float(p[0]), float(p[1]), float(p[2]))