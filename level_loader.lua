level_loader = {}

local util = require "util"
local vec = require "vec"

function find_layer(data, name)
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

function load_textures(data)
    local textures = {}
    local ground = find_tileset(data, "ground")
    for _, t in ipairs(ground.tiles) do
        util.pyprint("loading", t.image:sub(4), "to", ground.firstgid + t.id)
        textures[ground.firstgid + t.id] = rl.LoadTexture(t.image:sub(4))
    end
    local decor = find_tileset(data, "decors")
    for _, t in ipairs(decor.tiles) do
        textures[decor.firstgid + t.id] = rl.LoadTexture(t.image:sub(4))
    end
    return textures
end

function read_layer_data(layer)
    local data = {}
    for y = 1, layer.height do
        if data[y] == nil then
            data[y] = {}
        end
        for x = 1, layer.width do
            local id = layer.data[(y - 1) * layer.width + x]
            if id ~= nil and id ~= 0 then
                data[y][x] = id
            end
        end
    end
    return data
end

function compute_bounds(ground)
    local vecs = util.table_flatten(util.table_map(ground, function (row, y) 
        local result = {}
        for x, v in pairs(row) do
            if v ~= nil and v ~= 0 then
                table.insert(result, vec.v2(x * 32, y * 32))
            end
        end
        return result
    end))

    local xs = util.table_map(vecs, function (v) return v.x end)
    local ys = util.table_map(vecs, function (v) return v.y end)
    local position = vec.v2(math.min(unpack(xs)), math.min(unpack(ys)))
    local width, height = math.max(unpack(xs)) - position.x, math.max(unpack(ys)) - position.y
    return util.Rec(position.x, position.y, width, height)
end

function level_loader.load(data)
    local ground = read_layer_data(find_layer(data, "ground"))
    local decor = read_layer_data(find_layer(data, "decor"))
    local enemies_data = read_layer_data(find_layer(data, "entities"))

    local enemies = {}
    local enemy_tileset = find_tileset(data, "entities")
    for y, row in pairs(enemies_data) do
        for x, id in pairs(row) do
            if id ~= nil then
                table.insert(enemies, {
                    pos = vec.v2(x, y) * 32,
                    enemy_id = id - enemy_tileset.firstgid
                })
            end
        end
    end

    local level_start = util.table_find(enemies, function (v) return v.enemy_id == 1 end)
    local level_end = util.table_find(enemies, function (v) return v.enemy_id == 2 end)

    local textures = load_textures(data)
    return {
        ground = ground,
        level_bounds = compute_bounds(ground),
        level_start = level_start.pos,
        level_end = level_end.pos,
        enemies = enemies,
        decor = decor,
        textures = textures
    }
end

return level_loader
