local pendulum = {}

local util = require "util"
local vec = require "vec"

local entity = {}

function entity:update(dt)
    self.t = self.t + dt
    self.angle = math.sin(-self.t)
    print(self.angle)
    self.bob_pos = self.pivot_pos + vec.v2(math.sin(self.angle) * self.radius,
                                           math.cos(self.angle) * self.radius)
end

function entity:draw()
    rl.DrawLineV(self.pivot_pos, self.bob_pos, rl.WHITE)
    rl.DrawCircleV(self.bob_pos, 16, rl.WHITE)
end

function entity:get_draw_box()
    return util.Rec(self.pivot_pos.x, self.pivot_pos.y, 32, 5*32)
end

function entity:get_hitbox()
    return util.Rec(0, 0, 1, 1)
end

function entity:player_collision(pos)
end

function pendulum.new(spawn_pos)
    entity.__index = entity
    return setmetatable({
        pivot_pos = spawn_pos,
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        angle = 0,
        t = 0,
        radius = 128
    }, entity)
end

return pendulum
