local level_exit = {}

local vec = require "vec"

local entity = {}

function entity:update(dt)
end

function entity:draw()
    rl.DrawTextureV(self.texture, self.pos, rl.WHITE)
end

function level_exit.new(pos, texture)
    entity.__index = entity
    local tex = rl.LoadTexture(texture)
    return setmetatable({
        pos = vec.v2(pos.x, pos.y - ((tex.height / 32 - 1) * 32)),
        texture = tex,
    }, entity)
end

return level_exit
