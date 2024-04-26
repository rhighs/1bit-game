local entity = {}

local util = require "util"

-- This file should group information about *all* the entities in the game.
-- Add here stuff like texture loading, generic entity creation, etc., then
-- have singular entities reference this file if needed.
-- As an example, if a ghost enemy needs to draw a texture, it should get it
-- from entity.textures instead of loading it himself.

local ghost = require "ghost"
local interactable = require "interactable-entity"

entity.textures = {}

function entity.load_textures()
    entity.textures.ghost = rl.LoadTexture("assets/ghost.png")
end

function entity.create(data)
    if data.enemy_id == "ghost" then
        return ghost.new(data.pos)
    elseif data.enemy_id == "level-end" then
        return interactable.new(data.pos, data.width, data.height, function()
            return "level-completed"
        end)
    end
    error(util.pystr("unknown entity: ", data))
    -- add more entities here
end

return entity
