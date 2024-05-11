local level_end = {}

local interactable = require "interactable-entity"

function level_end.new(pos, width, height)
    return interactable.new(pos, width, height, function()
        return "level-completed"
    end)
end

return level_end
