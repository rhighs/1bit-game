local key = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

local entity = {}

function entity:update(dt)
end

function entity:draw()
    rl.DrawTextureV(textures.key, self.pos, rl.WHITE)
end

function entity:get_draw_box()
    return util.RecV(self.pos, vec.v2(32, 32))
end

function entity:get_hitbox()
    return util.RecV(self.pos, vec.v2(32, 32))
end

function entity:player_collision(pos)
    self.destroyed = true
    self.world.entities_queue:send({
        type = "key-got"
    })
end

function key.new(world, spawn_pos, ...)
    entity.__index = entity
    return setmetatable({
        pos = spawn_pos,
        world = world
    }, entity)
end

return key

