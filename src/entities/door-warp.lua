local door_warp = {}

local interactable = require "interactable-entity"

function door_warp.new(world, pos, width, height, data)
    local entity = interactable.new(pos, width, height, function()
        if data.props.to ~= nil and data.props.to ~= "" then
            world:warp_to(data.props.to, data.props.to_level)
        end
    end)
    if data.props.to == nil or data.props.to == "" then
        GAME_LOG("changing message")
        entity.message = ""
    end
    return entity
end

return door_warp
