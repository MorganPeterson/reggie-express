#!/usr/bin/env bash

set -euo pipefail

LUA_FILE=$1
NAME=$(basename "$1" .lua)
STATIC_LUA_LIB=/usr/lib/x86_64-linux-gnu/liblua5.1.a
LUA_INCLUDE_DIR=/usr/include/lua5.1
shift

antifennel "${LUA_FILE}" > "${NAME}.fnl"
fennel --compile --require-as-include "${NAME}.fnl" > "tmp.lua"
luajit luastatic.lua "tmp.lua" "$STATIC_LUA_LIB" "-I${LUA_INCLUDE_DIR}" \
    -s -no-pie -o "${NAME}"
rm "${NAME}.fnl" "tmp.lua" "tmp.luastatic.c"
