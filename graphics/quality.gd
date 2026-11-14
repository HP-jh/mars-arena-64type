extends Node

## GraphicsQuality — 低开销画质预设（Autoload）
##
## 目标：在集显 / 软件渲染上也能「看起来明显更好」，但几乎不增加 GPU 负担。
##
## 原则：
##   1. 只增加**常量数量的 draw call**：地面用 1 个程序化 shader 平面，
##      发光条/网格线全部合进 1 个 MultiMesh。
##   2. 不用后处理链、不用 SSAO/SSIL/体积雾/Glow，不用 4x MSAA。
##   3. 所有改动可一键降级；任何一步失败都静默跳过，绝不影响游戏启动。
##
## 预设：
##   low    — 关雾、关阴影、无装饰（最省，软件渲染自动选中）
##   medium — 天空 + 空气透视雾 + 2x MSAA + 程序化地面 + 网格线 + 边界灯带（默认）
##   high   — 中等基础上 4 级阴影级联、更远阴影距离、轻微调色
##
## 选择顺序：`--low-gpu` > `--quality=xx` > 环境变量 MARS_QUALITY > 自动探测 > medium

const PRESETS := ["low", "medium", "high"]

var preset := "medium"
var applied := false

var _status := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_apply_when_ready")

func _apply_when_ready() -> void:
	for _i in range(180):
		if get_tree().current_scene != null:
			break
		await get_tree().process_frame
	await get_tree().process_frame
	apply(_pick_preset())

func _pick_preset() -> String:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a == "--low-gpu":
			return "low"
		if a.begins_with("--quality="):
			var v := a.get_slice("=", 1).to_lower()
			if v in PRESETS:
				return v
	var env := OS.get_environment("MARS_QUALITY").to_lower()
	if env in PRESETS:
		return env

	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	_status["adapter"] = adapter
	_status["renderer"] = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"))
	if adapter.contains("llvmpipe") or adapter.contains("swiftshader") \
			or adapter.contains("softpipe") or adapter.contains("software") or adapter == "":
		return "low"
	return "medium"

func apply(name: String) -> void:
	if not (name in PRESETS):
		name = "medium"
	preset = name
	var scene := get_tree().current_scene
	if scene == null:
		return
	_apply_environment(scene)
	_apply_arena_dressing(scene)
	_apply_msaa()
	applied = true
	_status["preset"] = preset
	_status["applied"] = true
	_save_status()
	print("[GraphicsQuality] preset=%s adapter=%s" % [preset, str(_status.get("adapter", "?"))])

func _save_status() -> void:
	var f := FileAccess.open("user://graphics_status.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_status, "  "))
		f.close()

# ---------------------------------------------------------------- 节点查找

func _find_by_name(root: Node, want: String) -> Node:
	if root.name == want:
		return root
	for c in root.get_children():
		var r := _find_by_name(c, want)
		if r != null:
			return r
	return null

func _find_first_of_type(root: Node, cls: String) -> Node:
	if root.is_class(cls):
		return root
	for c in root.get_children():
		var r := _find_first_of_type(c, cls)
		if r != null:
			return r
	return null

# ---------------------------------------------------------------- environment

func _apply_environment(scene: Node) -> void:
	var we := _find_first_of_type(scene, "WorldEnvironment") as WorldEnvironment
	if we == null:
		_status["environment"] = "missing"
		return
	var env: Environment
	if we.environment == null:
		env = Environment.new()
	else:
		env = we.environment.duplicate(true)   # 不污染共享资源
	we.environment = env

	if preset != "low":
		# 程序化天空：1 次 draw，换来地平线层次 + 免费的环境光
		var sky := Sky.new()
		var mat := ProceduralSkyMaterial.new()
		mat.sky_top_color = Color(0.10, 0.07, 0.10)
		mat.sky_horizon_color = Color(0.55, 0.29, 0.18)
		mat.sky_curve = 0.18
		mat.ground_bottom_color = Color(0.05, 0.03, 0.03)
		mat.ground_horizon_color = Color(0.30, 0.16, 0.11)
		mat.sun_angle_max = 10.0
		mat.sun_curve = 0.10
		sky.sky_material = mat
		env.sky = sky
		env.background_mode = Environment.BG_SKY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.20
		env.ambient_light_sky_contribution = 1.0
	else:
		env.sky = null
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.16, 0.08, 0.06)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.28, 0.15, 0.10)
		env.ambient_light_energy = 0.30

	# 空气透视雾：只影响远处，成本极低
	env.fog_enabled = preset != "low"
	if env.fog_enabled:
		env.fog_light_color = Color(0.55, 0.26, 0.17)
		env.fog_light_energy = 0.7
		env.fog_density = 0.006
		env.fog_aerial_perspective = 0.5
		env.fog_sky_affect = 0.15
		env.fog_height = 0.6
		env.fog_height_density = 0.06

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	if preset == "high":
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.0
		env.adjustment_contrast = 1.05
		env.adjustment_saturation = 1.06
	else:
		env.adjustment_enabled = false

	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = false

	for node in scene.find_children("*", "DirectionalLight3D", true, false):
		var light := node as DirectionalLight3D
		light.shadow_enabled = preset != "low"
		light.light_energy = 1.05
		light.light_color = Color(1.0, 0.82, 0.62)
		light.light_angular_distance = 0.5
		light.shadow_bias = 0.03
		light.shadow_normal_bias = 1.4
		light.directional_shadow_split_1 = 0.10
		light.directional_shadow_split_2 = 0.25
		light.directional_shadow_split_3 = 0.50
		if preset == "high":
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.directional_shadow_max_distance = 70.0
		else:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			light.directional_shadow_max_distance = 45.0

	_status["environment"] = "ok"

