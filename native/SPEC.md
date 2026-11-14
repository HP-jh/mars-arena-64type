# Mars Kernel 规范 v1（多语言逐位一致）

本规范是 C++ / Rust / Go / Lua 四种实现的**唯一裁定标准**。参考实现是 `personality_64/personality_tracker.gd`，
四语言必须与其输出**逐位相同**（IEEE-754 double）。

## 1. 输入

| 名称 | 类型 | 含义 |
|---|---|---|
| `battle` | double[16] | 战斗行为累计分，可为任意非负值 |
| `dialogue` | double[16] | 对话选择累计分，可为任意非负值 |
| `weight_battle` | double | 0.6 |
| `weight_dialogue` | double | 0.4 |

## 2. 输出

```
final_scores[16]  加权最终分
order[16]         功能索引序列：分数降序，平分时索引升序
type_id           0..63
dominant          order[0]
auxiliary         order[1]
```

## 3. 算法（严格按序，不允许重排浮点运算）

### 3.1 归一化 `normalize(x[16]) -> n[16]`

```
m = max(x[0..15])            // 从 0.0 起逐项比较，NaN 不参与（见 §5）
if m <= 0.0:
    n[i] = 0.0               // 全部
else:
    n[i] = clamp(x[i] / m * 100.0, 0.0, 100.0)
```

注意运算顺序必须是 `(x[i] / m) * 100.0`，不可写成 `x[i] * 100.0 / m`（浮点结果可能差 1 ulp）。

### 3.2 加权

```
final[i] = n_battle[i] * weight_battle + n_dialogue[i] * weight_dialogue
```

### 3.3 排序

稳定降序：等价于对 `(score, index)` 按 `score` 降序、`index` 升序排序。
与 GDScript `sort_custom(a["score"] > b["score"])` 在平分时的表现一致。

### 3.4 64 型推导

```
base = dominant / 2          // 0..7
sub  = dominant % 2          // 0..1
auxs = AUX_TABLE[base]       // 4 个允许的辅助功能
slot = index_of(auxs, auxiliary)   // 未找到 => 0
type_id = base * 8 + sub * 4 + slot
```

`AUX_TABLE`（`base` 顺序：Se, Si, Ne, Ni, Te, Ti, Fe, Fi）：

```
0 Se: [ 4, 5, 6, 7]    // Ne_div, Ne_int, Ni_pro, Ni_syn
1 Si: [ 0, 1, 8, 9]    // Se_exp, Se_st, Te_exe, Te_emp
2 Ne: [ 0, 1, 2, 3]    // Se_exp, Se_st, Si_rec, Si_hom
3 Ni: [ 0, 1, 2, 3]
4 Te: [ 4, 5, 6, 7]
5 Ti: [ 4, 5, 6, 7]
6 Fe: [ 8, 9,10,11]    // Te_exe, Te_emp, Ti_ana, Ti_pre
7 Fi: [ 8, 9,10,11]
```

校验：`base*8 + sub*4 + slot` 必须与 `personality_tracker.gd::_build_type_mapping` 的 64 项映射完全对应，
即 `type_id` 的枚举顺序就是 `Type64` 的声明顺序（Se 8 项、Si 8 项、…、Fi 8 项）。

## 4. 边界条件

| 情况 | 行为 |
|---|---|
| `m <= 0` | 全部归一化为 0，`final` 全 0 |
| 全 0 输入 | `order` = 0..15（全平分，索引升序），`type_id` = 0 |
| 输入含负数 | 归一化后 clamp 到 0（`clamp` 下界） |
| `dominant`/`auxiliary` 相同 | 不会发生（排序结果索引互异） |
| 并列最高分 | 取索引较小者为 `dominant` |

## 5. NaN / Inf

实现必须**不崩溃**。约定：`NaN` 视为「不参与 max 比较」且归一化时输出 0.0；`+Inf` 参与 max，则其它项归一化为 0.0，
`Inf` 自身 clamp 为 100.0。四种语言按此实现，避免平台差异。

## 6. 导出符号

```
mars_kernel_score(const double*, const double*, double, double, MarsResult*) -> int32
mars_kernel_abi_version(void) -> int32   // 返回 1
mars_kernel_impl_name(void) -> const char*  // "cpp" / "rust" / "go" / "lua"
```

## 7. 一致性验收

`native/harness/mars_harness --all` 对 `native/vectors/golden.txt` 中全部向量逐项比对：

- `final_scores`：`memcmp` 级别相等（允许 0 ulp）；
- `order`、`type_id`、`dominant`、`auxiliary`：整数相等。

任意一项不一致 → 该语言标记 FAIL，构建流程拒绝发布该语言。