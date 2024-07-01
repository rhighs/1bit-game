local textures = {}

function textures.load()
    textures.gustshot   = rl.LoadTexture("assets/gustshot.png")
    textures.powerups   = rl.LoadTexture("assets/powerups.png")
    textures.player     = rl.LoadTexture("assets/player.png")
    textures.ghost      = rl.LoadTexture("assets/ghost.png")
    textures.arm        = rl.LoadTexture("assets/ghost-arm.png")
    textures.spider     = rl.LoadTexture("assets/spider.png")
    textures.candles    = rl.LoadTexture("assets/candles.png")
    textures.candle_ghost = rl.LoadTexture("assets/candle-ghost.png")
    textures.fireball   = rl.LoadTexture("assets/fireball.png")
    textures.platform   = rl.LoadTexture("assets/moving-platform.png")
end

return textures
