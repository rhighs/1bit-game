local textures = {}

function textures.load()
    textures.ghost      = rl.LoadTexture("assets/ghost.png")
    textures.arm        = rl.LoadTexture("assets/ghost-arm.png")
    textures.spike_ball = rl.LoadTexture("assets/spike-ball.png")
    textures.chain      = rl.LoadTexture("assets/chain.png")
end

return textures
