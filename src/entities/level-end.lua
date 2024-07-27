local level_end = {}

local interactable = require "interactable-entity"

function level_end.new(world, pos, width, height)
    local entity = interactable.new(pos, width, height, function()
        world:send_scene_event("levelcompleted")
    end)
end

return level_end
