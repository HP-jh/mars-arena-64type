/*
 * mars_kernel.h — Mars Arena 64Type 多语言内核统一 ABI
 *
 * 所有语言实现（C++ / Rust / Go / Lua）必须产出逐位一致的结果。
 * 规格见 native/SPEC.md。任何实现偏离 => native/harness 校验失败 => 该语言被禁用。
 */
#ifndef MARS_KERNEL_H
#define MARS_KERNEL_H

#include <stdint.h>

#ifdef _WIN32
#  define MARS_API __declspec(dllexport)
#else
#  define MARS_API __attribute__((visibility("default")))
#endif

#define MARS_NFUNC      16   /* 16 个细分认知功能 */
#define MARS_NTYPES     64   /* 64 型人格 */
#define MARS_ABI_VERSION 1

typedef struct MarsResult {
    double  final_scores[MARS_NFUNC]; /* [out] 加权后的最终分 0..100 */
    int32_t order[MARS_NFUNC];        /* [out] 功能索引，按分数降序；平分按索引升序 */
    int32_t type_id;                  /* [out] 0..63 */
    int32_t dominant;                 /* [out] 主导功能索引 0..15 */
    int32_t auxiliary;                /* [out] 辅助功能索引 0..15 */
    int32_t nfunc;                    /* [out] 恒为 16 */
} MarsResult;

#ifdef __cplusplus
extern "C" {
#endif

/* 返回 0 表示成功，非 0 表示参数错误。 */
MARS_API int32_t mars_kernel_score(const double *battle,
                                   const double *dialogue,
                                   double weight_battle,
                                   double weight_dialogue,
                                   MarsResult *out);

MARS_API int32_t mars_kernel_abi_version(void);
MARS_API const char *mars_kernel_impl_name(void);

#ifdef __cplusplus
}
#endif

#endif /* MARS_KERNEL_H */