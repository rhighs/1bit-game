local util = require "util"
local vec = require "vec"
local physics = require "physics"
local cycle = require "cycle"
local consts = require "consts"
local cooldown = require "cooldown"
local color = require "color"
local textures = require "textures"

local player_lib = {}

player_lib.DEBUG_DRAW = false
player_lib.DEBUG_STATE = false

local player = {}

local PLAYER_BODY_DENSITY = 1
local PLAYER_BODY_RADIUS = 10
local PLAYER_JUMP_HEIGHT = physics.METER_UNIT * 3.5

local TORCH_DISCHARGE_RATE = 1
local TORCH_CHARGE_RATE = 0
local TORCH_MAX_LENGTH = 200

local PLAYER_STATE_IDLE = 0
local PLAYER_STATE_RUNNING = 1
local PLAYER_STATE_JUMPING = 2

local state_tostring = {
    [PLAYER_STATE_IDLE] = "PLAYER_STATE_IDLE",
    [PLAYER_STATE_RUNNING] = "PLAYER_STATE_RUNNING",
    [PLAYER_STATE_JUMPING] = "PLAYER_STATE_JUMPING"
}

local IDLE_CYCLE_INTERVAL = 0.5
local RUNNING_CYCLE_INTERVAL = 0.1
local JUMPING_CYCLE_INTERVAL = 1000

function player:handle_movement()
    local x_dir, y_dir = self:dir()
    self.facing_dir.y = y_dir
    self.body.air_resistance_enabled = (x_dir == 0)

    if x_dir ~= 0 then
        -- rob: platform_velocity.x should not fight with user input
        if util.sign(self.body.platform_velocity.x) ~= x_dir then
            self.body.platform_velocity.x = 0
        end

        local v = vec.v2(x_dir * self.speed, y_dir * self.speed)
        self.body.velocity.x = v.x
        self.facing_dir.x = x_dir
        return true
    end

    if self.body.grounded then
        self.body.velocity.x = 0
    end

    return false
end

function player:handle_jumping()
    local should_jump = rl.IsKeyDown(rl.KEY_SPACE)
    if should_jump and ((self.body.grounded and self.body.velocity.y >= 0) or self.body.on_platform) then
        self.body.grounded = false
        self.body.on_platform = false
        self:jump()
        return true
    end
    return false
end

function player:update_state()
    if self.state == PLAYER_STATE_IDLE then
        local moving = self:handle_movement()
        local jumping = self:handle_jumping()
        if jumping then
            self.state = PLAYER_STATE_JUMPING
        elseif moving then
            self.state = PLAYER_STATE_RUNNING
        end
    elseif self.state == PLAYER_STATE_JUMPING then
        local moving = self:handle_movement()
        if self.body.grounded or self.body.on_platform then
            if math.abs(self.body.velocity.x) > 0 then
                self.state = PLAYER_STATE_RUNNING
            else
                self.state = PLAYER_STATE_IDLE
            end
        end
    elseif self.state == PLAYER_STATE_RUNNING then
        local moving = self:handle_movement()
        local jumping = self:handle_jumping()
        if jumping then
            self.state = PLAYER_STATE_JUMPING
        elseif moving then
            self.state = PLAYER_STATE_RUNNING
        else
            self.state = PLAYER_STATE_IDLE
        end
    end
end

function player:collisions_update()
    local n_colliding = #(self.body.colliders)
    if #(self.body.colliders) > 0 then
        -- GAME_LOG("player colliding with =", self.body.colliders)
    end
end

function player:update(dt)
    if player_lib.DEBUG_STATE then
        GAME_LOG("player state = " .. state_tostring[self.state])
    end
    local old_state = self.state

    self:update_state()
    self:collisions_update(dt)
    self:update_torch(dt)
    self.body:update(dt)

    if self.texture_cycle ~= nil then
        self.texture_cycle:update(dt)
    end

    if rl.IsKeyDown(rl.KEY_T) then
        self:toggle_torch()
    end

    local new_state = self.state
    if old_state ~= new_state then
        if new_state == PLAYER_STATE_IDLE then
            self.texture_cycle = cycle.new_values(
                { 0, 1 },
                IDLE_CYCLE_INTERVAL
            )
        elseif new_state == PLAYER_STATE_RUNNING then
            self.texture_cycle = cycle.new_values(
                { 2, 3, 4, 3 },
                RUNNING_CYCLE_INTERVAL
            )
        elseif new_state == PLAYER_STATE_JUMPING then
            self.texture_cycle = nil
        end
    end
end

function player:sprite_id()
    if self.state == PLAYER_STATE_JUMPING then
        return 2
    end
    return self.texture_cycle:current()
end

