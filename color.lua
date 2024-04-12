local color = {
    COLOR_PRIMARY = rl.WHITE,
    COLOR_SECONDARY = rl.BLACK,
}

function color.swap_color()
    color.COLOR_PRIMARY, color.COLOR_SECONDARY = color.COLOR_SECONDARY, color.COLOR_PRIMARY
end

return color
