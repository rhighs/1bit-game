local vec = {}

local util = require "util"

function vec.zero() return rl.new("Vector2", 0, 0) end
function vec.v2(x, y) return rl.new("Vector2", x, y) end
function vec.floor(v) return vec.v2(math.floor(v.x), math.floor(v.y)) end
function vec.unit() return vec.v2(1, 1) end
function vec.normalize(v) return rl.Vector2Normalize(v) end
function vec.length(v) return rl.Vector2Length(v) end
function vec.rotate(v, angle) return rl.Vector2Rotate(v, angle) end
function vec.pow2(v) return vec.v2(math.pow(v.x, 2), math.pow(v.y, 2)) end
function vec.clamp(v, a, b) return vec.v2(util.clamp(v.x, a.x, b.x), util.clamp(v.y, a.y, b.y)) end

return vec
