#!/usr/bin/env python3
"""把 Lua 内核源码内联成 C 数组（替代 xxd，避免发行版差异）。

用法: python3 native/lua/gen_blob.py [--out native/lua/lua_source_blob.c]
"""
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "mars_kernel.lua")
OUT = os.path.join(HERE, "lua_source_blob.c")


def main(argv):
    out = OUT
    for i, a in enumerate(argv):
        if a == "--out" and i + 1 < len(argv):
            out = argv[i + 1]

    with open(SRC, "rb") as f:
        data = f.read()

    lines = [
        "/* 自动生成，请勿手改：python3 native/lua/gen_blob.py */",
        "const unsigned char mars_lua_source[] = {",
    ]
    per = 16
    for off in range(0, len(data), per):
        chunk = data[off:off + per]
        lines.append("    " + ", ".join("0x%02x" % b for b in chunk) + ",")
    lines.append("};")
    lines.append("const unsigned int mars_lua_source_len = %du;" % len(data))
    lines.append("")

    with open(out, "w") as f:
        f.write("\n".join(lines))
    print("wrote %s (%d bytes of lua source)" % (out, len(data)))


if __name__ == "__main__":
    main(sys.argv)