local util = require("util")
local player = require("player")
local color = require("color")
local ghost = require("ghost")
local camera = require("camera")
local vec = require "vec"
local level_loader = require "level_loader"

local VP_WIDTH, VP_HEIGHT = 800, 450
local VP = vec.v2(VP_WIDTH, VP_HEIGHT)

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(VP.x, VP.y, "1bit ghost house")
rl.SetTargetFPS(60)

rl.InitPhysics()
rl.SetPhysicsGravity(0.0, 1.0)

local floor = rl.CreatePhysicsBodyRectangle(vec.v2(VP.x/2, VP.y/2), 500, 20, 10)
floor.enabled = false

local cam = camera.new(vec.v2(0, 0))
local p = player.new(vec.v2(VP.x/2, 0))
local g = ghost.new(vec.v2(VP.x/2 + 100, 0))
local last_color_swap = 0.0

local level2 = require("leveldata/level2")
local level_data = level_loader.load(level2)
local textures = level_loader.load_textures()

while not rl.WindowShouldClose() do
    local dt = rl.GetFrameTime()

--     rl.UpdatePhysics()
--     p:update(dt)
--     p:wrap_y(0, VP_HEIGHT)
--     g:update(dt)
--     g:set_target(p:position())

    last_color_swap = last_color_swap + rl.GetFrameTime()
    if rl.IsKeyDown(rl.KEY_T) and last_color_swap > 0.2 then
        color.swap_color()
        last_color_swap = 0.0
    end

	rl.BeginDrawing()
	rl.ClearBackground(color.COLOR_SECONDARY)
    cam:draw(level_data.ground, VP, function (tile_id) return textures.tiles[tile_id] end)
    cam:draw_enemies(level_data.enemies, VP, function (enemy_id)
        return textures.enemies[enemy_id]
    end)
	rl.EndDrawing()

--     p:draw(dt)
--     g:draw(dt)

end

rl.ClosePhysics()
rl.CloseWindow()
