local interactable = {}

local vec = require "vec"
local util = require "util"

local entity = {}

local INTERACTION_WAIT = 0.2

function entity:update(dt)
    self.last_interaction = self.last_interaction + dt
end

function entity:draw()
    self:show_interaction("[E] interact")
    rl.DrawRectangleRec(self.bounds, rl.WHITE)
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

function entity:get_draw_box()
    return self.bounds
end

function entity:get_hitbox()
    return self.bounds
end

function entity:player_collision(pos)
    if rl.IsKeyDown(rl.KEY_E) then
        self.last_interaction = 0.0
        return self.on_interaction()
    end
    return nil
end

function interactable.new(pos, width, height, on_interaction)
    entity.__index = entity
    local pos = vec.v2(pos.x, pos.y)
    local bounds = util.Rec(pos.x, pos.y, width, height)
    return setmetatable({
        pos = pos,
        bounds = bounds,

        on_interaction = on_interaction,
        last_interaction = INTERACTION_WAIT * 2,
    }, entity)
end

return interactable
