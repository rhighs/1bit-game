local spider = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

function spider.new(world, spawn_pos, width, height, data)
    local spider = {
        world = world,
        pos = spawn_pos - vec.v2(0, 64),
        state = "idle",
        idle_timer = 0,
        target_pos = -1
    }

    local x = math.floor(spider.pos.x / 32)
    for y = spider.pos.y/32, 0, -1 do
        if world.ground[y] ~= nil and (world.ground[y][x] ~= nil
                                    or world.ground[y][x] ~= nil) then
            spider.upper_bound = y
            break
        end
    end

    for y = spider.pos.y / 32, (world.bounds.y + world.bounds.height) / 32 do
        if world.ground[y] ~= nil and (world.ground[y][x] ~= nil
                                    or world.ground[y][x] ~= nil) then
            spider.lower_bound = y
            break
        end
    end

    function spider:update(dt)
        if self.state == "idle" then
            self.idle_timer = self.idle_timer + 1
            if self.idle_timer > 10 then
                self.state = "moving"
                self.target_pos = math.random(spider.upper_bound+1, spider.lower_bound-2) * 32
                self.dir = self.pos.y < self.target_pos and 1 or -1
            end
        else
            self.pos.y = self.pos.y + self.dir * 2
            if (self.dir ==  1 and self.pos.y >= self.target_pos)
            or (self.dir == -1 and self.pos.y <= self.target_pos) then
                self.pos.y = self.target_pos
                self.state = "idle"
                self.idle_timer = 0
            end
        end
    end

    function spider:draw()
        rl.DrawTextureV(textures.spider, self.pos, rl.WHITE)
        rl.DrawLine(spider.pos.x + 32, spider.pos.y + 19,
                    spider.pos.x + 32, spider.upper_bound * 32 + 32, rl.WHITE)
    end

    function spider:get_draw_box()
        return util.RecV(self.pos, vec.v2(textures.spider.width, textures.spider.height))
    end

    function spider:get_hitbox()
        return util.RecV(self.pos + vec.v2(24, 19), vec.v2(16, 30))
    end

    function spider:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    return spider
end

return spider

