prog := ghosts
level_data := leveldata/level1.lua leveldata/level2.lua

all: $(level_data)
	LUA_PATH="?;?.lua;src/?.lua" raylua_e src/main.lua && mv main_out $(prog) && echo "ghosts executable available at ./$(prog)"

leveldata/level%.lua: leveldata/level%.tmx leveldata/*.tx leveldata/*.tsx
	tiled --export-map --embed-tilesets --resolve-types-and-properties $< $@

.PHONY: run
run: $(level_data)
	LUA_PATH="?;?.lua;src/?.lua" raylua_s src/main.lua

.PHONY: test
test:
	LUA_PATH="?;?.lua;src/?.lua;tests/?.lua" raylua_s tests/run_tests.lua

.PHONY: install
install:
	./scripts/install-raylua.sh
