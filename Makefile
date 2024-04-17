leveldata/level%.lua: leveldata/level%.tmx
	tiled --export-map lua $< $@

run: leveldata/level3.lua
	raylua_s main.lua

.PHONY: run
