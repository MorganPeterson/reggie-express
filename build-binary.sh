#!/usr/bin/env bash

set -euo pipefail

LUA_FILE=$1
NAME=$(basename "$1" .lua)
STATIC_LUA_LIB=libs/libluajit.a
LUA_INCLUDE_DIR=include
shift

./antifennel "${LUA_FILE}" > "${NAME}.fnl"
fennel --compile --require-as-include "${NAME}.fnl" > "tmp.lua"
luajit luastatic.lua "tmp.lua" "$STATIC_LUA_LIB" "-I${LUA_INCLUDE_DIR}" \
    -s -static -no-pie -o "${NAME}"
rm "${NAME}.fnl" "tmp.lua" "tmp.luastatic.c"
