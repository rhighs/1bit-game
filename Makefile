leveldata/level%.lua: leveldata/level%.tmx
	tiled --export-map lua $< $@

run: leveldata/level2.lua
	raylua_s main.lua

.PHONY: run
