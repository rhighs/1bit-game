local vec = {}

local util = require "util"

function vec.zero() return rl.new("Vector2", 0, 0) end
function vec.v2(x, y) return rl.new("Vector2", x, y) end
function vec.floor(v) return vec.v2(math.floor(v.x), math.floor(v.y)) end
function vec.unit() return vec.v2(1, 1) end
function vec.distance(v1, v2) return rl.Vector2Distance(v1, v2) end
function vec.normalize(v) return rl.Vector2Normalize(v) end
function vec.length(v) return rl.Vector2Length(v) end
function vec.rotate(v, angle) return rl.Vector2Rotate(v, angle) end
function vec.dot(v1, v2) return rl.Vector2DotProduct(v1, v2) end
function vec.pow2(v) return vec.v2(math.pow(v.x, 2), math.pow(v.y, 2)) end
function vec.clamp(v, a, b) return vec.v2(util.clamp(v.x, a.x, b.x), util.clamp(v.y, a.y, b.y)) end
function vec.copy(v) return vec.v2(v.x, v.y) end

function vec.draw(v, o, c)
    o, c = o or vec.zero(), c or rl.RED
    local d, od = v, o + v
    local f = 10
    local nd = vec.normalize(d)
    local t_a = od + vec.rotate(nd, math.rad(90)) * f
    local t_b = od + vec.rotate(nd, math.rad(-90)) * f
    local t_c = od + nd * f*1.5
    local w, h = vec.length(d), 5
    local rec = util.Rec(o.x, o.y, w, h)
    rl.DrawRectanglePro(rec, vec.v2(0, h/2), math.deg(math.atan2(d.y, d.x)), c)
    rl.DrawTriangle(t_a, t_c, t_b, c)
end

return vec
