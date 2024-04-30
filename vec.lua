local vec = {}

function vec.zero() return rl.new("Vector2", 0, 0) end
function vec.v2(x, y) return rl.new("Vector2", x, y) end
function vec.floor(v) return vec.v2(math.floor(v.x), math.floor(v.y)) end
function vec.unit() return vec.v2(1, 1) end
function vec.normalize(v) return rl.Vector2Normalize(v) end
function vec.length(v) return rl.Vector2Length(v) end
function vec.rotate(v, angle) return rl.Vector2Rotate(v, angle) end

return vec
