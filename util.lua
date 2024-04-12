local color = require("color")
local ffi = require "ffi"

local util = {}

function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end
function util.Rec(x, y, w, h) return ffi.new("Rectangle", x, y, w, h) end
function util.sign(a) return a >= 0 and 1 or -1 end
function util.print(text) rl.DrawText(text, 10, 10, 20, color.COLOR_PRIMARY) end

return util
