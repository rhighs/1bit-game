local start_screen = {}

function start_screen.new()
    return {
        cursor = rl.LoadTexture("assets/cursor.png"),
        counter = 0,

        init = function (self) end,

        update = function (self)
            if self.counter == 50 then
                self.counter = 0
            end
            self.counter = self.counter + 1
        end,

        draw = function (self)
            width = rl.MeasureText("GHOSTS", 92)
            rl.DrawText("GHOSTS", 800/2 - width/2, 100, 92, rl.WHITE)
            width = rl.MeasureText("START", 20)
            rl.DrawText("START", 800/2 - width/2, 300, 20, rl.WHITE)
            if self.counter <= 25 then
                rl.DrawTexture(self.cursor, 800/2 - width/2 - 24, 300, rl.WHITE)
            end
        end,

        should_change = function (self)
            return rl.IsKeyDown(rl.KEY_ENTER)
            and { name = "level", data = { level = "leveldata/level3" } }
            or nil
        end
    }
end

return start_screen
