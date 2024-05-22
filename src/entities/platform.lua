local platform = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"

local cycle = require "cycle"

local entity = {}

function entity:update(dt)
    self.cycle:update(dt)
    self.body.velocity = vec.v2(math.sin(rl.GetTime() * 1), math.cos(rl.GetTime() * 1)) * 100
    self.body:update(dt)
end

function entity:draw()
    local vec_point = self.body.position + self.body.velocity
    rl.DrawLine(self.body.position.x, self.body.position.y, vec_point.x, vec_point.y, rl.RED)
    rl.DrawRectangle(self.body.position.x, self.body.position.y, self.width, self.height, rl.GREEN)
end

function entity:get_draw_box()
    return util.Rec(self.body.position.x, self.body.position.y, self.width, self.height)
end

function entity:get_hitbox()
    return util.Rec(self.body.position.x, self.body.position.y, self.width, self.height)
end

function entity:player_collision(pos)
end

function platform.new(world, position, width, height)
    entity.__index = entity
    local body = physics.new_rectangle(position, width, height, 1.0)
    body.gravity_enabled = false
    body.air_resistance_enabled = false
    body.static_collisions_enabled = false

    return setmetatable({
        starting_pos = position,
        body = body,
        height = height,
        width = width,
        cycle = cycle.new(0, 2, 2.0),
    }, entity)
end

return platform
