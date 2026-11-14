/*
 * mars_kernel.cpp — C++17 参考实现（MARS_IMPL="cpp"）
 */
#include "mars_kernel.h"
#include <cmath>
#include <algorithm>

namespace {

const int AUX_TABLE[8][4] = {
    { 4,  5,  6,  7 }, /* Se: Ne_div Ne_int Ni_pro Ni_syn */
    { 0,  1,  8,  9 }, /* Si: Se_exp Se_st  Te_exe Te_emp */
    { 0,  1,  2,  3 }, /* Ne */
    { 0,  1,  2,  3 }, /* Ni */
    { 4,  5,  6,  7 }, /* Te */
    { 4,  5,  6,  7 }, /* Ti */
    { 8,  9, 10, 11 }, /* Fe: Te_exe Te_emp Ti_ana Ti_pre */
    { 8,  9, 10, 11 }  /* Fi */
};

inline double normalize_value(double v, double m) {
    if (!(m > 0.0)) return 0.0;
    if (std::isnan(v)) return 0.0;
    double r = (v / m) * 100.0;
    if (r < 0.0) r = 0.0;
    if (r > 100.0) r = 100.0;
    return r;
}

struct Pair { double score; int index; };

} // namespace

extern "C" MARS_API int32_t mars_kernel_score(const double *battle,
                                             const double *dialogue,
                                             double wb, double wd,
                                             MarsResult *out) {
    if (!battle || !dialogue || !out) return 1;

    /* --- 归一化 --- */
    double mb = 0.0, md = 0.0;
    for (int i = 0; i < MARS_NFUNC; ++i) {
        if (std::isnan(battle[i])) continue;   /* m 从 0 起，负值不抬高 */
        if (battle[i] > mb) mb = battle[i];
    }
    for (int i = 0; i < MARS_NFUNC; ++i) {
        if (std::isnan(dialogue[i])) continue;
        if (dialogue[i] > md) md = dialogue[i];
    }

    double nb[MARS_NFUNC], nd[MARS_NFUNC];
    for (int i = 0; i < MARS_NFUNC; ++i) {
        nb[i] = normalize_value(battle[i], mb);
        nd[i] = normalize_value(dialogue[i], md);
    }

    /* --- 加权 --- */
    Pair pairs[MARS_NFUNC];
    for (int i = 0; i < MARS_NFUNC; ++i) {
        out->final_scores[i] = nb[i] * wb + nd[i] * wd;
        pairs[i].score = out->final_scores[i];
        pairs[i].index = i;
    }

    /* --- 稳定降序：分数降序，平分索引升序 --- */
    std::stable_sort(pairs, pairs + MARS_NFUNC,
                     [](const Pair &a, const Pair &b) { return a.score > b.score; });

    for (int i = 0; i < MARS_NFUNC; ++i) out->order[i] = pairs[i].index;

    out->nfunc = MARS_NFUNC;
    out->dominant = out->order[0];
    out->auxiliary = out->order[1];

    /* --- 64 型推导 --- */
    int base = out->dominant / 2;
    int sub = out->dominant % 2;
    int slot = 0;
    for (int k = 0; k < 4; ++k) {
        if (AUX_TABLE[base][k] == out->auxiliary) { slot = k; break; }
    }
    out->type_id = base * 8 + sub * 4 + slot;
    return 0;
}

extern "C" MARS_API int32_t mars_kernel_abi_version(void) { return MARS_ABI_VERSION; }

extern "C" MARS_API const char *mars_kernel_impl_name(void) { return "cpp"; }