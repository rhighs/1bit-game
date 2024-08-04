local level_exit = {}

local interactable = require "interactable-entity"

function level_exit.new(world, pos, w, h, data)
    local level_name = data.props["dst-level"]
    local entity = interactable.new(pos, w, h, function()
        world:trigger_level_transition(level_name)
    end)
    return entity
end

return level_exit