# Mars Arena 64Type — 执行计划（可恢复版）

> 目标：把项目升级为「多语言原生内核 + 云端构建 + 双击即用 + 低开销画质提升」的可发布版本。
> 本文件是稳定执行的**单一事实来源**：每一阶段都有明确产出物和验收命令，失败可原地重跑，不依赖上下文记忆。

## 0. 稳定性原则（为什么上次会断）

1. **所有长命令写日志到 `build/logs/*.log`**，只看 `tail`，避免工具输出过大导致中断。
2. **每阶段结束必须留下可验证的产物**（文件 + 校验命令），不是「应该好了」。
3. **失败不重来整条链**：每个阶段独立可重跑，前序产物已落盘。
4. **不在游戏运行时依赖未验证的原生库**：原生加速是可选增强，失败自动回退 GDScript。
5. **单次工具调用只做一件事**，超时上限显式设置。

## 1. 阶段划分与检查点

| 阶段 | 内容 | 产出物 | 验收 |
|---|---|---|---|
| P0 | 环境基线 | `build/logs/env.log` | `godot --version` / `mingw` / `rustc` / `go` / `lua` 全部可用 |
| P1 | 内核规范 | `native/SPEC.md` | 规范可被 4 种语言逐字实现，含 64 型推导公式 |
| P2 | C++ 内核 | `native/cpp/build/libmars_kernel_cpp.{so,dll}` | `harness` 跑 512 组向量全通过 |
| P3 | Rust 内核 | `native/rust/target/.../libmars_kernel_rust.{so,dll}` | 同上，与 C++ 逐位一致 |
| P4 | Go 内核 | `native/go/build/mars_kernel_go.{so,dll}` | 同上 |
| P5 | Lua 内核 | `native/lua/mars_kernel.lua` | 同上（同一套 golden 向量） |
| P6 | 跨语言校验器 | `native/harness/mars_harness` | `--all` 输出 PASS，退出码 0 |
| P7 | Godot 桥接 | `polyglot/polyglot_bridge.gd` | 自检 32 组向量通过；缺失时静默回退 |
| P8 | 画质提升 | `graphics/quality.gd` + 场景改动 | 三档预设可切换，GPU 开销有上限 |
| P9 | 云端构建 | `.github/workflows/release.yml` | Actions 成功产出 exe + dll + zip |
| P10 | 发布 | GitHub Release `v1.1.0` | 附件可下载、校验和一致 |

## 2. 多语言内核设计（核心）

### 2.1 为什么这样设计

- 游戏实际逻辑**仍以 GDScript 为唯一事实来源（reference）**，原生实现必须与它逐位一致；
- 4 种语言实现**同一个确定性函数**，用同一批 golden 向量交叉验证 → 「更强的语言」是**可证明的等价实现**，不是装饰；
- 原生库通过 C ABI 暴露，Godot 侧只调用 C ABI（GDExtension 可选），任何一层缺失都不影响游戏运行。

### 2.2 统一 C ABI（`native/mars_kernel.h`）

```c
int32_t mars_kernel_score(const double *battle,   // [16] 战斗原始累计分
                          const double *dialogue, // [16] 对话原始累计分
                          double wb, double wd,   // 0.6 / 0.4
                          double *out_final,      // [16] 加权后最终分
                          int32_t *out_order,     // [16] 降序索引，平分按索引升序
                          int32_t *out_type_id,   // 0..63
                          int32_t *out_dominant); // 主导功能索引
```

### 2.3 64 型推导（无需 64 项查表）

```
base = dominant / 2          # 16 功能 -> 8 大类：Se Si Ne Ni Te Ti Fe Fi
sub  = dominant % 2          # 每个大类的两个子形态
slot = aux_slot(base, auxiliary)   # 允许的 4 个辅助功能中的位置
type_id = base * 8 + sub * 4 + slot
```

允许的辅助功能表（与 `personality_tracker.gd::_build_type_mapping` 完全一致）：

