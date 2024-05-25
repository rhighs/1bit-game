local textures = {}

function textures.load()
    textures.ghost      = rl.LoadTexture("assets/ghost.png")
    textures.arm        = rl.LoadTexture("assets/ghost-arm.png")
    textures.chain_ball = rl.LoadTexture("assets/spike-ball.png")
    textures.chain      = rl.LoadTexture("assets/chain.png")
    textures.spider     = rl.LoadTexture("assets/spider.png")
end

return textures
