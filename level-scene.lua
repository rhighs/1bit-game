local util = require("util")
local player_lib = require "player"
local level_loader = require "level_loader"
local camera = require("camera")
local color = require("color")
local vec = require "vec"
local physics = require("physics")
local ghost = require("ghost")

local VP_WIDTH, VP_HEIGHT = 800, 450
local VP = vec.v2(VP_WIDTH, VP_HEIGHT)

local level_scene = {}

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

function draw_enemies(enemies, textures, camera)
end

function level_scene.new()
    return {
        player = player_lib.new(vec.v2(VP.x/2, 0)),
        data = {},
        textures = level_loader.load_textures(),
        cam = camera.new(VP, vec.v2(0, 0)),
        physics_bodies = {},
        bg_color = rl.BLACK,
        last_color_swap = 0.0,

        init = function (self, data)
            self.data = level_loader.load(require(data.level))
            self.physics_bodies = {
                self.player.body,
            }
        end,

        update = function (self, dt)
            self.cam:debug_move()
            self.last_color_swap = self.last_color_swap + rl.GetFrameTime()
            if rl.IsKeyDown(rl.KEY_T) and self.last_color_swap > 0.2 then
                self.bg_color = self.bg_color == rl.WHITE and rl.BLACK or rl.WHITE
                self.last_color_swap = 0.0
            end

            physics.update_physics(self.data.ground, self.physics_bodies, dt)
            self.player:update(dt)
            self.cam:retarget(self.player:position())
        end,

        draw_simple_grid = function (self, grid)
            local tl = vec.floor(self.cam:top_left_world_pos() / 32)
            local br = vec.floor(self.cam:bottom_right_world_pos() / 32)
            for y = tl.y, br.y do
                if grid[y] ~= nil then
                    for x = tl.x, br.x do
                        id = grid[y][x]
                        if id ~= nil and id ~= 0 then
                            rl.DrawTextureV(self.textures.tiles[id], vec.v2(x, y) * 32, rl.WHITE)
                        end
                    end
                end
            end
        end,

        draw = function (self)
            rl.ClearBackground(self.bg_color)
            rl.BeginMode2D(self.cam:get())

            self:draw_simple_grid(self.data.ground)
            self:draw_simple_grid(self.data.decor)

            for _, e in ipairs(self.data.enemies) do
                if self.cam:is_inside(e.pos) then
                    rl.DrawTextureV(self.textures.enemies[e.enemy_id], e.pos, rl.WHITE)
                end
            end

            self.player:draw(dt)
            rl.EndMode2D()
        end,

        should_change = function (self)
            return nil
        end
    }
end

return level_scene
