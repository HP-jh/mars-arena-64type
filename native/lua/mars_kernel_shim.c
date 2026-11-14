/*
 * mars_kernel_shim.c — Lua 内核的 C ABI 包装
 *
 * 把 native/lua/mars_kernel.lua 嵌入共享库，使 Lua 实现与其他三种语言
 * 拥有完全相同的导出符号，从而被同一套 harness 校验。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "mars_kernel.h"

/* 由 xxd -i 生成的 Lua 源码字节数组 */
extern const unsigned char mars_lua_source[];
extern const unsigned int  mars_lua_source_len;

static lua_State *G = NULL;
static int        G_ready = 0;

static int ensure_state(void) {
    if (G_ready) return 0;
    G = luaL_newstate();
    if (!G) return 1;
    luaL_openlibs(G);
    if (luaL_loadbufferx(G, (const char *)mars_lua_source, mars_lua_source_len,
                         "mars_kernel.lua", "t") != LUA_OK) {
        fprintf(stderr, "lua load error: %s\n",
                lua_tostring(G, -1) ? lua_tostring(G, -1) : "?");
        return 2;
    }
    if (lua_pcall(G, 0, 1, 0) != LUA_OK) {
        fprintf(stderr, "lua init error: %s\n",
                lua_tostring(G, -1) ? lua_tostring(G, -1) : "?");
        return 3;
    }
    lua_setfield(G, LUA_REGISTRYINDEX, "mars_kernel_module");
    G_ready = 1;
    return 0;
}

MARS_API int32_t mars_kernel_score(const double *battle,
                                   const double *dialogue,
                                   double wb, double wd,
                                   MarsResult *out) {
    if (!battle || !dialogue || !out) return 1;
    int rc = ensure_state();
    if (rc) return rc;

    lua_State *L = G;
    lua_getfield(L, LUA_REGISTRYINDEX, "mars_kernel_module");
    if (!lua_istable(L, -1)) { lua_pop(L, 1); return 4; }

    lua_getfield(L, -1, "score");
    if (!lua_isfunction(L, -1)) { lua_pop(L, 2); return 5; }

    /* 参数：battle, dialogue 两个 16 元素表 */
    for (int which = 0; which < 2; ++which) {
        const double *src = (which == 0) ? battle : dialogue;
        lua_createtable(L, MARS_NFUNC, 0);
        for (int i = 0; i < MARS_NFUNC; ++i) {
            lua_pushnumber(L, (lua_Number)src[i]);
            lua_rawseti(L, -2, i + 1);
        }
    }
    lua_pushnumber(L, (lua_Number)wb);
    lua_pushnumber(L, (lua_Number)wd);

    if (lua_pcall(L, 4, 5, 0) != LUA_OK) {
        fprintf(stderr, "lua score error: %s\n",
                lua_tostring(L, -1) ? lua_tostring(L, -1) : "?");
        lua_pop(L, 2);
        return 6;
    }

    /* 返回值：final, order, type_id, dominant, auxiliary */
    for (int i = 0; i < MARS_NFUNC; ++i) {
        lua_rawgeti(L, -5, i + 1);
        out->final_scores[i] = (double)lua_tonumber(L, -1);
        lua_pop(L, 1);
    }
    for (int i = 0; i < MARS_NFUNC; ++i) {
        lua_rawgeti(L, -4, i + 1);
        out->order[i] = (int32_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
    }
    out->type_id   = (int32_t)lua_tointeger(L, -3);
    out->dominant  = (int32_t)lua_tointeger(L, -2);
    out->auxiliary = (int32_t)lua_tointeger(L, -1);
    out->nfunc     = MARS_NFUNC;

    lua_pop(L, 6); /* 5 返回值 + 模块表 */
    return 0;
}

MARS_API int32_t mars_kernel_abi_version(void) { return MARS_ABI_VERSION; }

MARS_API const char *mars_kernel_impl_name(void) { return "lua"; }