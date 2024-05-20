local entity = {}

local ffi = require "ffi"
local util = require "util"

local libs = {}
local files = rl.LoadDirectoryFiles("src/entities")
for i = 0, files.count - 1 do
    local filename = ffi.string(files.paths[i])
    if filename:sub(-4) == ".lua" then
        local lib = require(filename:sub(0, -5))
        local name = filename:gsub("%a+/", ""):sub(0, -5)
        libs[name] = lib
    end
end

function entity.create_entity(data)
    local lib = libs[data.enemy_id]
    if lib == nil then
        error(util.pystr("unknown entity: ", data))
    end
    local entt = lib.new(data.pos, data.width, data.height, data)
    entt.offscreen_start = -1
    entt.id = data.id
    return entt
end

return entity
