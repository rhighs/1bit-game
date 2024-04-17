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
    local ground = find_tileset(data, "random_tileset")
    for _, t in ipairs(ground.tiles) do
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

function level_loader.load(data)
    local ground = read_layer_data(find_layer(data, "ground"))
    local decor = read_layer_data(find_layer(data, "decor"))
    local enemies_data = read_layer_data(find_layer(data, "enemies"))

    local enemies = {}
    local enemy_tileset = find_tileset(data, "enemies")
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

    local textures = load_textures(data)
    return {
        ground = ground,
        enemies = enemies,
        decor = decor,
        textures = textures
    }
end

-- function level_loader.load(data)
--     local ground = read_layer_data(find_layer(data, "ground"))
--     local decor = read_layer_data(find_layer(data, "decor"))
--     local enemies_data = read_layer_data(find_layer(data, "enemies"))
--     local textures = load_textures(data)

--     local enemies = {}
--     local enemy_tileset = find_tileset(data, "enemies")
--     for y, row in ipairs(enemies_data) do
--         for x, id in ipairs(row) do
--             if id ~= nil then
--                 table.insert(enemies, {
--                     pos = vec.v2(x, y) * 32,
--                     enemy_id = id - enemy_tileset.firstgid
--                 })
--             end
--         end
--     end

--     return {
--         ground = ground,
--         enemies = enemies,
--         decor = decor,
--         textures = textures
--     }
-- end

-- function level_loader.load_chunked(data)
--     local ground = {}
--     for _, chunk in ipairs(find_layer(data, "ground").chunks) do
--         for y = 1, chunk.height do
--             if ground[y + chunk.y] == nil then
--                 ground[y + chunk.y] = {}
--             end
--             for x = 1, chunk.width do
--                 local id = chunk.data[(y - 1) * chunk.width + x]
--                 if id ~= nil and id ~= 0 then
--                     ground[y + chunk.y][x + chunk.x] = id
--                 end
--             end
--         end
--     end

--     local enemies = {}
--     for _, chunk in ipairs(find_layer(data, "enemies").chunks) do
--         for y = 0, chunk.height do
--             for x = 0, chunk.width do
--                 elem = chunk.data[y * chunk.width + x]
--                 if elem ~= nil and elem ~= 0 then
--                     pos = vec.v2(x + chunk.x, y + chunk.y)
--                     table.insert(enemies, {
--                         pos = vec.v2(x + chunk.x, y + chunk.y) * 32,
--                         enemy_id = elem
--                     })
--                 end
--             end
--         end
--     end

--     return {
--         ground = ground,
--         enemies = enemies
--     }
-- end

return level_loader
