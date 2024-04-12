local vec = {}

function vec.v2(x, y) return rl.new("Vector2", x, y) end
function vec.floor(v) return vec.v2(math.floor(v.x), math.floor(v.y)) end

return vec
