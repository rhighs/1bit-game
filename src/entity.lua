local entity = {}

local ffi = require "ffi"
local util = require "util"

local libs = {}
local files = util.dirfiles("src/entities")
for i, filename in ipairs(files) do
    if filename:sub(-4) == ".lua" then
        local require_path = filename:sub(0, -5)
        GAME_LOG("preloading module with require path", require_path)
        local lib = require(require_path)
        local name = filename:gsub("%a+/", ""):sub(0, -5)
        libs[name] = lib
    end
end

function entity.create_new(world, data)
    local lib = libs[data.enemy_id]
    if lib == nil then
        error(util.pystr("unknown entity: ", data))
    end
    local entt = lib.new(world, data.pos, data.width, data.height, data)
    entt.offscreen_start = -1
    entt.enemy_id = data.enemy_id
    entt.id = data.id
    return entt
end

return entity
