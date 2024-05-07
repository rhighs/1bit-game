local consts = require "consts"
local util = require "util"
local player_lib = require "player"
local loader = require "loader"
local camera = require "camera"
local color = require "color"
local vec = require "vec"
local physics = require "physics"
local start_screen = require "start-screen-controller"
local ghost = require "ghost"
local interactable = require "interactable-entity"
local cooldown = require "cooldown"
local arm = require "arm"
local pendulum = require "pendulum"
local ball = require "ball"

local level_scene = {}

function create_entity(data)
    if data.enemy_id == "ghost" then
        return ghost.new(data.pos)
    elseif data.enemy_id == "level-end" then
        return interactable.new(data.pos, data.width, data.height, function()
            return "level-completed"
        end)
    elseif data.enemy_id == "arm" then
        return arm.new(data.pos)
    elseif data.enemy_id == "chain-ball" then
        return ball.new(data.pos)
    end
    error(util.pystr("unknown entity: ", data))
    -- add more entities here
end

function level_scene.new()
    return {
        name = "level",
        player = nil,
        data = {},
        cam = camera.new(consts.VP, vec.v2(0, 0)),
        bg_color = rl.BLACK,
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
            self.level_bounds = self.data.level_bounds
            self.enemies = {}
            for _, e in ipairs(self.data.entities) do
                local entt = create_entity(e)
                table.insert(self.enemies, entt)
                physics.register_body(entt.body)
            end

            physics.register_body(self.player.body)
            self.pendulum = pendulum.new(vec.v2(300, 1300), 10, 100, math.rad(179.99))
        end,

        destroy = function (self)
            physics.unregister_body(self.player.body)
            for _, e in ipairs(self.enemies) do
                physics.unregister_body(e.body)
            end
        end,

        color_swap = cooldown.make_cooled(function (self)
            self.bg_color = self.bg_color == rl.WHITE and rl.BLACK or rl.WHITE
        end, 0.2),

        update = function(self, dt)
            self:check_game_over()

            -- if rl.IsKeyDown(rl.KEY_T) then
            --     self:color_swap()
            -- end

            self.player:update(dt)
            self.cam:retarget(vec.v2(
                util.clamp(self.player:position().x, self.level_bounds.x + consts.VP.x/2, self.level_bounds.x + self.level_bounds.width - consts.VP.x/2),
                util.clamp(self.player:position().y, self.level_bounds.y + consts.VP.y/2, self.level_bounds.y + self.level_bounds.height - consts.VP.y/2)
            ))
            physics.check_collisions(self.data.ground, physics.bodies, dt)
            -- self.cam:retarget(self.player:position())

            for _, e in ipairs(self.enemies) do
                e:update(dt)
                if self:check_bounds(e:get_hitbox()) then
                    local res = e:player_collision(self.player:position())
                    if res == "game-over" then
                        self.do_game_over = true
                    elseif res == "level-completed" then
                        self.do_level_completed = true
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

        draw_at = function (self, grid, x, y)
            local tile_info = grid[y][x]
            if tile_info == nil then
                return
            end
            local texture = self.data.textures[tile_info.gid]
            if texture == nil then
                error(util.pystr("trying to draw tex id =", tile_info.gid, "at pos = (", x, y, ")"))
            end
            local y_offset = texture.height / 32 - 1
            rl.DrawTextureRec(
                texture,
                util.Rec(0, 0, texture.width  * tile_info.flip_horz,
                               texture.height * tile_info.flip_vert),
                vec.v2(x, y - y_offset) * 32,
                rl.WHITE
            )
        end,

        draw_hud = function (self, dt)
           rl.DrawRectangle(0, 0, consts.VP_WIDTH, 50, rl.BLACK)

           -- player torch status
           local torch_bar_length = consts.VP_WIDTH / 3
           local text = "TORCH [T] "
           local text_height = 18
           local text_width = rl.MeasureText(text, text_height)
           rl.DrawText(text,
               10,
               10,
               text_height,
               rl.WHITE
           )
           local bar_x = 20 + text_width
           rl.DrawRectangleLines(bar_x, 10, torch_bar_length, text_height, rl.WHITE)
           rl.DrawRectangle(bar_x, 10, torch_bar_length * (self.player.torch_battery/100.0), text_height, rl.WHITE)
        end,

        draw_simple_grid = function (self, grid)
            -- draw two tiles over the screen bounds to permit 96x96 tiles
            local tl = vec.floor(self.cam:top_left_world_pos() / 32) - vec.v2(2, 2)
            local br = vec.floor(self.cam:bottom_right_world_pos() / 32) + vec.v2(2, 2)
            for y = tl.y, br.y do
                if grid[y] ~= nil then
                    for x = tl.x, br.x do
                        self:draw_at(grid, x, y)
                    end
                end
            end
        end,

        draw = function (self)
            rl.ClearBackground(self.bg_color)

            rl.BeginMode2D(self.cam:get())
            self:draw_simple_grid(self.data.decor)
            self.player:draw(dt)
            self:draw_simple_grid(self.data.ground)

            for _, e in ipairs(self.enemies) do
                if self.cam:is_inside(e:get_draw_box()) then
                    e:draw()
                    if self.debug_mode then
                        e:draw_debug()
                    end
                end
            end
            rl.EndMode2D()

            self:draw_hud(dt)
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
