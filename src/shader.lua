local util = require "util"

local shader = {}

function shader.create_fragment_shader()
    local source = [[
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

    local shader = {
        struct = rl.LoadShaderFromMemory(nil, source),
    }

    shader.locs = {
        on_white_color = rl.GetShaderLocation(shader.struct, "onWhiteColor"),
        on_black_color = rl.GetShaderLocation(shader.struct, "onBlackColor"),
        lightness      = rl.GetShaderLocation(shader.struct, "lightness")
    }

    function shader:get() return self.struct end
    function shader:unload()
        rl.UnloadShader(self.struct)
    end

    return setmetatable(shader, {
        __newindex = function (t, key, value)
            rl.SetShaderValue(shader.struct, shader.locs[key], value[1], value[2])
        end
    })
end

return shader
