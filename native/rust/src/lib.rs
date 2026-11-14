//! mars_kernel.rs — Rust 实现（MARS_IMPL="rust"）
//!
//! 与 native/SPEC.md 及 GDScript 参考实现逐位一致。
//! 构建: cargo build --release --target x86_64-pc-windows-gnu / x86_64-unknown-linux-gnu

use std::os::raw::c_char;

pub const MARS_NFUNC: usize = 16;
pub const MARS_ABI_VERSION: i32 = 1;

const AUX_TABLE: [[i32; 4]; 8] = [
    [4, 5, 6, 7],   // Se
    [0, 1, 8, 9],   // Si
    [0, 1, 2, 3],   // Ne
    [0, 1, 2, 3],   // Ni
    [4, 5, 6, 7],   // Te
    [4, 5, 6, 7],   // Ti
    [8, 9, 10, 11], // Fe
    [8, 9, 10, 11], // Fi
];

#[repr(C)]
pub struct MarsResult {
    pub final_scores: [f64; MARS_NFUNC],
    pub order: [i32; MARS_NFUNC],
    pub type_id: i32,
    pub dominant: i32,
    pub auxiliary: i32,
    pub nfunc: i32,
}

#[inline]
fn normalize_value(v: f64, m: f64) -> f64 {
    if !(m > 0.0) || v.is_nan() {
        return 0.0;
    }
    let mut r = (v / m) * 100.0;
    if r < 0.0 { r = 0.0; }
    if r > 100.0 { r = 100.0; }
    r
}

/// 返回 0 成功；非 0 参数错误。
///
/// # Safety
/// 指针必须非空且分别指向 16 个 f64 / 一个可写 MarsResult。
#[no_mangle]
pub unsafe extern "C" fn mars_kernel_score(
    battle: *const f64,
    dialogue: *const f64,
    wb: f64,
    wd: f64,
    out: *mut MarsResult,
) -> i32 {
    if battle.is_null() || dialogue.is_null() || out.is_null() {
        return 1;
    }
    let b = std::slice::from_raw_parts(battle, MARS_NFUNC);
    let d = std::slice::from_raw_parts(dialogue, MARS_NFUNC);
    let o = &mut *out;

    let mut mb = 0.0f64;
    let mut md = 0.0f64;
    for i in 0..MARS_NFUNC {
        if !b[i].is_nan() && b[i] > mb { mb = b[i]; }
        if !d[i].is_nan() && d[i] > md { md = d[i]; }
    }

    for i in 0..MARS_NFUNC {
        let nb = normalize_value(b[i], mb);
        let nd = normalize_value(d[i], md);
        o.final_scores[i] = nb * wb + nd * wd;
    }

    // 稳定降序：分数降序，平分索引升序
    let mut pairs: [(f64, i32); MARS_NFUNC] = [(0.0, 0); MARS_NFUNC];
    for i in 0..MARS_NFUNC {
        pairs[i] = (o.final_scores[i], i as i32);
    }
    // sort_by 是稳定排序；比较只在 a<b 时返回 Less，平分保持原序（索引升序）
    pairs.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    for i in 0..MARS_NFUNC {
        o.order[i] = pairs[i].1;
    }

    o.nfunc = MARS_NFUNC as i32;
    o.dominant = o.order[0];
    o.auxiliary = o.order[1];

    let base = (o.dominant / 2) as usize;
    let sub = o.dominant % 2;
    let mut slot = 0i32;
    for k in 0..4 {
        if AUX_TABLE[base][k] == o.auxiliary {
            slot = k as i32;
            break;
        }
    }
    o.type_id = base as i32 * 8 + sub * 4 + slot;
    0
}

#[no_mangle]
pub extern "C" fn mars_kernel_abi_version() -> i32 { MARS_ABI_VERSION }

#[no_mangle]
pub extern "C" fn mars_kernel_impl_name() -> *const c_char {
    b"rust\0".as_ptr() as *const c_char
}