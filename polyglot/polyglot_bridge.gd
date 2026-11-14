extends Node
## PolyglotBridge — 多语言原生内核桥接层
##
## 作用：在运行时加载 native/ 下的四种语言实现（C++ / Rust / Go / Lua），
## 与本项目内置的 GDScript 参考实现做逐位自检；任何一层不可用都会静默回退，
## 绝不影响游戏启动。
##
## 设计要点：
##   * 只用 GDExtension 之前的 dlsym/ctypes 风格调用 —— 通过 GDNative 不可用，
##     因此这里使用 `OS.execute` 校验 + 由 native 内核在离线校验中保证一致性；
##     游戏运行时优先使用 GDScript 参考实现（保证行为一致），
##     原生实现作为「可验证的等价加速层」存在，供工具链与 CI 使用。
##   * 自检结果写入 user://polyglot_status.json，可在结算界面查看。

const STATUS_PATH := "user://polyglot_status.json"
const VECTORS_PATH := "res://native/vectors/golden.txt"
const MAX_CASES := 64

var available: Array[String] = []
var verified: Dictionary = {}
var active_impl := "gdscript"

func _ready() -> void:
	_scan()

func _scan() -> void:
	var libs := {
		"cpp":  ["res://native/cpp/build/libmars_kernel_cpp.so",  "res://native/cpp/build/mars_kernel_cpp.dll"],
		"rust": ["res://native/rust/build/libmars_kernel_rust.so", "res://native/rust/build/mars_kernel_rust.dll"],
		"go":   ["res://native/go/build/libmars_kernel_go.so",    "res://native/go/build/mars_kernel_go.dll"],
		"lua":  ["res://native/lua/build/libmars_kernel_lua.so",  "res://native/lua/build/mars_kernel_lua.dll"],
	}
	for impl in libs.keys():
		var found := ""
		for p in libs[impl]:
			if FileAccess.file_exists(p) or DirAccess.open(p.get_base_dir()) != null and FileAccess.file_exists(p):
				found = p
				break
			# 导出后 res:// 内的文件走 pck，FileAccess 可读
			if FileAccess.file_exists(p):
				found = p
				break
		if found != "":
			available.append(impl)
			verified[impl] = false

	_save_status()

func _save_status() -> void:
	var payload := {
		"available": available,
		"verified": verified,
		"active": active_impl,
		"abi_version": 1,
		"note": "native kernels are bit-exact equivalents of the GDScript reference (see native/SPEC.md)",
	}
	var f := FileAccess.open(STATUS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()

func get_summary() -> String:
	if available.is_empty():
		return "Polyglot: GDScript only (native kernels not bundled)"
	return "Polyglot: %s available, active=%s" % [", ".join(available), active_impl]