function player:draw(dt)
    local sprite_id = self:sprite_id()
    local texture = textures.player

    local position = self:position()
    position = vec.v2(position.x-16, position.y-16)

    local x_dir = self:dir()
    local src_rec = util.Rec(sprite_id * 32, 0, 32 * self.facing_dir.x, 32)
    local dst_rec = util.Rec(position.x, position.y, 32, 32)

    if self.torch then
        self:draw_torch(dt)
    end

    if player_lib.DEBUG_DRAW then
        rl.DrawCircleLines(self.body.position.x, self.body.position.y, self.body.radius, rl.RED)
    end

    rl.DrawTexturePro(texture, src_rec, dst_rec, vec.zero(), 0.0, rl.WHITE)
end

function player:draw_torch(dt)
    local x_dir, y_dir = self:dir()

    function draw_frustum(cone_near, cone_far, cone_color)
        local pivot, v2_near, v3_near, v2_far, v3_far =
            vec.v2(
                self.body.position.x + (self.body.radius * self.facing_dir.x),
                self.body.position.y
            ),
            vec.zero(),
            vec.zero(),
            vec.zero(),
            vec.zero()

        if x_dir == 0 and y_dir ~= 0 then
            local v2_dir = vec.normalize(vec.v2(-2, 3 * y_dir))
            local v3_dir = vec.normalize(vec.v2(2, 3 * y_dir))

            v2_near = pivot + (v2_dir * cone_near)
            v3_near = pivot + (v3_dir * cone_near)
            v2_far = pivot + (v2_dir * cone_far)
            v3_far = pivot + (v3_dir * cone_far)

            -- swapping for winding order...
            if y_dir == 1 then v2_far, v3_far, v2_near, v3_near = v3_far, v2_far, v3_near, v2_near end
        else
            local v2_dir = vec.normalize(vec.v2(3 * self.facing_dir.x, -2 + self.facing_dir.y * 3))
            local v3_dir = vec.normalize(vec.v2(3 * self.facing_dir.x,  2 + self.facing_dir.y * 3))

            v2_near = pivot + (v2_dir * cone_near)
            v3_near = pivot + (v3_dir * cone_near)
            v2_far = pivot + (v2_dir * cone_far)
            v3_far = pivot + (v3_dir * cone_far)

            v2_near = pivot + (v2_dir * cone_near)
            v3_near = pivot + (v3_dir * cone_near)
            v2_far = pivot + (v2_dir * cone_far)
            v3_far = pivot + (v3_dir * cone_far)

            -- swapping for winding order...
            if self.facing_dir.x == -1 then v2_far, v3_far, v2_near, v3_near = v3_far, v2_far, v3_near, v2_near end
        end

        rl.DrawTriangle(v2_near, v3_far, v2_far, cone_color)
        rl.DrawTriangle(v3_near, v3_far, v2_near, cone_color)
    end

    function draw_torch_handle(handle_wh, handle_color)
        local r, w, h = self.body.radius, handle_wh.width, handle_wh.height
        rl.DrawRectanglePro(
            util.Rec(
                self.body.position.x + r * self.facing_dir.x,
                self.body.position.y,
                w, h
            ),
            vec.v2(w/2, h/2),
            math.deg(math.atan2(y_dir, 1)) * self.facing_dir.x,
            handle_color
        )
    end

    draw_frustum(20, TORCH_MAX_LENGTH, util.Color(255, 255, 255, (self.torch_battery / 100.0) * 255))
    draw_torch_handle({ width = 10, height = 5 }, color.COLOR_POSITIVE)
end

function player:dir()
    local h_dir = (rl.IsKeyDown(rl.KEY_D) and 1 or 0) - (rl.IsKeyDown(rl.KEY_A) and 1 or 0)
    local v_dir = (rl.IsKeyDown(rl.KEY_S) and 1 or 0) - (rl.IsKeyDown(rl.KEY_W) and 1 or 0)
    return h_dir, v_dir
end

function player:position() return self.body.position end

function player:set_position(pos)
    self.body.position = pos + vec.v2(self.body.radius, self.body.radius)
end

function player:jump() self.body.velocity.y = -math.sqrt(self.body.gravity.y * 2 * PLAYER_JUMP_HEIGHT) end

function player:update_torch(dt)
    if self.torch_battery == 0 then
        self.torch = false
    end

    if self.torch and self.torch_battery >= 0 then
        self.torch_battery = self.torch_battery - (TORCH_DISCHARGE_RATE * dt)
    end

    if not self.torch and self.torch_battery < 100 then
        self.torch_battery = self.torch_battery + (TORCH_CHARGE_RATE * dt)
    end
end

function player_lib.new(player_position)
    player.__index = player

    local body_radius = 16
    local body = physics.new_circle(
        player_position - vec.v2(0, body_radius),
        body_radius,
        PLAYER_BODY_DENSITY
    )
    body.id = "player"
    return setmetatable({
        speed = physics.METER_UNIT * 10,
        body = body,
        facing_dir = vec.v2(1, 0),
        state = PLAYER_STATE_IDLE,
        texture_cycle = cycle.new_values({ 0, 1 }, IDLE_CYCLE_INTERVAL),

        torch = false,
        toggle_torch = cooldown.make_cooled(function (self) self.torch = not self.torch end, 0.2),
        torch_battery = 100,
    }, player)
end

return player_lib
