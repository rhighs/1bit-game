local lib = {}

local util = require "util"
local timer = require "timer"

lib.FADE_MODE_IN   = 0
lib.FADE_MODE_OUT  = 1
lib.FADE_MODE_BOTH = 2

function lib.new(duration, fade_mode, fade_ratio)
    if fade_mode == nil then fade_mode = lib.FADE_MODE_BOTH end
    if fade_ratio == nil then fade_ratio = fade_mode == lib.FADE_MODE_BOTH and 0.33 or 1.0 end
    local fade_duration = duration * fade_ratio

    local obj = {
        timer = timer.new(duration),
        value = 1.0
    }

    function obj:update(dt)
        self.timer:update(dt)
        local t = duration - self.timer:get() 
        local fading_in = t < fade_duration
        local fading_out = t > duration - fade_duration 
        if (fade_mode == lib.FADE_MODE_BOTH or fade_mode == lib.FADE_MODE_IN) and fading_in then
            self.value = util.clamp(t/fade_duration, 0, 1.0)
        end
        if (fade_mode == lib.FADE_MODE_BOTH or fade_mode == lib.FADE_MODE_OUT) and fading_out then
            self.value = util.clamp((duration - t)/fade_duration, 0, 1.0)
        end
        if not fading_in and not fading_out then self.value = 1.0 end
    end

    function obj:reset()
        self.value = 1.0
        self.timer:reset()
    end
    function obj:get() return self.value end
    function obj:done() return self.timer:done() end

    return obj
end

return lib