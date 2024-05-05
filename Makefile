PROG:=ghosts
LEVEL_DATA:=leveldata/level3.lua

all: $(LEVEL_DATA)
	raylua_e main.lua && mv main_out $(PROG) && echo "ghosts executable available at ./$(PROG)"

leveldata/level%.lua: leveldata/level%.tmx
	tiled --export-map --embed-tilesets --resolve-types-and-properties $< $@

.PHONY: run
run: $(LEVEL_DATA)
	raylua_s main.lua

.PHONY: install
install:
	./scripts/install-raylua.sh
