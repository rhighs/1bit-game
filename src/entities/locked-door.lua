local door_warp = {}

local interactable = require "interactable-entity"

function door_warp.new(world, pos, width, height, data)
    local entity = interactable.new(pos, width, height, function (self)
        if world.player.num_keys > 0 then
            world.entities_queue:send({ type = "key-used" })
            self.locked = false
        end

        if not self.locked then
            world:warp_to(data.props.to, data.props.to_level)
        end
    end)

    entity.keepalive = true
    entity.locked = true

    return entity
end

return door_warp
