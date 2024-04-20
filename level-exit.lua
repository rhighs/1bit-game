local level_exit = {}

local entity = {}

function entity:update(dt)
end

function entity:draw()
    rl.DrawTextureV(self.texture, self.pos, rl.WHITE)
end

function level_exit.new(pos, texture)
    entity.__index = entity
    return setmetatable({
        pos = pos,
        texture = rl.LoadTexture(texture),
    }, entity)
end

return level_exit