```
Se: [Ne_div, Ne_int, Ni_pro, Ni_syn]
Si: [Se_exp, Se_st, Te_exe, Te_emp]
Ne: [Se_exp, Se_st, Si_rec, Si_hom]
Ni: [Se_exp, Se_st, Si_rec, Si_hom]
Te: [Ne_div, Ne_int, Ni_pro, Ni_syn]
Ti: [Ne_div, Ne_int, Ni_pro, Ni_syn]
Fe: [Te_exe, Te_emp, Ti_ana, Ti_pre]
Fi: [Te_exe, Te_emp, Ti_ana, Ti_pre]
```
未命中 → `slot = 0`（等价于 `_find_closest_type` 的降级行为）。

### 2.4 数值一致性要点

- 归一化：`max <= 0` → 全 0；否则 `clamp(raw/max*100, 0, 100)`；
- 最终分：`norm_battle*wb + norm_dialogue*wd`；
- 排序：分数降序，**平分按索引升序**（GDScript `sort_custom` 为稳定排序 + 插入序）；
- 全程 `double`，不做中间 float 截断。

## 3. 画质提升（低 GPU 开销）

约束：3 核 CPU / 无独显环境下也要能跑；目标 **稳定 60 FPS @1080p，GPU 预算 ≤ 中端集显**。

做法（全部是「便宜但显眼」的项）：
- 雾 + 大气色调统一（已在用），加 `fog_aerial_perspective`；
- `glow` 开启但 `glow_bloom` 低阈值、`glow_hdr_threshold` 高 → 只让高光溢出；
- MSAA 2x（而非 4x），阴影单级 2048，关闭 SSAO/SSIL/体积雾；
- 材质用 `vertex_color_use_as_albedo` + 简单噪声法线扰动，不加纹理采样；
- 竞技场增加低成本细节：地面网格线（无光照材质）、边缘发光条、掩体倒角；
- 提供 `Low / Medium / High` 三档，自动按 `RenderingServer.get_video_adapter_name()` 与 `--low-gpu` 参数选择。

GPU 开销控制：所有新增项都是 **常量数量 draw call**（新增 mesh 合并为单 MeshInstance3D + 单材质），不引入逐帧 CPU 计算，不引入后处理链。

## 4. 云端构建（GitHub Actions）

`.github/workflows/release.yml`：
1. ubuntu-latest，安装 mingw-w64、Rust targets、Go、Lua、Godot 4.2.2 + export templates；
2. 交叉编译 4 个内核 → `windows/amd64` + `linux/amd64`；
3. `mars_harness --all` 全语言校验（失败即构建失败）；
4. Godot `--export-release "Windows Desktop"` → `MarsArena64Type.exe`；
5. 打包 `MarsArena64Type-win64.zip`（exe + 说明 + dll）；
6. tag 推送时自动创建 Release 并上传附件 + `SHA256SUMS.txt`。

## 5. 双击即用

- `binary_format/embed_pck=true`：exe 单文件含全部资源；
- 不依赖外部 DLL 即可启动（原生内核是可选加速，缺失自动回退）；
- 附带 `启动游戏.bat`（处理 SmartScreen 提示说明）与 `README-运行说明.txt`。

## 6. 回滚与风险

| 风险 | 缓解 |
|---|---|
| 交叉编译失败 | 阶段独立；失败时该语言标记 `unavailable`，其余照常发布 |
| 原生库与 GDScript 不一致 | 桥接层启动自检 32 组向量，不一致自动禁用 |
| Godot 导出 warning | 已确认 `EXIT=0` 且产物为有效 PE，warning 不影响运行 |
| 内存不足（4.6G） | 编译加 `-j2`，一次只编一种语言 |

## 7. 执行日志

| 时间 | 阶段 | 结果 | 备注 |
|---|---|---|---|
| 2026-11-14 | P0 | Windows 导出复现成功 | `EXIT=0`，69,826,624 B，PE 头正常 |