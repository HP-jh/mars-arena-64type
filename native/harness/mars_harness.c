/*
 * mars_harness.c — 跨语言内核一致性校验器
 *
 * 读取 native/vectors/golden.txt（由 GDScript 参考实现生成），
 * 对每个动态库逐向量比对，要求 double 位级相等。
 *
 * 用法:
 *   ./mars_harness --all
 *   ./mars_harness <lib1.so> [lib2.so ...]
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <dlfcn.h>

#include "mars_kernel.h"

#define MAXLINE 8192
#define MAXF    16

typedef int32_t (*score_fn)(const double *, const double *, double, double, MarsResult *);
typedef int32_t (*ver_fn)(void);
typedef const char *(*name_fn)(void);

/* 16 hex chars -> 8 raw little-endian bytes -> double (bit-exact) */
static int parse_hex_list(const char *s, double *out, int want) {
    int n = 0;
    const char *p = s;
    while (*p && n < want) {
        unsigned char raw[8];
        int ok = 1;
        for (int i = 0; i < 16; ++i) {
            char c = p[i];
            int v;
            if (c >= '0' && c <= '9') v = c - '0';
            else if (c >= 'a' && c <= 'f') v = c - 'a' + 10;
            else if (c >= 'A' && c <= 'F') v = c - 'A' + 10;
            else { ok = 0; break; }
            raw[i / 2] = (unsigned char)((i % 2 == 0) ? (v << 4) : (raw[i / 2] | v));
        }
        if (!ok) break;
        memcpy(&out[n], raw, 8);
        p += 16;
        n++;
        if (*p == ',') p++;
        else break;
    }
    return n;
}

static uint64_t bits(double d) { uint64_t u; memcpy(&u, &d, 8); return u; }

