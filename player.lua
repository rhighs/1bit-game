local util = require "util"
local vec = require "vec"
local physics = require "physics"
local cycle = require "cycle"
local consts = require "consts"
local cooldown = require "cooldown"
local color = require "color"

local player_lib = {}

local player = {}

local PLAYER_BODY_DENSITY = 1
local PLAYER_BODY_RADIUS = 10
local PLAYER_JUMP_HEIGHT = physics.METER_UNIT * 3.5

local PLAYER_STATE_IDLE = 0
local PLAYER_STATE_RUNNING = 1
local PLAYER_STATE_JUMPING = 2

local TORCH_DISCHARGE_RATE = 1
local TORCH_CHARGE_RATE = 0
local TORCH_MAX_LENGTH = 200

local state_tostring = {
    [PLAYER_STATE_IDLE] = "PLAYER_STATE_IDLE",
    [PLAYER_STATE_RUNNING] = "PLAYER_STATE_RUNNING",
    [PLAYER_STATE_JUMPING] = "PLAYER_STATE_JUMPING"
}

local IDLE_CYCLE_INTERVAL = 0.5
local RUNNING_CYCLE_INTERVAL = 0.1
local JUMPING_CYCLE_INTERVAL = 1000

function player_lib.load_textures()
    player_lib.TEXTURES = {
        IDLE = {
            [1] = rl.LoadTexture("assets/idle1.png"),
            [2] = rl.LoadTexture("assets/idle2.png"),
        },
        RUNNING = {
            [1] = rl.LoadTexture("assets/running1.png"),
            [2] = rl.LoadTexture("assets/running2.png"),
            [3] = rl.LoadTexture("assets/running3.png"),
        },
        JUMPING = {
            [1] = rl.LoadTexture("assets/running1.png"),
        }
    }
end

function player:handle_movement()
    local x_dir, y_dir = self:dir()
    self.facing_dir.y = y_dir
    self.body.air_resistance_enabled = (x_dir == 0)
    if x_dir ~= 0 then
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
    if should_jump and self.body.grounded and self.body.velocity.y >= 0 then
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
        if self.body.grounded then
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
        util.pyprint("player colliding with =", self.body.colliders)
    end
end

function player:update(dt)
    local old_state = self.state

    self:update_state()
    self:collisions_update(dt)
    self:update_torch(dt)
    self.texture_cycle:update(dt)

    if rl.IsKeyDown(rl.KEY_T) then
        self:toggle_torch()
    end

    local new_state = self.state

    if old_state ~= new_state then
        if new_state == PLAYER_STATE_IDLE then
            self.textures = player_lib.TEXTURES.IDLE
            self.texture_cycle = cycle.new(1, #self.textures, IDLE_CYCLE_INTERVAL)
        elseif new_state == PLAYER_STATE_RUNNING then
            self.textures = player_lib.TEXTURES.RUNNING
            self.texture_cycle = cycle.new(1, #self.textures, RUNNING_CYCLE_INTERVAL)
        elseif new_state == PLAYER_STATE_JUMPING then
            self.textures = player_lib.TEXTURES.JUMPING
            self.texture_cycle = cycle.new(1, #self.textures, JUMPING_CYCLE_INTERVAL)
        end
    end
end

function player:draw(dt)
    local texture = self:current_texture()
    local position = self:position()
    position = vec.v2(position.x - texture.width/2, position.y - texture.height/2)

    local x_dir = self:dir()
    local src_rec = util.Rec(0, 0, texture.width * self.facing_dir.x, texture.height)
    local dst_rec = util.Rec(position.x, position.y, texture.width, texture.height)

    if self.torch then
        self:draw_torch(dt)
    end

    rl.DrawTexturePro(texture, src_rec, dst_rec, vec.zero(), 0.0, rl.WHITE)
end

function player:draw_torch(dt)
    local x_dir, y_dir = self:dir()

    function draw_light_cone(cone_length, cone_color)
        local v1, v2, v3 =
            vec.v2(
                self.body.position.x + (self.body.radius * self.facing_dir.x),
                self.body.position.y
            ),
            vec.zero(),
            vec.zero()

        if x_dir == 0 and y_dir ~= 0 then
            v2 = v1 + (vec.normalize(vec.v2(-2, 3 * y_dir)) * cone_length)
            v3 = v1 + (vec.normalize(vec.v2(2, 3 * y_dir)) * cone_length)
            -- swapping for winding order...
            if y_dir == -1 then v2, v3 = v3, v2 end
        else
            v2 = v1 + (vec.normalize(vec.v2(3 * self.facing_dir.x, -2 + self.facing_dir.y * 3)) * cone_length)
            v3 = v1 + (vec.normalize(vec.v2(3 * self.facing_dir.x,  2 + self.facing_dir.y * 3)) * cone_length)
            -- swapping for winding order...
            if self.facing_dir.x == 1 then v2, v3 = v3, v2 end
        end
        rl.DrawTriangle(v1, v2, v3, cone_color)
    end

    function draw_torch_handle(handle_wh, handle_color)
        rl.DrawRectanglePro(
            util.Rec(
                self.body.position.x + self.body.radius,
                self.body.position.y,
                handle_wh.width,
                handle_wh.height,
                handle_color
            ),
            vec.v2(self.body.radius, handle_wh.height/2),
            math.deg(math.atan(y_dir, self.facing_dir.x)),
            handle_color
        )
    end

    draw_light_cone(TORCH_MAX_LENGTH, util.Color(255, 255, 255, (self.torch_battery / 100.0) * 255))
    draw_light_cone(TORCH_MAX_LENGTH * 0.1, color.COLOR_NEGATIVE)
    draw_torch_handle({ width = 10, height = 5 }, color.COLOR_POSITIVE)
end

function player:dir()
    local h_dir = (rl.IsKeyDown(rl.KEY_D) and 1 or 0) - (rl.IsKeyDown(rl.KEY_A) and 1 or 0)
    local v_dir = (rl.IsKeyDown(rl.KEY_S) and 1 or 0) - (rl.IsKeyDown(rl.KEY_W) and 1 or 0)
    return h_dir, v_dir
end

function player:position() return self.body.position end
function player:current_texture() return self.textures[self.texture_cycle:current()] end
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

    local init_textures = player_lib.TEXTURES.IDLE
    local body_radius = init_textures[1].height/2
    return setmetatable({
        speed = physics.METER_UNIT * 10,
        body = physics.new_circle(player_position, body_radius, PLAYER_BODY_DENSITY),
        facing_dir = vec.v2(1, 0),
        state = PLAYER_STATE_IDLE,
        textures = init_textures,
        texture_cycle = cycle.new(1, #init_textures, IDLE_CYCLE_INTERVAL),

        torch = false,
        toggle_torch = cooldown.make_cooled(function (self) self.torch = not self.torch end, 0.2),
        torch_battery = 100,
    }, player)
end

return player_lib
