local util = require("util")
local player = require("player")
local color = require("color")
local ghost = require("ghost")
local camera = require("camera")
local vec = require "vec"

local physics = require("physics")

local VP_WIDTH, VP_HEIGHT = 800, 450

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)
rl.InitWindow(VP_WIDTH, VP_HEIGHT, "1bit ghost house")
rl.SetTargetFPS(60)

-- rl.InitPhysics()
-- rl.SetPhysicsGravity(0.0, 1.0)

-- local floor = rl.CreatePhysicsBodyRectangle(vec.v2(VP_WIDTH/2, VP_HEIGHT/2), 500, 20, 10)
-- floor.enabled = false

local cam = camera.new()
local p = player.new(vec.v2(VP_WIDTH/2, 0))
local g = ghost.new(vec.v2(VP_WIDTH/2 + 100, 0))

local physics_instance = physics.new(vec.v2(0.0, 1000))
physics_instance:add(p.body)
-- physics_instance:add(g.body)

local last_color_swap = 0.0
while not rl.WindowShouldClose() do
    local dt = rl.GetFrameTime()

    physics_instance:update(dt)
    p:update(dt)
    g:update(dt)
    g:set_target(p:position())

    p:wrap_y(0, VP_HEIGHT)
    last_color_swap = last_color_swap + rl.GetFrameTime()

	rl.BeginDrawing()
	rl.ClearBackground(color.COLOR_SECONDARY)

    p:draw(dt)
    g:draw(dt)

    if rl.IsKeyDown(rl.KEY_T) and last_color_swap > 0.2 then
        color.swap_color()
        last_color_swap = 0.0
    end

    bodiesCount = rl.GetPhysicsBodiesCount()
    for i=0,bodiesCount-1 do
      local body = rl.GetPhysicsBody(i)

      if body ~= nil then
        local vertexCount = rl.GetPhysicsShapeVerticesCount(i)
        for j=0,vertexCount-1 do
          local vertexA = rl.GetPhysicsShapeVertex(body, j);

          local jj = ((j + 1) < vertexCount) and (j + 1) or 0
          local vertexB = rl.GetPhysicsShapeVertex(body, jj);

          rl.DrawLineV(vertexA, vertexB, color.COLOR_PRIMARY)
        end
      end
    end

	rl.EndDrawing()
end

rl.ClosePhysics()
rl.CloseWindow()
