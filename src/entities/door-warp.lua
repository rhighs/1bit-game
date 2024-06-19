local door_warp = {}

local interactable = require "interactable-entity"

function door_warp.new(world, pos, width, height, data)
    return interactable.new(pos, width, height, function()
        world:warp_to(data.data.to, data.data.to_level)
    end)
end

return door_warp
