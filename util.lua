local ffi = require "ffi"

local util = {}

function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end
function util.sign(a) return a >= 0 and 1 or -1 end

return util
