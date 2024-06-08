local door_warp = {}

local interactable = require "interactable-entity"

function door_warp.new(world, pos, width, height, data)
    GAME_LOG("fuck you", data)
    return interactable.new(pos, width, height, function()
        GAME_LOG("interacted with warp", data.data.warp_name, "warping to", data.data.to)
        world:warp_to(data.data.to, data.data.to_level)
    end)
end

return door_warp
