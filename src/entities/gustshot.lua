local gustshot = {}

local util = require "util"
local textures = require "textures"
local cycle = require "cycle"
local vec = require "vec"

local entity = {}

local GUSTSHOT_SPEED = 400
local DRAW_DIMS = vec.v2(128, 128)

function entity:update(dt)
    self.cycle:update(dt)
    self.spawn_time = self.spawn_time + dt
    if self.radius < self.max_radius then
        self.radius = self.radius + self.grow_rate * dt
    end
    local t_id = self.cycle:current()
    if t_id == 15 then
        self.destroyed = true
    end
    self.position = self.position + self.velocity * dt
end

function entity:draw()
    local t_id = self.cycle:current()
    local tex_coord = vec.v2(t_id % 4, math.floor(t_id / 4)) * 128
    -- rl.DrawCircleLines(self.position.x, self.position.y, self.radius, rl.RED)
    rl.DrawTexturePro(
        textures.gustshot,
        util.RecV(tex_coord, DRAW_DIMS),
        util.RecV(self.position, DRAW_DIMS),
        DRAW_DIMS / 2,
        math.deg(rl.GetTime()) * 20,
        rl.WHITE
    )
end

function entity:get_draw_box()
    return util.RecV(self.position, vec.v2(self.radius * 2, self.radius * 2))
end

function entity:get_hitbox()
    return util.RecV(self.position, vec.v2(self.radius * 2, self.radius * 2))
end

function entity:player_collision(pos)
end

function entity:entity_collision(position, entity_id)
    self.world:emit_signal("gustshot_hit", {
        position = self.position,
        radius = self.radius,
    }, entity_id)
end

function gustshot.new(world, position, _w, _h, data)
    entity.__index = entity

    local grow_interval = 0.08
    local min_radius = 20
    local max_radius = 64
    local time_required = grow_interval * 16

    return setmetatable({
        powerup_tag = "gustshot",
        position = position,
        velocity = vec.normalize(data.direction) * GUSTSHOT_SPEED,
        cycle = cycle.new(0, 16, 0.08),
        world = world,
        spawn_time = 0,

        radius = min_radius,
        max_radius = max_radius,
        grow_rate = (max_radius-min_radius)/time_required
    }, entity)
end

return gustshot
