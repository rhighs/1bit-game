local textures = require "textures"
local util = require "util"
local vec = require "vec"
local physics = require "physics"
local event_queue = require "event_queue"

local arm = {}

local ARM_HEIGHT = 69 -- and not 64
local BALL_WIDTH = 48
local BALL_HEIGHT = 48
local HANDLE_HEIGHT = 13
local PENDULUM_RADIUS = 128
local ARM_OFFSET = 16
local BALL_RADIUS = 48/2
local CHAIN_HEIGHT = 16

function arm.new(world, spawn_pos, ...)
    local dir = world.player:position().x < spawn_pos.x and -1 or 1
    local arm = {
        pivot_pos = vec.copy(spawn_pos),
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        w = 3.5 * dir * -1,
        angle = 0,
        radius = PENDULUM_RADIUS,
        state = "pendulum",
        event_queue = event_queue.new(),
        world = world,
        direction = dir
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

        if self.direction == -1 and self.angle < -math.pi/3
        or self.direction ==  1 and self.angle >  math.pi/3 then
            self.state = "throw"
            self.time = 0

            local norm = vec.normalize(vec.rotate(self.pivot_pos - self.bob_pos, math.pi/2 * self.direction))
            world:spawn({
                enemy_id = "chain-ball",
                pos = self.bob_pos,
                width = 0, height = 0, -- both useless
                init_force = vec.v2(norm.x * 1000, norm.y * 2000),
                angle = self.angle,
                radius = self.radius,
                arm_queue = self.event_queue,
                direction = self.direction
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
        local ev = self.event_queue:recv()
        if ev == 'chain-ball-despawned' then
            self.state = 'appear'
            self.pos = 100
            self.bob_pos = self.pivot_pos + vec.v2(0, self.radius)
        end
    end

    function arm:state_appear(dt)
        self.time = self.time + 1
        self.pos = self.pos - 1
        if self.time % 4 < 2 then
            self.bob_pos = self.pivot_pos + vec.v2(self.pos, self.radius)
        else
            self.bob_pos = self.pivot_pos + vec.v2(-self.pos, self.radius)
        end
        if self.pos == 0 then
            self.state = "pendulum"
            self.direction = world.player:position().x < self.pivot_pos.x and -1 or 1
            self.w = 3.5 * self.direction * -1
            self.angle = 0
            self.bob_pos = self.pivot_pos + vec.v2(0, 4 * 32)
        end
    end

    function arm:draw()
        local num_chains = math.ceil((self.radius - (ARM_HEIGHT - ARM_OFFSET) - BALL_RADIUS) / CHAIN_HEIGHT)
        if self.state == "throw" then
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(32, 0, 32 * self.direction, ARM_HEIGHT),
                util.RecV(self.pivot_pos, vec.v2(32, ARM_HEIGHT)),
                vec.v2(ARM_OFFSET, ARM_OFFSET),
                math.deg(-self.angle),
                rl.WHITE
            )
        elseif self.state == "pendulum" then
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(0, 0, 32 * self.direction, ARM_HEIGHT),
                util.RecV(self.pivot_pos, vec.v2(32, ARM_HEIGHT)),
                vec.v2(ARM_OFFSET, ARM_OFFSET),
                math.deg(-self.angle),
                rl.WHITE
            )
            for i = 1, num_chains do
                local pos = vec.v2(math.sin(self.angle), math.cos(self.angle))
                          * ((ARM_HEIGHT - ARM_OFFSET) + (i-1)*16)
                rl.DrawTexturePro(
                    textures.arm,
                    util.Rec(128, 0, 16, 16),
                    util.RecV(self.pivot_pos + pos, vec.v2(16, 16)),
                    vec.v2(8, 0),
                    math.deg(-self.angle),
                    rl.WHITE
                )
            end
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(64, 0, 55, 50),
                util.RecV(self.bob_pos, vec.v2(55, 50)),
                vec.v2(55/2, 50/2),
                math.deg(-self.angle),
                rl.WHITE
            )
        else -- state: appear
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(32, 0, 32 * self.direction, ARM_HEIGHT), -- arm
                util.RecV(self.pivot_pos, vec.v2(32, ARM_HEIGHT)),
                vec.v2(16, 16),
                0,
                rl.WHITE
            )
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(128, 16, 32, 16),
                util.RecV(
                    vec.v2(
                        self.bob_pos.x-16,
                        self.pivot_pos.y + ARM_HEIGHT - ARM_OFFSET - 13
                    ),
                    vec.v2(32, 16)
                ),
                vec.v2(0, 0),
                0,
                rl.WHITE
            )
            for i = 1, num_chains do
                local y = ((ARM_HEIGHT - ARM_OFFSET) + (i-1)*16)
                rl.DrawTexturePro(
                    textures.arm,
                    util.Rec(128, 0, 16, 16),
                    util.RecV(vec.v2(self.bob_pos.x, self.pivot_pos.y + y), vec.v2(16, 16)),
                    vec.v2(8, 0),
                    0,
                    rl.WHITE
                )
            end
            rl.DrawTexturePro(
                textures.arm,
                util.Rec(64, 0, 55, 50),
                util.RecV(self.bob_pos, vec.v2(55, 50)),
                vec.v2(55/2, 50/2),
                0,
                rl.WHITE
            )
        end
    end

    function arm:get_draw_box()
        if self.state == "pendulum" then
            local left_pos  = math.min(self.bob_pos.x, self.pivot_pos.x)
            local right_pos = math.max(self.bob_pos.x, self.pivot_pos.x)
            local up_pos    = math.min(self.bob_pos.y, self.pivot_pos.y)
            local down_pos  = math.max(self.bob_pos.y, self.pivot_pos.y)
            local xmin = left_pos  - (left_pos  == self.bob_pos.x and 55 or 16)
            local xmax = right_pos + (right_pos == self.bob_pos.x and 55 or 16)
            local ymin = up_pos    - (up_pos    == self.bob_pos.y and 50 or 16)
            local ymax = down_pos  + (down_pos  == self.bob_pos.y and 50 or 16)
            return util.Rec(xmin, ymin, xmax - xmin, ymax - ymin)
        elseif self.state == "throw" then
            local end_pos = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * 64
            local xmin = math.min(end_pos.x, self.pivot_pos.x - 16)
            local xmax = math.max(end_pos.x, self.pivot_pos.x + 16)
            local ymin = math.min(end_pos.y, self.pivot_pos.y - 16)
            local ymax = math.max(end_pos.y, self.pivot_pos.y + 16)
            return util.Rec(xmin, ymin, xmax - xmin, ymax - ymin)
        else
            local xmin = math.min(self.bob_pos.x - BALL_RADIUS, self.pivot_pos.x - 16)
            local xmax = math.min(self.bob_pos.x - BALL_RADIUS, self.pivot_pos.x + 16)
            local ymin = self.pivot_pos.y - 16
            local ymax = self.bob_pos.y + BALL_RADIUS
            return util.Rec(xmin, ymin, xmax - xmin, ymax - ymin)
        end
    end

    function arm:get_hitbox()
        if self.state == "pendulum" then
            return util.RecV(self.bob_pos - vec.v2(BALL_RADIUS, BALL_RADIUS),
                             vec.v2(BALL_RADIUS, BALL_RADIUS))
        else
            return util.Rec(0, 0, 0, 0)
        end
    end

    function arm:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    return arm
end

return arm
