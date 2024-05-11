PROG:=ghosts
LEVEL_DATA:=leveldata/level3.lua

all: $(LEVEL_DATA)
	LUA_PATH="?;?.lua;src/?.lua" raylua_e src/main.lua && mv main_out $(PROG) && echo "ghosts executable available at ./$(PROG)"

leveldata/level%.lua: leveldata/level%.tmx
	tiled --export-map --embed-tilesets --resolve-types-and-properties $< $@

.PHONY: run
run: $(LEVEL_DATA)
	LUA_PATH="?;?.lua;src/?.lua" raylua_s src/main.lua

.PHONY: install
install:
	./scripts/install-raylua.sh
