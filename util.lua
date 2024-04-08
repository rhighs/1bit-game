local ffi = require "ffi"

local util = {}

function util.Vec2(x, y) return rl.new("Vector2", x, y) end
function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end

return util