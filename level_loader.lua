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
            [3] = rl.LoadTexture("assets/right.png")
        },
        enemies = {
            [4] = rl.LoadTexture("assets/ghost.png")
        }
    }
end

function level_loader.load(data)
    local ground = {}
    for _, chunk in ipairs(find_layer(data, "ground").chunks) do
        for y = 0, chunk.height do
            if ground[y + chunk.y] == nil then
                ground[y + chunk.y] = {}
            end
            for x = 0, chunk.width do
                local id = chunk.data[y * chunk.width + x]
                if id ~= 0 then
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
                    print("pos = " .. tostring(pos))
                    table.insert(enemies, {
                        pos = vec.v2(x + chunk.x, y + chunk.y),
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
