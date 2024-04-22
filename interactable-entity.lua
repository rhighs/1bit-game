local interactable = {}

local vec = require "vec"
local util = require "util"

local entity = {}

local INTERACTION_WAIT = 0.2

function entity:update(dt)
    self.last_interaction = self.last_interaction + dt
end

function entity:draw()
    rl.DrawTextureV(self.texture, self.pos, rl.WHITE)
end

function entity:show_interaction(message)
    local width = rl.MeasureText(message, 24)
    rl.DrawText(message,
        (self.bounds.x + self.bounds.width/2) - width/2,
        (self.bounds.y - 20) - 32/2,
        24,
        rl.WHITE
    )
end

function entity:interact()
    if rl.IsKeyDown(rl.KEY_E) and self.last_interaction > INTERACTION_WAIT then
        self.on_interaction()
        self.last_interaction = 0.0
    end
end

function interactable.new(pos, texture, on_interaction)
    entity.__index = entity
    local tex = rl.LoadTexture(texture)
    local pos = vec.v2(pos.x, pos.y - ((tex.height / 32 - 1) * 32))
    local bounds = util.Rec(pos.x, pos.y, tex.width, tex.height)
    return setmetatable({
        pos = pos,
        bounds = bounds,
        texture = tex,

        on_interaction = on_interaction,
        last_interaction = INTERACTION_WAIT * 2,
    }, entity)
end

return interactable
