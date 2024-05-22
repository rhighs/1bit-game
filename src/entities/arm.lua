local textures = require "textures"
local util = require "util"
local vec = require "vec"
local physics = require "physics"

local arm = {}

function arm.new(world, spawn_pos, ...)
    local arm = {
        pivot_pos = spawn_pos,
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        w = 3.5,
        angle = 0,
        radius = 128,
        state = "pendulum",
    }

    function arm:update(dt)
        return self['state_' .. self.state](self, dt)
    end

    function arm:state_pendulum(dt)
        local force = physics.GRAVITY.y * math.sin(self.angle)
        local accel = -force / self.radius
        self.w = self.w + accel * dt
        self.angle = self.angle + self.w * dt
        self.bob_pos = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.radius

        if self.angle < -math.pi/3 then
            self.state = "throw"
            self.time = 0

            local norm = vec.normalize(vec.rotate(self.pivot_pos - self.bob_pos, -math.pi/2))
            world:spawn({
                enemy_id = "chain-ball",
                pos = self.bob_pos,
                width = 0, -- both useless
                height = 0,
                init_force = vec.v2(norm.x * 1000, norm.y * 2000),
                angle = self.angle,
                radius = self.radius
            })
        end
    end

    function arm:state_throw(dt)
        self.time = self.time + 1
        if self.time > 40 and self.angle < 0 then
            self.angle = self.angle + 0.05
            if self.angle >= 0 then
                self.angle = 0
            end
        end
        if self.time > 200 then
            self.state = "pendulum"
            self.w = 3.5
            self.angle = 0
            self.bob_pos = self.pivot_pos + vec.v2(0, 4 * 32)
        end
    end

    function arm:draw()
        local num_chains = math.ceil((self.radius - (64 - 16) - 25) / 16)
        if self.state == "throw" then
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(32, 0, 32, 64),
                util.RecV(self.pivot_pos, vec.v2(32, 64)),
                vec.v2(16, 16),
                math.deg(-self.angle),
                rl.WHITE
            )
        else
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(0, 0, 32, 64),
                util.RecV(self.pivot_pos, vec.v2(32, 64)),
                vec.v2(16, 16),
                math.deg(-self.angle),
                rl.WHITE
            )
            for i = 1, num_chains do
                local pos = vec.v2(math.sin(self.angle), math.cos(self.angle)) * ((64 - 16) + (i-1)*16)
                rl.DrawTexturePro(
                    textures.chain,
                    util.Rec(0, 0, 16, 16),
                    util.RecV(self.pivot_pos + pos, vec.v2(16, 16)),
                    vec.v2(8, 0),
                    math.deg(-self.angle),
                    rl.WHITE
                )
            end
            rl.DrawTexturePro(
                textures.chain_ball,
                util.Rec(0, 0, 55, 50),
                util.RecV(self.bob_pos, vec.v2(55, 50)),
                vec.v2(55/2, 50/2),
                math.deg(-self.angle),
                rl.WHITE
            )
        end
    end

    function arm:get_draw_box()
        return util.Rec(self.bob_pos.x, self.bob_pos.y, 32, 5*32)
    end

    function arm:get_hitbox()
        return util.Rec(0, 0, 1, 1)
    end

    function arm:player_collision(pos)
    end

    return arm
end

return arm
