local table = {}

function table.contains(t, callable)
    for k, v in pairs(t) do
        if callable(v) then
            return true
        end
    end
    return false
end

return table