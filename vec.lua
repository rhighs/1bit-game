local vec = {}

function vec.v2(x, y) return rl.new("Vector2", x, y) end
function vec.fmt(v) return "(" .. v.x .. ", " .. v.y .. ")" end

return vec
