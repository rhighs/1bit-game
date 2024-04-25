local consts = require "consts"
local util = require "util"
local player_lib = require "player"
local loader = require "loader"
local camera = require "camera"
local color = require "color"
local vec = require "vec"
local physics = require "physics"
local ghost = require "ghost"
local interactable = require "interactable-entity"
local start_screen = require "start-screen-controller"

local level_scene = {}

function draw_enemies(enemies, textures, camera)
end

level_scene.LEVEL_BOUNDS_PADDING = 100

function make_level_bounds(layer_bounds)
    return util.Rec(
        layer_bounds.x - level_scene.LEVEL_BOUNDS_PADDING,
        layer_bounds.y - level_scene.LEVEL_BOUNDS_PADDING,
        layer_bounds.width + (level_scene.LEVEL_BOUNDS_PADDING * 2),
        layer_bounds.height + (level_scene.LEVEL_BOUNDS_PADDING * 2) 
    )
end

function level_scene.new()
    return {
        name = "level",
        player = nil,
        data = {},
        cam = camera.new(consts.VP, vec.v2(0, 0)),
        physics_bodies = {},
        bg_color = rl.BLACK,
        last_color_swap = 0.0,
        level_bounds = nil,
        do_game_over = false,
        do_level_completed = false,

        enemies = {},
        interactables = {},

        init = function (self, data)
            self.do_game_over = false
            self.do_level_completed = false
            self.data = loader.load_level(require(data.level))
            self.player = player_lib.new(self.data.level_start)
            self.level_bounds = make_level_bounds(self.data.level_bounds)
            self.physics_bodies = {
                self.player.body,
            }
            for _, e in ipairs(self.data.enemies) do
                if e.enemy_id == 0 then
                    table.insert(self.enemies, ghost.new(e.pos))
                elseif e.enemy_id == 1 then
                    table.insert(self.enemies, interactable.new(e.pos, "assets/level_start.png", nil))
                elseif e.enemy_id == 2 then
                    local level_end = interactable.new(e.pos, "assets/level_end.png", function()
                        self.do_level_completed = true
                    end)
                    table.insert(self.enemies, level_end)
                    table.insert(self.interactables, level_end)
                end
                -- add more enemies here
            end
        end,

        update = function(self, dt)
            self:check_game_over()
            self:check_interactions()

            self.cam:debug_move()
            self.last_color_swap = self.last_color_swap + rl.GetFrameTime()
            if rl.IsKeyDown(rl.KEY_T) and self.last_color_swap > 0.2 then
                self.bg_color = self.bg_color == rl.WHITE and rl.BLACK or rl.WHITE
                self.last_color_swap = 0.0
            end

            physics.update_physics(self.data.ground, self.physics_bodies, dt)
            self.player:update(dt)
            self.cam:retarget(self.player:position())

            for _, e in ipairs(self.enemies) do
                e:update(dt)
            end
        end,

        check_interactions = function (self)
            if rl.IsKeyDown(rl.KEY_E) then
                for k, v in pairs(self.interactables) do
                    if v.interact ~= nil and v.bounds ~= nil and self:check_bounds(v.bounds) then
                        v:interact()
                    end
                end
            end
        end,

        check_game_over = function (self)
            if not self:check_bounds(self.level_bounds) then
                self:game_over()
                return
            end
        end,

        check_bounds = function (self, bounds)
            return rl.CheckCollisionCircleRec(self.player:position(), self.player.body.radius, bounds)
        end,

        game_over = function (self)
            self.do_game_over = true
        end,

        draw_tile = function (self, grid, x, y)
            local tile_info = grid[y][x]
            if tile_info == nil then
                return
            end
            local texture = self.data.textures[tile_info.gid]
            if texture == nil then
                error(util.pystr("trying to draw tex id ", id, "at pos ", x, y))
            end
            rl.DrawTextureRec(
                texture,
                util.Rec(0, 0, texture.width  * tile_info.flip_horz,
                               texture.height * tile_info.flip_vert),
                vec.v2(x, y) * 32,
                rl.WHITE
            )
        end,

        draw_simple_grid = function (self, grid)
            local tl = vec.floor(self.cam:top_left_world_pos() / 32)
            local br = vec.floor(self.cam:bottom_right_world_pos() / 32)
            for y = tl.y, br.y do
                if grid[y] ~= nil then
                    for x = tl.x, br.x do
                        self:draw_tile(grid, x, y)
                    end
                end
            end
        end,

        draw = function (self)
            rl.ClearBackground(self.bg_color)
            rl.BeginMode2D(self.cam:get())

            for k, v in pairs(self.interactables) do
                if v.show_interaction ~= nil and v.bounds ~= nil and self:check_bounds(v.bounds) then
                    v:show_interaction("[E] interact")
                end
            end

            -- debug draw level bounds
            rl.DrawRectangleLines(self.level_bounds.x, self.level_bounds.y, self.level_bounds.width, self.level_bounds.height, rl.RED)

            self:draw_simple_grid(self.data.ground)
            self:draw_simple_grid(self.data.decor)

            for _, e in ipairs(self.enemies) do
                if self.cam:is_inside(e:get_draw_box()) then
                    e:draw()
                end
            end

            self.player:draw(dt)
            rl.EndMode2D()
        end,

        should_change = function (self)
            if self.do_game_over then
                return { name = "gameover" }
            elseif self.do_level_completed then
                return { name = "levelcompleted" }
            end
            return nil
        end
    }
end

return level_scene
