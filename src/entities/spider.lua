local spider = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

local SPIDER_RANGE      = 1.5*32
local SPIDER_SIZE       = 2*32
local SPIDER_RANGE_VERT = 2*32

function spider.new(world, spawn_pos, width, height, data)
    local spider = {
        world = world,
        pos = spawn_pos,
        state = "idle",
        timer = 0,
        target_pos = -1,
        anim_frame = 0
    }

    local orig_y = spawn_pos.y
    spider.upper_bound = 0
    local x = math.floor(spider.pos.x / 32)
    for y = math.floor(spider.pos.y/32), 0, -1 do
        if world.ground[y] ~= nil and (world.ground[y][x] ~= nil
                                    or world.ground[y][x] ~= nil) then
            spider.upper_bound = y * 32
            break
        end
    end

    spider.lower_bound = (world.bounds.y + world.bounds.height)
    for y = math.floor(spider.pos.y / 32),
            math.floor((world.bounds.y + world.bounds.height) / 32) do
        if world.ground[y] ~= nil and (world.ground[y][x] ~= nil
                                    or world.ground[y][x] ~= nil) then
            spider.lower_bound = y * 32
            break
        end
    end

    function spider:update(dt)
        function between(x, a, b)
            return x > a and x < b
        end

        self.timer = self.timer + 1
        if self.state == "idle" then
            local pp = self.world.player:position()
            if self.timer % 16 == 0 then
                self.anim_frame = (self.anim_frame + 1) % 2
            end
            if  between(pp.y, self.pos.y + SPIDER_RANGE_VERT, spider.lower_bound)
            and between(pp.x, self.pos.x - SPIDER_RANGE, self.pos.x + SPIDER_SIZE + SPIDER_RANGE) then
                self.state = "move"
                self.target_pos = math.min(pp.y - 32, self.lower_bound - 80)
                self.anim_frame = 0
            end
        elseif self.state == "move" then
            self.pos.y = self.pos.y + 8
            if self.pos.y >= self.target_pos then
                self.pos.y = self.target_pos
                self.state = "attack"
                self.timer = 0
                self.anim_frame = 1
            end
        elseif self.state == "attack" then
            if self.timer > 8 then
                self.anim_frame = 2
            end
            if self.timer > 100 then
                self.state = "move_back"
                self.anim_frame = 0
                self.timer = 0
            end
        elseif self.state == "move_back" then
            if self.timer % 16 == 0 then
                self.anim_frame = (self.anim_frame + 1) % 2
            end
            self.pos.y = self.pos.y - 2
            if self.pos.y <= orig_y then
                self.state = "idle"
                self.pos.y = orig_y
            end
        end
    end

    function spider:draw()
        rl.DrawLine(spider.pos.x + 32, spider.pos.y + 19,
                    spider.pos.x + 32, spider.upper_bound + 32, rl.WHITE)
        rl.DrawTextureRec(textures.spider, util.Rec(self.anim_frame * 64, 0, 64, 80), self.pos, rl.WHITE)
    end

    function spider:get_draw_box()
        return util.RecV(self.pos, vec.v2(64, textures.spider.height))
    end

    function spider:get_hitbox()
        if self.state == "attack" then
            return util.RecV(self.pos + vec.v2(24, 19), vec.v2(16, 50))
        end
        return util.RecV(self.pos + vec.v2(24, 19), vec.v2(16, 30))
    end

    function spider:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    return spider
end

return spider

