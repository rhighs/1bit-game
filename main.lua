local util = require("util")
local player = require("player")
local color = require("color")
local ghost = require("ghost")
local camera = require("camera")
local vec = require "vec"
local level_loader = require "level_loader"

local physics = require("physics")

local VP_WIDTH, VP_HEIGHT = 800, 450
local VP = vec.v2(VP_WIDTH, VP_HEIGHT)

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(VP.x, VP.y, "1bit ghost house")

-- rl.InitPhysics()
-- rl.SetPhysicsGravity(0.0, 1.0)

local cam = camera.new(VP, vec.v2(0, 0))
local p = player.new(vec.v2(VP.x/2, 0))
local g = ghost.new(vec.v2(VP.x/2 + 100, 0))

local physics_bodies = {
    [1] = p.body,
    [2] = g.body,
}

local last_color_swap = 0.0

local level2 = require("leveldata/level2")
local level_data = level_loader.load(level2)
local textures = level_loader.load_textures()

function dump_ground(t)
    s = "{\n"
    for y, row in pairs(t) do
        for x, v in pairs(row) do
            s = s .. "[" .. tostring(x) .. "][" .. tostring(y) .. "] = " .. tostring(v) .. "\n"
        end
    end
    s = s .. "}"
    print(s)
end

function draw_tiles(tiles, textures)
    local tl = vec.floor(cam:top_left_world_pos() / 32)
    local br = vec.floor(cam:bottom_right_world_pos() / 32)
    for y = tl.y, br.y do
        if tiles[y] ~= nil then
            for x = tl.x, br.x do
                id = tiles[y][x]
                if id ~= nil and id ~= 0 then
                    rl.DrawTextureV(textures.tiles[id], vec.v2(x, y) * 32, rl.WHITE)
                end
            end
        end
    end
end

function draw_enemies(enemies, textures, camera)
    for _, e in ipairs(enemies) do
        if camera:is_inside(e.pos) then
            rl.DrawTextureV(textures.enemies[e.enemy_id], e.pos, rl.WHITE)
        end
    end
end

while not rl.WindowShouldClose() do
    local dt = rl.GetFrameTime()

    last_color_swap = last_color_swap + rl.GetFrameTime()
    if rl.IsKeyDown(rl.KEY_T) and last_color_swap > 0.2 then
        color.swap_color()
        last_color_swap = 0.0
    end

	rl.BeginDrawing()
	rl.ClearBackground(color.COLOR_SECONDARY)

    rl.DrawFPS(10, 10)

    rl.BeginMode2D(cam:get())
    draw_tiles(level_data.ground, textures)
    draw_enemies(level_data.enemies, textures, cam)

    physics.update_physics(level_data.ground, physics_bodies, dt)
    p:update(dt)
    g:update(dt)
    g:set_target(p:position())
    cam:retarget(p:position())
    p:draw(dt)
    g:draw(dt)

    rl.EndMode2D()

	rl.EndDrawing()
end

rl.ClosePhysics()
rl.CloseWindow()
