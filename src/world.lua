local ffi = require "ffi"
local consts = require "consts"
local util = require "util"
local player_lib = require "player"
local loader = require "loader"
local camera = require "camera"
local color = require "color"
local vec = require "vec"
local physics = require "physics"
local start_screen = require "start-screen-controller"
local cooldown = require "cooldown"
local entity = require "entity"

local world_lib = {}

world_lib.DRAW_PHYSICS = false

function world_lib.new(data, scene_queue)
    local shader_source = [[
#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec3 onWhiteColor;
uniform vec3 onBlackColor;
uniform float lightness; // 0.0..1.0

bool isBlack(vec4 c) {
    return c.x == 0 && c.y == 0 && c.z == 0;
}

vec4 mapColor(vec4 color) {
    return mix(
        vec4(0, 0, 0, 0),
        vec4(lightness, lightness, lightness, 1),
        vec4(isBlack(color) ? onBlackColor.xyz : onWhiteColor.xyz, color.w)
    );
}

void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    finalColor = mapColor(texelColor * colDiffuse * fragColor);
}
]]

    local shader = rl.LoadShaderFromMemory(nil, shader_source)
    local on_white_color_loc = rl.GetShaderLocation(shader, "onWhiteColor")
    local on_black_color_loc = rl.GetShaderLocation(shader, "onBlackColor")

    local world = {
        player = player_lib.new(data.level_start),
        entities = {},
        cam = camera.new(consts.VP, vec.v2(0, 0)),
        bounds = data.level_bounds,
        ground = data.ground,
        decor = data.decor,
        scene_queue = scene_queue,
        mode = 'normal',
        warp = {
            pos = nil,
            fade_light = 1.0,
            step = -0.05
        }
    }

    physics.register_body(world.player.body)

    function world:check_player_bounds(bounds)
        return rl.CheckCollisionCircleRec(self.player:position(), self.player.body.radius, bounds)
    end

    function world:set_palette(black, white)
        black = rl.ColorNormalize(black)
        white = rl.ColorNormalize(white)
        local b = ffi.new "float [3]"
        local w = ffi.new "float [3]"
        b[0], b[1], b[2] = black.x, black.y, black.z
        w[0], w[1], w[2] = white.x, white.y, white.z
        rl.SetShaderValue(shader, on_black_color_loc, b, rl.SHADER_UNIFORM_VEC3)
        rl.SetShaderValue(shader, on_white_color_loc, w, rl.SHADER_UNIFORM_VEC3)
    end

    function world:set_lightness(value)
        local lightness = ffi.new "float [1]"
        lightness[0] = value
        rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "lightness"), lightness, rl.SHADER_UNIFORM_FLOAT)
    end

    world:set_palette(rl.BLACK, rl.WHITE)
    world:set_lightness(1.0)

    function world:normal_update(dt)
        if not self:check_player_bounds(self.bounds) then
            self.scene_queue:send({ name = "gameover" })
            return
        end

        local old_cam = self.cam:clone()
        local level_size = vec.v2(self.bounds.width, self.bounds.height)
        self.cam:retarget(vec.clamp(
            self.player:position(),
            self.bounds + consts.VP/2,
            self.bounds + level_size - consts.VP/2
        ))

        -- despawn entities when they stay off-screen for too much time
        -- or if they've fallen inside pits
        local to_despawn = table.map(
            table.filter(self.entities, function (e)
                local p = e:get_draw_box()
                return not e.keepalive and (e.offscreen_start >= 400
                    or p.y > self.bounds.y + self.bounds.height)
            end),
            function (e) return e.id end
        )
        for _, id in ipairs(to_despawn) do
            -- GAME_LOG("despawning entity with id =", id)
            if self.entities[id].on_despawn ~= nil then
                self.entities[id]:on_despawn()
            end
            if self.entities[id].body ~= nil then
                physics.unregister_body(self.entities[id].body)
            end
            self.entities[id] = nil
        end

        -- spawn new entities when they come inside the camera
        local new_entities = table.filter(
            data.entities,
            function (e)
                return self.entities[e.id] == nil
                   and self.cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
                   and not old_cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
            end
        )
        for _, e in ipairs(new_entities) do
            -- GAME_LOG("spawning new entity with id =", e.id)
            local entt = entity.create_new(self, e)
            self.entities[e.id] = entt
            if entt.body ~= nil then
                physics.register_body(entt.body)
            end
        end

        for _, e in pairs(self.entities) do
            e:update(dt)
            e.offscreen_start = self.cam:is_inside(e:get_draw_box()) and -1 or e.offscreen_start + 1
            if self:check_player_bounds(e:get_hitbox()) then
                e:player_collision(self.player:position())
            end
        end

        self.player:update(dt)
        physics.check_collisions(self.ground, physics.bodies, dt)
    end

    function world:warp_mode_update(dt)
        self.warp.fade_light = self.warp.fade_light + self.warp.step
        if self.warp.fade_light < 0 and self.warp.step < 0 then
            self.warp.step = -self.warp.step
            self:set_lightness(0)
            self.player:set_position(self.warp.pos)
            self:normal_update(dt)
            self.warp.pos = nil
        elseif self.warp.fade_light > 1.0 and self.warp.step > 0 then
            self.warp.step = -self.warp.step
            self.mode = 'normal'
        else
            self:set_lightness(self.warp.fade_light)
        end
    end

    function world:update(dt)
            if self.mode == 'warp'   then self:warp_mode_update(dt)
        elseif self.mode == 'normal' then self:normal_update(dt)
        else error('invalid mode: ' .. self.mode) end
    end

    function world:draw_hud(dt)
        rl.DrawRectangle(0, 0, consts.VP_WIDTH, 50, rl.BLACK)
        -- player torch status
        local torch_bar_length = consts.VP_WIDTH / 3
        local text = "TORCH [T] "
        local text_height = 18
        local text_width = rl.MeasureText(text, text_height)
        rl.DrawText(text, 10, 10, text_height, rl.WHITE)
        local bar_x = 20 + text_width
        rl.DrawRectangleLines(bar_x, 10, torch_bar_length, text_height, rl.WHITE)
        rl.DrawRectangle(bar_x, 10, torch_bar_length * (self.player.torch_battery/100.0), text_height, rl.WHITE)
    end

    function world:draw_at(grid, x, y)
        local tile_info = grid[y][x]
        if tile_info == nil then
            return
        end

        -- rob: hide platform paths
        if tile_info.properties ~= nil and
        (tile_info.properties.ppath_point or tile_info.properties.ppath_decor) then
            return
        end

        local texture = data.textures[tile_info.gid]
        if texture == nil then
            error(util.pystr("trying to draw tex id =", tile_info.gid, "at pos = (", x, y, ")"))
        end

        local rotation = 0.0
        local origin = vec.v2(texture.width, texture.height)/2
        local source_rec = util.Rec(0, 0, texture.width, texture.height)
        local y_offset = texture.height/32 - 1
        local dest_rec = util.Rec(
            x           *32 + origin.x,
            (y-y_offset)*32 + origin.y,
            texture.width, texture.height
        )

        local flip_diag, flip_vert, flip_horz =
            tile_info.flip_diag, tile_info.flip_vert, tile_info.flip_horz

        if flip_diag and flip_vert and flip_horz then
            source_rec.width = -source_rec.width
            rotation = 90.0
        elseif flip_diag and flip_vert then
            rotation = -90.0
        elseif flip_diag and flip_horz then
            rotation = 90.0
        elseif flip_vert and flip_horz then
            rotation = 180.0
        elseif flip_diag then
            source_rec.height = -source_rec.height
            rotation = 90.0
        elseif flip_vert then
            source_rec.height = -source_rec.height
        elseif flip_horz then
            source_rec.width = -source_rec.width
        end

        rl.DrawTexturePro(
            texture,
            source_rec,
            dest_rec,
            origin,
            rotation,
            rl.WHITE
        )
    end

    function world:draw_grid(grid)
        -- draw two tiles over the screen bounds to permit 96x96 tiles
        local tl = vec.floor(self.cam:top_left_world_pos() / 32) - vec.v2(2, 2)
        local br = vec.floor(self.cam:bottom_right_world_pos() / 32) + vec.v2(2, 2)
        for y = tl.y, br.y do
            if grid[y] ~= nil then
                for x = tl.x, br.x do
                    self:draw_at(grid, x, y)
                end
            end
        end
    end

    function world:draw()
        rl.BeginShaderMode(shader)
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(self.cam:get())
        self:draw_grid(self.decor)
        self.player:draw(dt)
        self:draw_grid(self.ground)

        for _, e in pairs(self.entities) do
            if self.cam:is_inside(e:get_draw_box()) then
                e:draw()
                if self.debug_mode then
                    e:draw_debug()
                end
            end
        end

        if world_lib.DRAW_PHYSICS then
            for _, b in pairs(physics.bodies) do
                if b.__shape == "circle" then
                    rl.DrawCircleLines(b.position.x, b.position.y, b.radius, rl.RED)
                elseif b.__shape == "rectangle" then
                    rl.DrawRectangleLines(b.position.x, b.position.y, b.width, b.height, rl.RED)
                end

                vec.draw(b.velocity, b.position)
                if b.platform_velocity then
                    vec.draw(b.platform_velocity, b.position, rl.BLUE)
                end
            end
        end
        rl.EndMode2D()

        self:draw_hud(dt)
        rl.EndShaderMode()
    end

    -- public api functions:
    function world:spawn(data)
        local new_id = #self.entities + 1
        data.id = new_id
        local entt = entity.create_new(self, data)
        self.entities[new_id] = entt
        if entt.body ~= nil then
            physics.register_body(entt.body)
        end
    end

    function world:destroy()
        rl.UnloadShader(self.shader)
    end

    function world:send_scene_event(name)
        self.scene_queue:send({ name = name })
    end

    function world:warp_to(name)
        local warp = table.find(data.entities, function (e) return e.data.warp_name == name end)
        if warp == nil then
            print("WARNING: no warp found: " .. name)
            return
        end
        self.warp.pos = vec.v2(warp.pos.x + warp.width/2, warp.pos.y + warp.height) - vec.v2(16, 32)
        self.mode = 'warp'
    end

    return world
end

return world_lib
