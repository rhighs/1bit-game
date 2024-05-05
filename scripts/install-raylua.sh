#!/bin/bash
error_exit() {
    echo "$1" 1>&2
    exit 1
}

git clone https://github.com/TSnake41/raylib-lua.git
cd raylib-lua
git submodule update --init --recursive
make -j 16 || error_exit "failed building raylib-lua"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    cp raylua_s.exe /usr/local/bin/raylua_s || error_exit "failed to copy raylua_s executable"
    cp raylua_e.exe /usr/local/bin/raylua_e || error_exit "failed to copy raylua_e executable"
    cp raylua_r.exe /usr/local/bin/raylua_r || error_exit "failed to copy raylua_r executable"
else
    sudo cp raylua_s /usr/local/bin/raylua_s || error_exit "failed to copy raylua_s executable"
    sudo cp raylua_e /usr/local/bin/raylua_e || error_exit "failed to copy raylua_e executable"
fi

cd .. && rm -rf raylib-lua || error_exit "failed removing dir raylib-lua"
