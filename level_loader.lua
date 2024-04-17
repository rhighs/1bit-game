level_loader = {}

local vec = require "vec"

function find_layer(data, name)
    for _, l in ipairs(data.layers) do
        if l.name == name then
            return l
        end
    end
    return nil
end

function level_loader.load_textures()
    return {
        tiles = {
            [1] = rl.LoadTexture("assets/left.png"),
            [2] = rl.LoadTexture("assets/middle.png"),
            [3] = rl.LoadTexture("assets/right.png"),
            [4] = rl.LoadTexture("assets/door_bottom_left.png"),
            [5] = rl.LoadTexture("assets/door_bottom_right.png"),
            [6] = rl.LoadTexture("assets/door_top_left.png"),
            [7] = rl.LoadTexture("assets/door_top_right.png"),
            [8] = rl.LoadTexture("assets/window.png")
        },
        enemies = {
            [4] = rl.LoadTexture("assets/ghost.png")
        }
    }
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
    local ground_layer = find_layer(data, "ground")
    local ground = read_layer_data(ground_layer)

    local decor_layer = find_layer(data, "decor")
    local decor = read_layer_data(decor_layer)

    local enemies_layer = find_layer(data, "enemies")
    local enemies_data = read_layer_data(enemies_layer)
    local enemies = {}
    for y, row in ipairs(enemies_data) do
        for x, id in ipairs(row) do
            if id ~=nil then
                table.insert(enemies, {
                    pos = vec.v2(x, y) * 32,
                    enemy_id = id
                })
            end
        end
    end

    return {
        ground = ground,
        enemies = enemies,
        decor = decor
    }
end

function level_loader.load_chunked(data)
    local ground = {}
    for _, chunk in ipairs(find_layer(data, "ground").chunks) do
        for y = 1, chunk.height do
            if ground[y + chunk.y] == nil then
                ground[y + chunk.y] = {}
            end
            for x = 1, chunk.width do
                local id = chunk.data[(y - 1) * chunk.width + x]
                if id ~= nil and id ~= 0 then
                    ground[y + chunk.y][x + chunk.x] = id
                end
            end
        end
    end

    local enemies = {}
    for _, chunk in ipairs(find_layer(data, "enemies").chunks) do
        for y = 0, chunk.height do
            for x = 0, chunk.width do
                elem = chunk.data[y * chunk.width + x]
                if elem ~= nil and elem ~= 0 then
                    pos = vec.v2(x + chunk.x, y + chunk.y)
                    table.insert(enemies, {
                        pos = vec.v2(x + chunk.x, y + chunk.y) * 32,
                        enemy_id = elem
                    })
                end
            end
        end
    end

    return {
        ground = ground,
        enemies = enemies
    }
end

return level_loader
