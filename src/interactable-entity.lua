local interactable = {}

local vec = require "vec"
local util = require "util"
local cooldown = require "cooldown"

local entity = {}

local INTERACTION_WAIT = 0.4

function entity:update(dt)
    self.player_inside = false
end

function entity:draw()
    if self.player_inside then
        local width = rl.MeasureText(self.message, 24)
        rl.DrawText(self.message,
            (self.bounds.x + self.bounds.width/2) - width/2,
            (self.bounds.y - 20) - 32/2,
            24,
            rl.WHITE
        )
    end
end

function entity:get_draw_box()
    return self.bounds
end

function entity:get_hitbox()
    return self.bounds
end

function entity:player_collision(pos)
    self.player_inside = true
    if rl.IsKeyReleased(rl.KEY_E) then
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

        on_interaction = cooldown.make_cooled(on_interaction, INTERACTION_WAIT),
        message = "[E] interact",
        player_inside = false
    }, entity)
end

return interactable
