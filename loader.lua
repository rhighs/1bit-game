loader = {}

local util = require "util"
local vec = require "vec"

function loader.find_layer(data, name)
    for _, l in ipairs(data.layers) do
        if l.name == name then
            return l
        end
    end
    print("layer not found: ", name)
    return nil
end

function find_tileset(data, name)
    print("searching", name)
    for _, t in ipairs(data.tilesets) do
        if t.name == name then
            return t
        end
    end
    print("tileset not found: ", name)
    return nil
end

function load_textures(data, tilesets)
    local textures = {}
    for _, name in ipairs(tilesets) do
        local ts = find_tileset(data, name)
        for _, v in ipairs(ts.tiles) do
            textures[ts.firstgid + v.id] = rl.LoadTexture(v.image:sub(4))
        end
    end
    return textures
end

function read_tiles(layer)
    local data = {}
    for y = 1, layer.height do
        if data[y] == nil then
            data[y] = {}
        end
        for x = 1, layer.width do
            local id = layer.data[(y - 1) * layer.width + x]
            if id ~= nil and id ~= 0 then
                data[y][x] = {
                    flip_horz = bit.band(id, 0x80000000) == 0 and 1 or -1,
                    flip_vert = bit.band(id, 0x40000000) == 0 and 1 or -1,
                    gid  = bit.band(id, 0xfffffff),
                }
            end
        end
    end
    return data
end

function read_objects(layer)
    local objs = {}
    for k, v in ipairs(layer.objects) do
        table.insert(objs, {
            pos = vec.v2(v.x, v.y),
            enemy_id = v.name,
            width = v.width,
            height = v.height
        })
    end
    return objs
end

function compute_bounds(ground)
    local vecs = table.flatten(table.map(ground, function (row, y)
        local result = {}
        for x, v in pairs(row) do
            if v ~= nil and v ~= 0 then
                table.insert(result, vec.v2(x * 32, y * 32))
            end
        end
        return result
    end))

    local xs = table.map(vecs, function (v) return v.x end)
    local ys = table.map(vecs, function (v) return v.y end)
    local position = vec.v2(math.min(unpack(xs)), math.min(unpack(ys)))
    local width, height = math.max(unpack(xs)) - position.x, math.max(unpack(ys)) - position.y
    return util.Rec(position.x, position.y, width, height)
end

function loader.load_level(data)
    local textures = load_textures(data, { "ground", "decors" })
    local ground = read_tiles(loader.find_layer(data, "ground"))
    local decor = read_tiles(loader.find_layer(data, "decor"))
    local entities = read_objects(loader.find_layer(data, "entities"))

    local level_start_obj = loader.find_layer(data, "level-start").objects[1]
    if level_start_obj == nil then
        error("no level start object are defined for this level!")
    end
    local level_start = vec.v2(level_start_obj.x, level_start_obj.y)

    return {
        ground = ground,
        level_bounds = compute_bounds(ground),
        level_start = level_start,
        entities = entities,
        decor = decor,
        textures = textures
    }
end

return loader
