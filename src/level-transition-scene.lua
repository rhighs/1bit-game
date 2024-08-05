local timer = require "timer"
local util = require "util"
local shader = require "shader"
local timed_fade = require "timed-fade"

local level_trans = {}

local scene = {}

function scene:destroy() end

function scene:init(data)
    self.level_name = data.level_name
    self.timed_fade:reset()
end

function scene:update(dt)
    self.timed_fade:update(dt)
    if self.timed_fade:done() then
        self.scene_queue:send({
            name = "level",
            data = {
                level = "leveldata/" .. self.level_name,
            }
        })
    end
    self.alpha = self.timed_fade:get()
end

function scene:draw()
    local header_text = "loading " .. self.level_name .. "..."
    width = rl.MeasureText(header_text, 32)
    rl.DrawText(header_text, 800/2 - width/2, 450/2 - 32/2, 32, util.Color(255, 255, 255, self.alpha * 255))
end

function level_trans.new(scene_queue, duration_secs)
    scene.__index = scene
    return setmetatable({
        scene_queue = scene_queue,
        timed_fade = timed_fade.new(duration_secs, timed_fade.FADE_MODE_BOTH),
        alpha = 0.0,
    }, scene)
end

return level_trans