#!/usr/bin/env bash
# native/build_all.sh — 幂等构建全部四种语言内核（Linux .so + Windows .dll）
#
# 用法:
#   ./native/build_all.sh            # 构建全部
#   ./native/build_all.sh cpp rust   # 只构建指定语言
#
# 每个语言的构建日志写到 build/logs/<lang>.log；失败不中断其他语言。
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG_DIR="$ROOT/build/logs"
mkdir -p "$LOG_DIR"

WIN_GCC="${WIN_GCC:-x86_64-w64-mingw32-g++}"
WIN_CC="${WIN_CC:-x86_64-w64-mingw32-gcc}"
LUA_SRC="${LUA_SRC:-/tmp/lua-5.4.6}"

export PATH="$HOME/.cargo/bin:/usr/local/go/bin:$PATH"

LANGS=("$@")
if [ ${#LANGS[@]} -eq 0 ]; then
  LANGS=(cpp rust go lua)
fi

declare -A STATUS

build_cpp() {
  local out_so="native/cpp/build/libmars_kernel_cpp.so"
  local out_dll="native/cpp/build/mars_kernel_cpp.dll"
  mkdir -p native/cpp/build
  g++ -O2 -std=c++17 -fPIC -shared -Wl,--no-undefined -I native -o "$out_so" native/cpp/mars_kernel.cpp
  command -v "$WIN_GCC" >/dev/null || return 4
  "$WIN_GCC" -O2 -std=c++17 -shared -static-libgcc -static-libstdc++ \
      -I native -o "$out_dll" native/cpp/mars_kernel.cpp
}

build_rust() {
  mkdir -p native/rust/build
  ( cd native/rust && cargo build --release --quiet ) || return 3
  cp native/rust/target/release/libmars_kernel_rust.so native/rust/build/ 2>/dev/null
  if rustup target list --installed 2>/dev/null | grep -q x86_64-pc-windows-gnu; then
    ( cd native/rust && cargo build --release --quiet --target x86_64-pc-windows-gnu ) || return 3
    cp native/rust/target/x86_64-pc-windows-gnu/release/mars_kernel_rust.dll native/rust/build/ 2>/dev/null
  fi
}

build_go() {
  mkdir -p native/go/build
  ( cd native/go && CGO_ENABLED=1 go build -buildmode=c-shared -o build/libmars_kernel_go.so . ) || return 3
  if command -v "$WIN_CC" >/dev/null; then
    ( cd native/go && CGO_ENABLED=1 GOOS=windows GOARCH=amd64 \
        CC="$WIN_CC" go build -buildmode=c-shared -o build/mars_kernel_go.dll . ) || true
  fi
}

build_lua() {
  mkdir -p native/lua/build
  # 1) Linux .so（链接系统 Lua 静态库）
  #    用 python 生成 C 数组：xxd 各发行版参数支持不一致，曾导致 blob 为空
  python3 native/lua/gen_blob.py || return 5
  # 防御：blob 必须含符号，否则 .so 会带着 undefined symbol 静默产出
  if ! grep -q "mars_lua_source" native/lua/lua_source_blob.c; then
    echo "gen_blob.py produced an empty blob" >&2
    return 6
  fi
  # -Wl,--no-undefined 让「符号没链上」在构建期就失败，而不是运行时才炸
  gcc -O2 -std=c11 -fPIC -shared -Wl,--no-undefined -I native -I"$LUA_SRC/src" \
      -o native/lua/build/libmars_kernel_lua.so \
      native/lua/mars_kernel_shim.c native/lua/lua_source_blob.c \
      -L"$LUA_SRC/src" -llua -lm -ldl
  # 2) Windows .dll（Lua 源码直接用 mingw 编进来，避免外部依赖）
  command -v "$WIN_CC" >/dev/null || return 4
  "$WIN_CC" -O2 -std=c11 -shared -DMARS_LUA_STATIC \
      -I native -I"$LUA_SRC/src" \
      -o native/lua/build/mars_kernel_lua.dll \
      native/lua/mars_kernel_shim.c native/lua/lua_source_blob.c \
      $(ls "$LUA_SRC/src/"l*.c | grep -v -E 'lua\.c|luac\.c') \
      -lm
}

for lang in "${LANGS[@]}"; do
  echo "=== building $lang ==="
  case "$lang" in
    cpp)  build_cpp  > "$LOG_DIR/cpp.log"  2>&1; rc=$? ;;
    rust) build_rust > "$LOG_DIR/rust.log" 2>&1; rc=$? ;;
    go)   build_go   > "$LOG_DIR/go.log"   2>&1; rc=$? ;;
    lua)  build_lua  > "$LOG_DIR/lua.log"  2>&1; rc=$? ;;
    *) echo "unknown language: $lang"; continue ;;
  esac
  if [ $rc -eq 0 ]; then
    STATUS[$lang]="OK"
    echo "  OK"
  else
    STATUS[$lang]="FAIL($rc)"
    echo "  FAIL rc=$rc — see build/logs/$lang.log"
    tail -5 "$LOG_DIR/$lang.log" | sed 's/^/    /'
  fi
done

echo
echo "=== artifacts ==="
ls -lh native/cpp/build/ native/rust/build/ native/go/build/ native/lua/build/ 2>/dev/null |
  grep -E '\.(so|dll)$|:' || true

echo
echo "=== harness ==="
if [ -x native/harness/mars_harness ]; then
  ./native/harness/mars_harness --all native/lua/build/libmars_kernel_lua.so
  exit $?
fi
echo "harness not built; run: gcc -O2 -std=c11 -I native -o native/harness/mars_harness native/harness/mars_harness.c -ldl -lm"
exit 0