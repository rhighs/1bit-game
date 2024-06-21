require "table-ext"
local consts = require "consts"
local color = require "color"
local util = require "util"
local vec = require "vec"
local start_screen_controller = require "start-screen-controller"
local level_scene = require "level-scene"
local game_over = require "game-over-scene"
local level_completed = require "level-completed-scene"
local player = require "player"
local textures = require "textures"
local event_queue = require "event_queue"

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(consts.VP_WIDTH, consts.VP_HEIGHT, "1bit ghost house")
rl.SetTargetFPS(60)
textures.load()
player.load_textures()

local scene_events = event_queue.new()
local scenes = {
    list = {
        ["start"] = start_screen_controller.new(scene_events),
        ["level"] = level_scene.new(scene_events),
        ["levelcompleted"] = level_completed.new(scene_events, 1.0),
        ["gameover"] = game_over.new(scene_events, 1.0)
    },
    cur = "start",

    get = function(self) return self.list[self.cur] end
}

while not rl.WindowShouldClose() do
    local dt = rl.GetFrameTime()

    scenes:get():update(dt)

    local ev = scene_events:recv()
    if ev ~= nil then
        scenes:get():destroy()
        if ev.name == "/quit" then
            GAME_LOG("/quit received...")
            break
        end

        scenes.cur = ev.name
        scenes:get():init(ev.data)
    end

	rl.BeginDrawing()
	rl.ClearBackground(color.COLOR_SECONDARY)
    rl.DrawFPS(10, 10)
    scenes:get():draw(dt)

	rl.EndDrawing()
end

rl.CloseWindow()
