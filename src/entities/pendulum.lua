local pendulum = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local timer = require "timer"

local entity = {}

function entity:update(dt)
    local force = physics.GRAVITY.y * math.sin(self.angle)
    local angle_a = -force / self.rod_length
    self.angle_v = self.angle_v + self.angle_a * dt
    self.angle = self.angle + self.angle_v * dt
end

function entity:draw()
    local bob_position = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.rod_length
    rl.DrawCircleV(self.pivot_pos, 3, rl.WHITE)
    rl.DrawLineV(self.pivot_pos, bob_position, rl.WHITE)
    rl.DrawCircleV(bob_position, self.bob_radius, rl.WHITE)
end

function entity:get_draw_box()
    return util.Rec(
        self.pivot_pos.x - self.rod_length - self.bob_radius,
        self.pivot_pos.y - self.rod_length - self.bob_radius,
        (self.rod_length + self.bob_radius) * 2,
        (self.rod_length + self.bob_radius) * 2
    )
end

function entity:get_hitbox()
    -- rob: not really correct atm, but whatever
    local bob_position = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.rod_length
    return util.Rec(
        bob_position.x - self.bob_radius,
        bob_position.y - self.bob_radius,
        self.bob_radius * 2,
        self.bob_radius * 2
    )
end

function entity:player_collision(pos)
end

function pendulum.new(pivot_pos, bob_radius, rod_length, start_angle)
    entity.__index = entity

    return setmetatable({
        timer = timer.new(3),
        pivot_pos = pivot_pos,
        rod_length = rod_length,
        bob_radius = bob_radius,
        angle = start_angle,
        angle_a = 0,
        angle_v = 0,
    }, entity)
end

return pendulum
