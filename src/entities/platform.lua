local platform = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"

local cycle = require "cycle"

local entity = {}

function entity:update(dt)
    self.cycle:update(dt)
    self.body.velocity.x = self.cycle:current() == 0 and 50 or -50
    self.body:update(dt)
end

function entity:draw()
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

function platform.new(position, width, height)
    entity.__index = entity
    local body = physics.new_rectangle(position, width, height, 1.0)
    body.gravity_enabled = false
    body.air_resistance_enabled = false
    body.static_collisions_enabled = false

    return setmetatable({
        body = body,
        height = height,
        width = width,
        cycle = cycle.new(0, 2, 2.0),
    }, entity)
end

return platform
