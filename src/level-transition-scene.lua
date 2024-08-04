local timer = require "timer"
local util = require "util"
local shader = require "shader"

local level_trans = {}

local scene = {}

function scene:destroy() end

function scene:init(data)
    self.level_name = data.level_name
    self.timer:reset()
end

function scene:update(dt)
    self.timer:update(dt)
    if self.timer:done() then
        self.scene_queue:send({
            name = "level",
            data = {
                level = "leveldata/" .. self.level_name,
            }
        })
    end
 
    local t = self.scene_duration - self.timer:get() 
    self.alpha = util.clamp(
        (t < self.fade_duration                       and                       t) or
        (t > self.scene_duration - self.fade_duration and self.scene_duration - t) or
        1,
        0, 1
    )
end

function scene:draw()
    local header_text = "loading " .. self.level_name .. "..."
    width = rl.MeasureText(header_text, 32)
    rl.DrawText(header_text, 800/2 - width/2, 450/2 - 32/2, 32, util.Color(255, 255, 255, self.alpha * 255))
end

function level_trans.new(scene_queue, duration_secs)
    scene.__index = scene
    return setmetatable({
        timer = timer.new(duration_secs),
        scene_duration = duration_secs,
        fade_duration = duration_secs * 0.33,
        shader = shader.create_fragment_shader(),
        scene_queue = scene_queue,
        alpha = 0.0,
    }, scene)
end

return level_trans