local platform = {}

platform.DEBUG_DRAW = false

local color = require "color"
local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

local entity = {}

local PLATFORM_DISTANCE_THRESH = 2

function entity:update(dt)
    if self.target then
        local position = self:position()
        local target_d = vec.distance(position, self.target)
        if target_d < PLATFORM_DISTANCE_THRESH then
            self.target = self:next_target()
        end

        self.body.velocity = vec.normalize(self.target - position) * self.speed
    end

    self.body:update(dt)
end

function entity:draw()
    local vec_point = self.body.position + self.body.velocity
    rl.DrawTextureRec(
        textures.platform,
        util.Rec(0, 0, 64, 12),
        self.body.position,
        rl.WHITE
    )

    if platform.DEBUG_DRAW then
        rl.DrawCircleV(self:position(), 3, rl.RED)
        if self.target then
            rl.DrawCircleV(self:position(), 3, rl.BLUE)
        end

        vec.draw(self.body.velocity, self:position())
    end
end

function entity:get_draw_box()
    return util.Rec(self.body.position.x, self.body.position.y, self.width, self.height)
end

-- rob:
-- find the closest tile that is not the current one with
-- the smallest steering effort
function entity:next_target()
    local position = self:position()
    local tile = vec.floor(position / 32)
    local dirs = table.filter({
            vec.v2(1, 0),
            vec.v2(1, 1),
            vec.v2(0, 1),
            vec.v2(-1, 1),
            vec.v2(-1, 0),
            vec.v2(-1, -1),
            vec.v2(0, -1),
            vec.v2(1, -1),
        }, function (dir)
            local next = tile + dir
            if self.decor[next.y] ~= nil then
                local neighbor = self.decor[next.y][next.x]
                return
                    neighbor ~= nil
                    and neighbor.properties ~= nil
                    and neighbor.properties.ppath_point
            end
            return false
        end
    )

    -- rob:
    -- sort by similarity
    if self.current_dir ~= nil then
        table.sort(dirs, function (a, b)
            return vec.dot(self.current_dir, a) > vec.dot(self.current_dir, b)
        end)
    end

    local new_dir = dirs[1] or self.current_dir
    self.current_dir = new_dir
    local target = vec.floor((tile + self.current_dir) * 32) + vec.v2(16, 16)
    return target
end

function entity:position()
    return vec.v2(
        self.body.position.x + self.width/2,
        self.body.position.y + self.height/2
    )
end

function entity:get_hitbox()
    return util.Rec(self.body.position.x, self.body.position.y, self.width, self.height)
end

function entity:player_collision(pos)
end

function platform.new(world, position, width, height)
    entity.__index = entity
    local body = physics.new_rectangle(position, width, height, 1.0)
    body.gravity_enabled = false
    body.air_resistance_enabled = false
    body.static_collisions_enabled = false

    local obj = setmetatable({
        starting_pos = vec.v2(position.x, position.y - height),
        decor = world.decor,
        speed = 128,
        body = body,
        height = height,
        width = width,
        current_dir = nil,
        target = nil,
        keepalive = true,
    }, entity)
    obj.target = obj:next_target()
    return obj
end

return platform
