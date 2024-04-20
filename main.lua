local consts = require "consts"
local color = require "color"
local util = require "util"
local vec = require "vec"
local start_screen_controller = require "start-screen-controller"
local level_scene = require "level-scene"
local game_over = require "game-over-scene"

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(consts.VP_WIDTH, consts.VP_HEIGHT, "1bit ghost house")
rl.SetTargetFPS(60)

local scenes = {
    list = {
        ["start"] = start_screen_controller.new(),
        ["level"] = level_scene.new(),
        ["gameover"] = game_over.new()
    },
    cur = "start",

    get = function(self) return self.list[self.cur] end
}

while not rl.WindowShouldClose() do
    local dt = rl.GetFrameTime()

    scenes:get():update(dt)
    next_scene = scenes:get():should_change()
    if next_scene ~= nil then
        scenes.cur = next_scene.name
        scenes:get():init(next_scene.data)
    end

	rl.BeginDrawing()
	rl.ClearBackground(color.COLOR_SECONDARY)
    rl.DrawFPS(10, 10)

    scenes:get():draw()

	rl.EndDrawing()
end

rl.ClosePhysics()
rl.CloseWindow()
