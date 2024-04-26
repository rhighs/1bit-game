local entity = {}

local util = require "util"

entity.textures = {}

function entity.load_textures()
    entity.textures.ghost = rl.LoadTexture("assets/ghost.png")
end

return entity
