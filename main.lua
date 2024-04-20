local util = require("util")
local player = require("player")
local color = require("color")
local camera = require("camera")
local vec = require "vec"
local level_loader = require "level_loader"
local start_screen_controller = require "start-screen-controller"
local level_scene = require "level-scene"
local physics = require("physics")
local game_over = require "game-over-scene"

local VP_WIDTH, VP_HEIGHT = 800, 450
local VP = vec.v2(VP_WIDTH, VP_HEIGHT)

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(VP.x, VP.y, "1bit ghost house")
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
