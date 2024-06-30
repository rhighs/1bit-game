local textures = require "textures"
local vec = require "vec"
local util = require "util"

local ghost_candle = {}

function ghost_candle.new(world, spawn_pos)
    local ghost = {
        world = world,
        pos = vec.copy(spawn_pos),
        candle_frame = 0,
        ghost_frame = 0,
        timer = 0,
        state = "moving",
    }

    local min = 2e64
    local max = -2e64

    function ghost:update(dt)
        self.timer = self.timer + 1
        self.candle_frame = math.floor(self.timer / 8) % 4
        if self.state == "moving" then
            self.ghost_frame  = math.floor(self.timer / 8) % 2
            local old_y = self.pos.y
            self.pos.y = spawn_pos.y + math.sin(self.timer / 8) * 16
            if self.timer > 100 and old_y > spawn_pos.y and self.pos.y < spawn_pos.y then
                self.state = "stop"
                self.timer = 0
                self.pos.y = spawn_pos.y
            end
        elseif self.state == "stop" then
            if self.timer > 50 then
                self.state = "contract"
                self.timer = 0
            end
        elseif self.state == "contract" then
            self.ghost_frame = self.timer >= 12 and 4
                            or self.timer >=  8 and 3
                            or self.timer >=  4 and 2
                            or self.ghost_frame
            if self.timer >= 16 then
                self.state = "stop-contracted"
                self.timer = 0
                self:spawn_fireballs()
            end
        elseif self.state == "stop-contracted" then
            if self.timer > 50 then
                self.state = "decontract"
                self.timer = 0
            end
        elseif self.state == "decontract" then
            self.ghost_frame = self.timer >= 12 and 1
                            or self.timer >=  8 and 2
                            or self.timer >=  4 and 3
                            or self.ghost_frame
            if self.timer >= 16 then
                self.state = "moving"
                self.timer = 0
            end
        end
    end

    function ghost:spawn_fireballs()
        local positions = {
            self.pos + vec.v2(0, 6),
            self.pos + vec.v2(22, 0),
            self.pos + vec.v2(51, 6)
        }
        local angle_bounds = { { 67, 158 }, { 45, 135 }, { 22.5, 112 } }
        for i = 1, 3 do
            local angle_bound = angle_bounds[i]
            local angle = util.random_float(
                math.rad(angle_bound[1]),
                math.rad(angle_bound[2])
            )
            local v = vec.v2(math.cos(angle), math.sin(angle))
            self.world:spawn({
                enemy_id = "fireball",
                pos = positions[i],
                width = 0, height = 0, -- both useless
                init_force = vec.v2(v.x * 1000, -v.y * 1500)
            })
        end
    end

    function ghost:on_signal_gustshot_hit(data)
        local hit_dir = vec.normalize(self.pos - data.position)
        self.pos = self.pos + hit_dir*3
    end

    function ghost:draw()
        rl.DrawTextureRec(
            textures.candles,
            util.Rec(self.candle_frame * 64, 0, 64, 64),
            self.pos,
            rl.WHITE
        )
        rl.DrawTextureRec(
            textures.candle_ghost,
            util.Rec(self.ghost_frame * 64, 0, 64, 48),
            self.pos + vec.v2(0, 26),
            rl.WHITE
        )
    end

    function ghost:get_draw_box()
        return util.RecV(self.pos, vec.v2(64, 64 + 48 - 26))
    end

    function ghost:get_hitbox()
        return util.RecV(self.pos + vec.v2(20, 20), vec.v2(64, 64 + 48 - 26) - vec.v2(20, 20))
    end

    function ghost:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    return ghost
end

return ghost_candle