func _apply_msaa() -> void:
	var vp := get_tree().root
	if vp == null:
		return
	vp.msaa_3d = Viewport.MSAA_2X if preset != "low" else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = false
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 1.0

# ------------------------------------------------------------- arena dressing

func _apply_arena_dressing(scene: Node) -> void:
	if preset == "low":
		_status["dressing"] = "off(low)"
		return
	var arena := _find_by_name(scene, "Arena") as Node3D
	if arena == null:
		_status["dressing"] = "no-arena"
		return
	if arena.get_node_or_null("QualityDressing") != null:
		_status["dressing"] = "already"
		return

	var root := Node3D.new()
	root.name = "QualityDressing"
	arena.add_child(root)

	_upgrade_ground(scene)
	_add_center_light(root)

	_status["dressing"] = "ok"

## 地面：程序化材质（无贴图采样），1 draw call，细节全在 shader 里算
func _upgrade_ground(scene: Node) -> void:
	var ground := _find_by_name(scene, "Ground") as MeshInstance3D
	if ground == null:
		return
	var extent := 25.0
	if ground.mesh is PlaneMesh:
		extent = (ground.mesh as PlaneMesh).size.x * 0.5

	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_lambert, cull_back;

uniform vec3 rock_dark : source_color = vec3(0.17, 0.09, 0.07);
uniform vec3 rock_light : source_color = vec3(0.33, 0.19, 0.13);
uniform vec3 grout : source_color = vec3(0.06, 0.04, 0.03);
uniform float cell = 2.5;
uniform float half_extent = 25.0;

varying vec3 wp;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 便宜的 value noise（4 次 hash + 2 次平滑），无贴图采样
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	float n = vnoise(p * 1.3) * 0.55 + vnoise(p * 4.7) * 0.30 + vnoise(p * 11.0) * 0.15;
	vec3 base = mix(rock_dark, rock_light, n);

	// 板块缝隙：深色细线，远处自动变淡（避免摩尔纹）
	vec2 q = abs(fract(p / cell + 0.5) - 0.5) * cell;
	float seam = 1.0 - smoothstep(0.015, 0.06, min(q.x, q.y));
	float dist = length(p);
	float seam_fade = 1.0 - smoothstep(half_extent * 0.5, half_extent * 0.95, dist);
	base = mix(base, grout, seam * 0.65 * seam_fade);

	// 中心区域略微提亮，形成视觉焦点
	float focus = 1.0 - smoothstep(0.0, half_extent * 0.7, dist);
	base *= 1.0 + focus * 0.22;

	ALBEDO = base;
	ROUGHNESS = mix(0.72, 0.96, n);
	METALLIC = 0.03;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("half_extent", extent)
	mat.set_shader_parameter("cell", 2.5)
	ground.material_override = mat

	_status["ground"] = "procedural"

## 中心补光：1 个无阴影 OmniLight，几乎零成本，让掩体有体积感
func _add_center_light(parent: Node3D) -> void:
	var l := OmniLight3D.new()
	l.name = "ArenaLight"
	l.position = Vector3(0, 7.0, 0)
	l.light_color = Color(1.0, 0.62, 0.36)
	l.light_energy = 1.6
	l.omni_range = 34.0
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	parent.add_child(l)

## 灯带 + 网格：全部合进 1 个 MultiMesh（1 draw call，无阴影）
func _add_light_strips(parent: Node3D) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.05, 0.045)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.55, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.48, 0.18)
	mat.emission_energy_multiplier = 1.8
	box.material = mat

	# 网格线：每 2.5 单位一条，20x20 场地 -> 每方向 16 条
	var half := 20.0
	var cell := 2.5
	var lines := int((half * 2.0) / cell) + 1

	var xf: Array[Transform3D] = []
	# 沿 X 方向的线（横线）
	for i in lines:
		var z := -half + i * cell
		xf.append(Transform3D(Basis().scaled(Vector3(half * 2.0, 1.0, 1.0)), Vector3(0, 0.014, z)))
	# 沿 Z 方向的线（竖线）
	for i in lines:
		var x := -half + i * cell
		xf.append(Transform3D(Basis(Vector3.UP, PI * 0.5).scaled(Vector3(half * 2.0, 1.0, 1.0)), Vector3(x, 0.014, 0)))

	# 四边灯带（沿墙脚，稍微粗一点）
	var edge := Basis().scaled(Vector3(half * 2.0, 2.0, 2.4))
	xf.append(Transform3D(edge, Vector3(0, 0.03, -half)))
	xf.append(Transform3D(edge, Vector3(0, 0.03, half)))
	var edge_z := Basis(Vector3.UP, PI * 0.5).scaled(Vector3(half * 2.0, 2.0, 2.4))
	xf.append(Transform3D(edge_z, Vector3(-half, 0.03, 0)))
	xf.append(Transform3D(edge_z, Vector3(half, 0.03, 0)))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "LightStrips"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)

func get_summary() -> String:
	return "GraphicsQuality: preset=%s applied=%s" % [preset, str(applied)]