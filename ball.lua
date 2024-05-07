local ball = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"

local entity = {}

function entity:update(dt)
    return self['state_' .. self.state](self, dt)
end

function entity:state_pendulum(dt)
    local force = physics.GRAVITY.y * math.sin(self.angle)
    local accel = -force / self.radius
    self.w = self.w + accel * dt
    self.angle = self.angle + self.w * dt
    self.bob_pos = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.radius

    if self.angle < -math.pi/4 then
        self.state = "throw"
        self.body.air_resistance_enabled = false
        local v = self.pivot_pos - self.bob_pos
        local norm = vec.normalize(vec.rotate(v, -math.pi/2))
        self.body.position = self.bob_pos
        self.body.velocity = vec.zero()
        self.body:apply_force(norm * 1000)
    end
end

function entity:state_throw(dt)
end

function entity:draw()
    if self.state == "throw" then
        rl.DrawCircleV(self.body.position, 16, rl.WHITE)
    else
        -- rl.DrawLineV(self.pivot_pos, self.bob_pos, rl.WHITE)
        rl.DrawCircleV(self.bob_pos, 16, rl.WHITE)
    end
end

function entity:get_draw_box()
    return util.Rec(self.bob_pos.x, self.bob_pos.y, 32, 5*32)
end

function entity:get_hitbox()
    return util.Rec(0, 0, 1, 1)
end

function entity:player_collision(pos)
end

entity.has_physics_body = true

function ball.new(spawn_pos)
    entity.__index = entity
    return setmetatable({
        pivot_pos = spawn_pos,
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        w = 2.5,
        angle = 0,
        radius = 128,
        state = "pendulum",
        body = physics.new_circle(vec.zero(), 16, 1/10000),
    }, entity)
end

return ball

