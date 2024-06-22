loader = {}

local util = require "util"
local vec = require "vec"

function find_layer(data, name)
    local v, _ = table.find(data.layers, function (l) return l.name == name end)
    return v
end

function find_tileset(data, name)
    return table.find(data.tilesets, function (l) return l.name == name end)
end

function load_tiles(data, names)
    local tiles = {}
    for _, name in ipairs(names) do
        local ts = find_tileset(data, name)
        if ts ~= nil then
            local img = rl.LoadTexture(ts.image:sub(4))
            local h = ts.imageheight / ts.tileheight
            local w = ts.imagewidth  / ts.tilewidth
            for y = 0, h-1 do
                for x = 0, w-1 do
                    local id = y * w + x
                    tiles[ts.firstgid + id] = {
                        texture = img,
                        pos = vec.v2(x * ts.tilewidth, y * ts.tileheight),
                        size = vec.v2(ts.tilewidth, ts.tileheight)
                    }
                end
            end
        end
    end
    return tiles
end

function read_tiles(layer, tileset)
    local data = {}
    for y = 1, layer.height do
        if data[y-1] == nil then
            data[y-1] = {}
        end
        for x = 1, layer.width do
            local id = layer.data[(y - 1) * layer.width + x]
            if id ~= nil and id ~= 0 then
                local gid = bit.band(id, 0xfffffff)

                local tiledata = {
                    flip_horz = bit.band(id, 0x80000000) ~= 0,
                    flip_vert = bit.band(id, 0x40000000) ~= 0,
                    flip_diag = bit.band(id, 0x20000000) ~= 0,
                    gid = gid,
                }

                if tileset ~= nil then
                    local tile = table.find(
                        tileset.tiles,
                        function (t) return t.id == (gid - tileset.firstgid) end
                    )
                    tiledata.properties = tile.properties
                end

                data[y-1][x-1] = tiledata
            end
        end
    end
    return data
end

function read_objects(layer)
    local objs = {}
    for k, v in ipairs(layer.objects) do
        table.insert(objs, {
            id = k,
            pos = vec.v2(v.x, v.y),
            enemy_id = v.name,
            width = v.width,
            height = v.height,
            data = v.properties
        })
    end
    return objs
end

function compute_bounds(ground)
    local vecs = table.flatten(table.map(ground, function (row, y)
        local result = {}
        for x, v in pairs(row) do
            if v ~= nil and v ~= 0 then
                table.insert(result, vec.v2(x, y) * 32)
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
    local tiles = load_tiles(data, { "ground", "decor", "decor96x96" })
    local ground = read_tiles(find_layer(data, "ground"))
    local decor = read_tiles(find_layer(data, "decor"), find_tileset(data, "decors"))
    local entities = read_objects(find_layer(data, "entities"))

    local level_start_obj = find_layer(data, "level-start").objects[1]
    if level_start_obj == nil then
        error("no level start object are defined for this level!")
    end
    local level_start = vec.v2(level_start_obj.x, level_start_obj.y)

    return {
        ground = ground,
        level_bounds = util.Rec(0, 0, data.width * 32, data.height * 32),
        level_start = level_start,
        entities = entities,
        decor = decor,
        tiles = tiles
    }
end

return loader
