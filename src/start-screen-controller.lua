local util = require "util"
local consts = require "consts"
local vec = require "vec"
local gui = require "gui"
local cooldown = require "cooldown"

local start_screen = {}

function start_screen:init() end
function start_screen:destroy() end

function start_screen:update(dt)
    if self.counter == 50 then
        self.counter = 0
    end

    if rl.IsKeyDown(rl.KEY_UP) then
        self:options_up()
    end
    if rl.IsKeyDown(rl.KEY_DOWN) then
        self:options_down()
    end

    if rl.IsKeyDown(rl.KEY_ENTER) then
        self:options_callback()
    end

    self.counter = self.counter + 1
    self.options_container:update(dt)
end

function start_screen:draw_options() end

function start_screen:draw()
    local width = rl.MeasureText("GHOSTS", 92)
    rl.DrawText("GHOSTS", consts.VP_WIDTH/2 - width/2, 100, 92, rl.WHITE)
    self.options_container:draw()
end

function start_screen.new(scene_queue)
    start_screen.__index = start_screen

    local obj = {
        name = "start",
        cursor = rl.LoadTexture("assets/cursor.png"),
        counter = 0,
        scene_queue = scene_queue,

        options_up = cooldown.make_cooled(function (self)
            self.options_container.child:previous()
        end, 0.1),

        options_down = cooldown.make_cooled(function (self)
            self.options_container.child:next()
        end, 0.1),

        options_callback = cooldown.make_cooled(function (self)
            self.options_container.child:call_current()
        end, 0.5)
    }

    obj.options_container = gui.new_container(
        util.Rec(0, consts.VP_HEIGHT/2, consts.VP_WIDTH, consts.VP_HEIGHT/2),
        gui.new_menu_list_container(
            util.Rec(0, 0, 100, 50),
            {
                {
                    label = "START",
                    callback = function ()
                        GAME_LOG("starting level...")
                        obj.scene_queue:send({ name = "level", data = { level = "leveldata/level3" } })
                    end,
                },
                {
                    label = "OPTIONS",
                    callback = function () GAME_LOG("options unimplemented") end,
                },
                {
                    label = "QUIT",
                    callback = function ()
                        GAME_LOG("quitting game...")
                        obj.scene_queue:send({ name = "/quit" })
                    end,
                },
            }
        ),
        true
    )

    return setmetatable(obj, start_screen)
end

return start_screen
