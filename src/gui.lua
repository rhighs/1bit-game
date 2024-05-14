local vec = require "vec"
local util = require "util"
local cycle = require "cycle"

local gui = {}

gui.DEBUG_WIREFRAME = false

function gui.draw_debug_wireframe(container, fill_color)
    if gui.DEBUG_WIREFRAME then
        if fill_color then
            rl.DrawRectangle(
                container.x, container.y,
                container.width, container.height,
                fill_color
            )
        end

        rl.DrawRectangleLines(
            container.x, container.y,
            container.width, container.height,
            rl.RED
        )
    end
end

local vlist_container = {}

function vlist_container:add_element(element)
    local elem_y = self.container.y + self.container.height + self.padding
    element:set_position(vec.v2(self.container.x, elem_y))
    table.insert(self.elements, element)
    self.container.height = self.container.height + element.container.height + self.padding
    self.container.width = math.max(element.container.width, self.container.width)
end

function vlist_container:get_position() return vec.v2(self.container.x, self.container.y) end
function vlist_container:set_position(pos)
    self.container.x, self.container.y = pos.x, pos.y
    local prev = 0
    for i, e in ipairs(self.elements) do
        e:set_position(vec.v2(pos.x, pos.y + prev))
        prev = prev + e.container.height + self.padding
    end
end

function vlist_container:update(dt)
    for i, e in ipairs(self.elements) do
        e:update(dt)
    end
end

function vlist_container:draw(dt)
    gui.draw_debug_wireframe(self.container)
    for i, e in ipairs(self.elements) do e:draw(dt) end
end

function gui.new_vlist_container(container_rec, padding, elements)
    vlist_container.__index = vlist_container
    local obj = setmetatable({
        container = container_rec,
        padding = padding,
        elements = {}
    }, vlist_container)
    for i, e in ipairs(elements) do obj:add_element(e) end
    return obj
end

local hlist_container = {}

function hlist_container:add_element(element)
    local elem_x = self.container.x + self.container.width + self.padding
    element:set_position(vec.v2(elem_x, self.container.y))
    table.insert(self.elements, element)
    self.container.width = self.container.width + element.container.width + self.padding
    self.container.height = math.max(element.container.height, self.container.height)
end

function hlist_container:get_position() return vec.v2(self.container.x, self.container.y) end
function hlist_container:set_position(pos)
    self.container.x, self.container.y = pos.x, pos.y
    local prev = 0
    for i, e in ipairs(self.elements) do
        e:set_position(vec.v2(pos.x + prev, pos.y))
        prev = prev + e.container.width + self.padding
    end
end

function hlist_container:update(dt)
    for i, e in ipairs(self.elements) do
        e:update(dt)
    end
end

function hlist_container:draw(dt)
    gui.draw_debug_wireframe(self.container, rl.BLUE)
    for i, e in ipairs(self.elements) do e:draw(dt) end
end

function gui.new_hlist_container(container_rec, padding, elements)
    hlist_container.__index = hlist_container
    local obj = setmetatable({
        container = container_rec,
        padding = padding,
        elements = {}
    }, hlist_container)
    for i, e in ipairs(elements) do obj:add_element(e) end
    return obj
end

local container = {}

function container:draw(dt)
    gui.draw_debug_wireframe(self.container)
    self.child:draw(dt)
end

function container:update(dt)
    self.child:update(dt)
    if self.center then
        local expected_position = vec.v2(
            self.container.x + self.container.width/2  - self.child.container.width/2,
            self.container.y + self.container.height/2  - self.child.container.height/2
        )

        local child_pos = self.child:get_position()
        if child_pos.x ~= expected_position.x or child_pos.y ~= expected_position.y then
            self.child:set_position(expected_position)
        end
    end
end

function container:get_position() return vec.v2(self.container.x, self.container.y) end
function container:set_position(pos)
    local diff = pos - vec.v2(self.container.x, self.container.y) 
    self.container.x, self.container.y = pos.x, pos.y
    self.child:set_position(self.child:get_position() + diff)
end

