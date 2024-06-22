prog := ghosts
level_data := leveldata/level1.lua

all: $(level_data)
	LUA_PATH="?;?.lua;src/?.lua" raylua_e src/main.lua && mv main_out $(prog) && echo "ghosts executable available at ./$(prog)"

leveldata/level%.lua: leveldata/level%.tmx
	tiled --export-map --embed-tilesets --resolve-types-and-properties $< $@

.PHONY: run
run: $(level_data)
	LUA_PATH="?;?.lua;src/?.lua" raylua_s src/main.lua

.PHONY: install
install:
	./scripts/install-raylua.sh
