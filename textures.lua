local textures = {}

function textures.load()
    textures.ghost      = rl.LoadTexture("assets/ghost.png")
    textures.arm        = rl.LoadTexture("assets/ghost-arm.png")
    textures.spike_ball = rl.LoadTexture("assets/spike-ball.png")
    textures.chain      = rl.LoadTexture("assets/chain.png")
    textures.pend_bottom = rl.LoadTexture("assets/pendulum-bottom.png")
    textures.pend_middle = rl.LoadTexture("assets/pendulum-middle.png")
    textures.pend_orig = rl.LoadTexture("assets/pendulum-origin.png")
end

return textures