int main(int argc, char **argv) {
    const char *vectors = "native/vectors/golden.txt";
    const char *libs[16];
    int nlibs = 0;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--all") == 0) {
            libs[nlibs++] = "native/cpp/build/libmars_kernel_cpp.so";
            libs[nlibs++] = "native/rust/target/release/libmars_kernel_rust.so";
            libs[nlibs++] = "native/go/build/libmars_kernel_go.so";
        } else if (strncmp(argv[i], "--vectors=", 10) == 0) {
            vectors = argv[i] + 10;
        } else if (strncmp(argv[i], "--", 2) != 0) {
            libs[nlibs++] = argv[i];
        }
    }
    if (nlibs == 0) {
        fprintf(stderr, "usage: %s --all | <lib.so> ...\n", argv[0]);
        return 2;
    }

    FILE *f = fopen(vectors, "r");
    if (!f) { fprintf(stderr, "cannot open %s\n", vectors); return 2; }

    /* 载入向量 */
    static char lines[2048][MAXLINE];
    int nlines = 0;
    while (nlines < 2048 && fgets(lines[nlines], MAXLINE, f)) {
        if (lines[nlines][0] == '#' || lines[nlines][0] == '\n') continue;
        size_t L = strlen(lines[nlines]);
        while (L && (lines[nlines][L-1] == '\n' || lines[nlines][L-1] == '\r')) lines[nlines][--L] = 0;
        if (L == 0) continue;
        nlines++;
    }
    fclose(f);
    printf("vectors: %s (%d cases)\n", vectors, nlines);

    int total_fail = 0;

    for (int li = 0; li < nlibs; ++li) {
        void *h = dlopen(libs[li], RTLD_NOW | RTLD_LOCAL);
        if (!h) {
            printf("  [SKIP] %s (%s)\n", libs[li], dlerror());
            total_fail++;
            continue;
        }
        score_fn fn = (score_fn)dlsym(h, "mars_kernel_score");
        ver_fn  vf = (ver_fn)dlsym(h, "mars_kernel_abi_version");
        name_fn nf = (name_fn)dlsym(h, "mars_kernel_impl_name");
        if (!fn || !vf) {
            printf("  [FAIL] %s: missing symbols\n", libs[li]);
            total_fail++;
            dlclose(h);
            continue;
        }
        const char *impl = nf ? nf() : "?";
        if (vf() != MARS_ABI_VERSION) {
            printf("  [FAIL] %s: abi %d != %d\n", libs[li], vf(), MARS_ABI_VERSION);
            total_fail++;
            dlclose(h);
            continue;
        }

        int bad = 0;
        for (int k = 0; k < nlines; ++k) {
            char *line = strdup(lines[k]);
            char *arrow = strstr(line, "->");
            if (!arrow) { free(line); continue; }
            *arrow = 0;
            char *exp_s = arrow + 2;

            /* 输入侧: battle|dialogue|wb|wd */
            char *bar1 = strchr(line, '|');
            if (!bar1) { free(line); continue; }
            *bar1 = 0;
            char *rest = bar1 + 1;
            char *bar2 = strchr(rest, '|');
            if (!bar2) { free(line); continue; }
            *bar2 = 0;
            char *rest2 = bar2 + 1;
            char *bar3 = strchr(rest2, '|');
            if (!bar3) { free(line); continue; }
            *bar3 = 0;

            double battle[MAXF], dialogue[MAXF];
            int nb = parse_hex_list(line, battle, MAXF);
            int nd = parse_hex_list(rest, dialogue, MAXF);
            double wb = 0.0, wd = 0.0;
            parse_hex_list(rest2, &wb, 1);
            parse_hex_list(bar3 + 1, &wd, 1);

            /* 期望侧: final|order|type|dom|aux */
            char *e1 = strchr(exp_s, '|');
            if (!e1) { free(line); continue; }
            *e1 = 0;
            char *o_s = e1 + 1;
            char *e2 = strchr(o_s, '|');
            if (!e2) { free(line); continue; }
            *e2 = 0;
            char *t_s = e2 + 1;
            char *e3 = strchr(t_s, '|');
            if (!e3) { free(line); continue; }
            *e3 = 0;
            char *d_s = e3 + 1;
            char *e4 = strchr(d_s, '|');
            if (!e4) { free(line); continue; }
            *e4 = 0;
            char *a_s = e4 + 1;

            double exp_final[MAXF];
            int exp_order[MAXF];
            int nf = parse_hex_list(exp_s, exp_final, MAXF);
            int no = 0;
            { const char *p = o_s;
              while (*p && no < MAXF) { char *e = NULL; long v = strtol(p, &e, 10); if (e == p) break; exp_order[no++] = (int)v; p = e; if (*p == ',') p++; else break; } }
            int exp_type = atoi(t_s);
            int exp_dom  = atoi(d_s);
            int exp_aux  = atoi(a_s);

            if (nb != 16 || nd != 16 || nf != 16 || no != 16) {
                printf("  [FAIL] %s: malformed vector %d\n", impl, k + 1);
                bad++; free(line); continue;
            }

            MarsResult out;
            memset(&out, 0, sizeof(out));
            int rc = fn(battle, dialogue, wb, wd, &out);
            if (rc != 0) { printf("  [FAIL] %s: rc=%d on case %d\n", impl, rc, k + 1); bad++; free(line); continue; }

            for (int i = 0; i < 16; ++i) {
                if (bits(out.final_scores[i]) != bits(exp_final[i])) {
                    printf("  [FAIL] %s case %d: final[%d] %.17g != %.17g\n",
                           impl, k + 1, i, out.final_scores[i], exp_final[i]);
                    bad++; break;
                }
            }
            if (bad) { free(line); continue; }
            for (int i = 0; i < 16; ++i) {
                if (out.order[i] != exp_order[i]) {
                    printf("  [FAIL] %s case %d: order[%d]=%d != %d\n",
                           impl, k + 1, i, out.order[i], exp_order[i]);
                    bad++; break;
                }
            }
            if (bad) { free(line); continue; }
            if (out.type_id != exp_type || out.dominant != exp_dom || out.auxiliary != exp_aux) {
                printf("  [FAIL] %s case %d: type %d/%d/%d != %d/%d/%d\n",
                       impl, k + 1, out.type_id, out.dominant, out.auxiliary,
                       exp_type, exp_dom, exp_aux);
                bad++; free(line); continue;
            }
            free(line);
        }

        printf("  [%s] %-8s %s  (%d/%d cases)\n", bad ? "FAIL" : "PASS", impl,
               bad ? "MISMATCH" : "bit-exact", nlines - bad, nlines);
        total_fail += bad;
        dlclose(h);
    }

    printf("\n%s\n", total_fail == 0 ? "RESULT: ALL PASS" : "RESULT: FAILURES DETECTED");
    return total_fail == 0 ? 0 : 1;
}