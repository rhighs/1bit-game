local gustshot = {}

local util = require "util"
local textures = require "textures"
local vec = require "vec"

local entity = {}

local GUSTSHOT_SPEED = 400

function entity:update(dt)
    if self.radius < self.max_radius then
        self.radius = self.radius + self.grow_speed * dt
    end
    self.position = self.position + self.velocity * dt
end

function entity:draw()
    vec.draw(self.velocity, self.position, rl.RED)
    rl.DrawCircleLines(self.position.x, self.position.y, self.radius, rl.RED)
end

function entity:get_draw_box()
    return util.RecV(self.position, vec.v2(self.radius * 2, self.radius * 2))
end

function entity:get_hitbox()
    return util.RecV(self.position, vec.v2(self.radius * 2, self.radius * 2))
end

function entity_collision(pos)
end

function entity:player_collision(pos)
end

function entity:entity_collision(position, entity_id)
    local entity = self.world.entities[entity_id]
    if position ~= nil and position ~= 0 and entity.enemy_id == "ghost-candle" then
        local hit_dir = vec.normalize(position - self.position)
        self.world.entities[entity_id].pos = position + (hit_dir*3)
    end
    -- how about:
    -- self.world:send_event({
    --     type = "gustshot-hit",
    --     ...
    -- })
    -- and let the entity react to it?
end

function gustshot.new(world, position, _w, _h, data)
    entity.__index = entity

    local min_radius = 20
    local max_radius = 200
    local grow_time_secs = 1.5

    return setmetatable({
        powerup_tag = "gustshot",
        position = position,
        velocity = vec.normalize(data.direction) * GUSTSHOT_SPEED,
        world = world,

        radius = min_radius,
        max_radius = max_radius,
        grow_speed = (max_radius - min_radius) / grow_time_secs
    }, entity)
end

return gustshot
