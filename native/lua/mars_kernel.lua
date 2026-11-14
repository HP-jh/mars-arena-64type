-- mars_kernel.lua — Lua 5.4 实现（MARS_IMPL="lua"）
--
-- 纯 Lua 脚本，同时被 C shim (mars_kernel_shim.c) 嵌入以导出统一 ABI。
-- 与 native/SPEC.md 及 GDScript 参考实现逐位一致。

local M = {}

M.ABI_VERSION = 1
M.IMPL_NAME = "lua"

local AUX_TABLE = {
    { 4,  5,  6,  7 },  -- Se
    { 0,  1,  8,  9 },  -- Si
    { 0,  1,  2,  3 },  -- Ne
    { 0,  1,  2,  3 },  -- Ni
    { 4,  5,  6,  7 },  -- Te
    { 4,  5,  6,  7 },  -- Ti
    { 8,  9, 10, 11 },  -- Fe
    { 8,  9, 10, 11 },  -- Fi
}

local floor = math.floor

local function normalize_value(v, m)
    if not (m > 0.0) or v ~= v then
        return 0.0
    end
    local r = (v / m) * 100.0
    if r < 0.0 then r = 0.0 end
    if r > 100.0 then r = 100.0 end
    return r
end

-- 返回 final_scores(16), order(16), type_id, dominant, auxiliary
function M.score(battle, dialogue, wb, wd)
    local mb, md = 0.0, 0.0
    for i = 1, 16 do
        local bv = battle[i]
        if bv == bv and bv > mb then mb = bv end
        local dv = dialogue[i]
        if dv == dv and dv > md then md = dv end
    end

    local final = {}
    for i = 1, 16 do
        local nb = normalize_value(battle[i], mb)
        local nd = normalize_value(dialogue[i], md)
        final[i] = nb * wb + nd * wd
    end

    -- 稳定降序：分数降序，平分索引升序
    local order = {}
    for i = 1, 16 do order[i] = i - 1 end
    table.sort(order, function(x, y)
        local sx, sy = final[x + 1], final[y + 1]
        if sx == sy then return x < y end
        return sx > sy
    end)

    local dominant = order[1]
    local auxiliary = order[2]
    local base = floor(dominant / 2)
    local sub = dominant % 2
    local slot = 0
    local auxs = AUX_TABLE[base + 1]
    for k = 1, 4 do
        if auxs[k] == auxiliary then slot = k - 1 break end
    end
    local type_id = base * 8 + sub * 4 + slot

    return final, order, type_id, dominant, auxiliary
end

return M