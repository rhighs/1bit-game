local textures = require "textures"
local vec = require "vec"
local util = require "util"

local ghost_candle = {}

function ghost_candle.new(world, spawn_pos)
    local ghost = {
        world = world,
        pos = spawn_pos,
        candle_frame = 0,
        ghost_frame = 0,
        timer = 0,
        state = "moving",
    }

    function ghost:update(dt)
        self.timer = self.timer + 1
        self.candle_frame = math.floor(self.timer / 8) % 4
        if self.state == "moving" then
            self.ghost_frame  = math.floor(self.timer / 8) % 2
            self.pos.y = spawn_pos.y + math.cos(self.timer / 8)
            if self.timer > 20 then
                self.state = "stop"
                self.timer = 0
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
        for i = 1, 3 do
            local angle = util.random_float(math.pi/4, 3*math.pi/4)
            local v = vec.v2(math.cos(angle), math.sin(angle))
            print("angle =", math.deg(angle), "v =", v)
            self.world:spawn({
                enemy_id = "fireball",
                pos = self.pos,
                width = 0, height = 0, -- both useless
                init_force = vec.v2(v.x * 1000, -v.y * 1500)
            })
        end
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