function gui.new_container(container_rec, child, center)
    container.__index = container
    return setmetatable({
        center = center,
        container = container_rec,
        child = child
    }, container)
end

local label_container = {}

function label_container:draw(dt)
    gui.draw_debug_wireframe(self.container, rl.GREEN)
    local text_width = rl.MeasureText(self.text, self.font_size)
    rl.DrawText(self.text,
        self.container.x + (self.container.width/2 - text_width/2), self.container.y,
        self.font_size, self.color
    )
end

function label_container:update(dt) end
function label_container:get_position() return vec.v2(self.container.x, self.container.y) end
function label_container:set_position(pos) self.container.x, self.container.y = pos.x, pos.y end

function gui.new_label_container(container_rec, text, color)
    label_container.__index = label_container
    return setmetatable({
        container = container_rec,
        text = text,
        color = color,
        font_size = 20
    }, label_container)
end

local texture_container = {}

function texture_container:draw(dt)
    gui.draw_debug_wireframe(self.container, rl.GRAY)
    if self.visible then
        rl.DrawTextureRec(
            self.texture,
            util.Rec(0, 0, self.texture.width, self.texture.height),
            vec.v2(self.container.x, self.container.y),
            rl.WHITE
        )
    end
end

function texture_container:update(dt) end
function texture_container:get_position() return vec.v2(self.container.x, self.container.y) end
function texture_container:set_position(pos) self.container.x, self.container.y = pos.x, pos.y end

function gui.new_texture_container(container_rec, texture, color)
    texture_container.__index = texture_container
    return setmetatable({
        container = container_rec,
        texture = texture,
        visible = false
    }, texture_container)
end

local menu_list_container = {}

function menu_list_container:draw(dt)
    gui.draw_debug_wireframe(self.container)
    self.vlist_container:draw(dt)
end

function menu_list_container:next()
    self.elements[self.active_option].container.elements[1].child.visible = false
    self.active_option = self.active_option == #self.elements and 1 or self.active_option + 1
    self.elements[self.active_option].container.elements[1].child.visible = true
end

function menu_list_container:previous()
    self.elements[self.active_option].container.elements[1].child.visible = false
    self.active_option = self.active_option == 1 and #self.elements or self.active_option - 1
    self.elements[self.active_option].container.elements[1].child.visible = true
end

function menu_list_container:update(dt)
    self.blink_cycle:update(dt)
    self.elements[self.active_option].container.elements[1].child.visible = self.blink_cycle:current() == 1
    self.vlist_container:update(dt)
end
function menu_list_container:get_position() return vec.v2(self.container.x, self.container.y) end
function menu_list_container:set_position(pos) 
    self.container.x, self.container.y = pos.x, pos.y
    self.vlist_container:set_position(pos)
end

function menu_list_container:call_current(...)
    return self.elements[self.active_option].callback(...)
end

function gui.new_menu_list_container(container_rec, actions)
    menu_list_container.__index = menu_list_container
    local elements = {}

    local cursor_texture = rl.LoadTexture("assets/cursor.png")
    for i, e in ipairs(actions) do
        table.insert(elements, {
            container = gui.new_hlist_container(
                util.Rec(0, 0, 0, 20),
                10,
                {
                    [1] = gui.new_container(
                        util.Rec(0, 0, container_rec.width * 0.2, 20),
                        gui.new_texture_container(util.Rec(0, 0, 20, 20), cursor_texture),
                        true
                    ),
                    [2] = gui.new_label_container(
                        util.Rec(0, 0, container_rec.width * 0.8, 20),
                        e.label,
                        rl.WHITE
                    )
                }
            ),
            callback = e.callback
        })
    end

    return setmetatable({
        container = container_rec,
        elements = elements,
        active_option = 1,
        vlist_container = gui.new_vlist_container(
            util.Rec(0, 0, container_rec.width, 0),
            2,
            table.map(elements, function (e) return e.container end)
        ),
        blink_cycle = cycle.new(0, 2, 0.5)
    }, menu_list_container)
end

return gui
