local _, styles = pcall(require, 'app.styles')
local HamburgerButton = require("ml2d.gui.hamburger_button")
local eval_units = require("ml2d.gui.eval_units")

local function HamburgerMenu(style_menu_main, menu, main_view)
    menu = menu or style_menu_main[1]
    main_view = main_view or style_menu_main[2]

    local self = {}
    local style = {}

    style.friction = style_menu_main.friction or 6
    style.backgroundColor = style_menu_main.backgroundColor or hexToColor(0xFF0000, 1.0)
    style.width = style_menu_main.width or "70%"

    -- a state tree perhaps?
    local state = {
        offset_x = 0,
        velocity = 1,
        dragging = false,
        menu_width = eval_units(style.width, love.graphics.getWidth( )),
        last_drag_time = 0
    }

    local button = HamburgerButton(function()
        if state.offset_x > 0 then
            -- close
            state.velocity = state.offset_x * style.friction * -1.25
        else
            -- open
            local remaining = state.menu_width - state.offset_x
            state.velocity = remaining * style.friction * 1.25
        end
    end)

    self.close = function(self, animated)
        if animated then 
            state.velocity = state.offset_x * style.friction * -1.25
        else
            state.offset_x = 0
        end
    end

    self.open = function(self, animated)
        if animated then 
            local remaining = state.menu_width - state.offset_x
            state.velocity = remaining * style.friction * 1.25
        else
            state.offset_x = state.menu_width
        end
    end

    self.hit = function(self, x, y)
        -- return true
      local w, h = love.graphics.getDimensions()
      return state.dragging == true or x < w * 0.2 or state.offset_x > 0
    end

    self.ondrag = function(self, dx, dy)
        local now = love.timer.getTime()
        local dt = now - state.last_drag_time

        local next_x = state.offset_x + dx

        if next_x > state.menu_width then
            local overscroll = next_x - state.menu_width

            dx = dx / (1 + overscroll * 0.01)
        end

        state.offset_x = state.offset_x + dx

        if dt > 0 then
            state.velocity = dx / dt
        end

        state.last_drag_time = now
        state.dragging = true
    end

    self.onrelease = function(self, x, y)
        state.dragging = false
    end

    self.update = function(self, dt)
        state.offset_x = math.max(0, state.offset_x)

        local max_velocity = state.menu_width * style.friction * 1.25

        if state.velocity > 0 then
            state.velocity = math.min(max_velocity, state.velocity)
        elseif state.velocity < 0 then
            state.velocity = math.max(max_velocity * -1, state.velocity)
        end

        if state.dragging == false then
            local target = (state.offset_x > state.menu_width / 2) and state.menu_width or 0

            local stiffness = 20
            local damping = style.friction

            local displacement = target - state.offset_x

            state.velocity = state.velocity + displacement * stiffness * dt
            state.velocity = state.velocity * math.exp(-damping * dt)

            state.offset_x = state.offset_x + state.velocity * dt
        end
    end

    self.draw = function(self, w, h)
        state.menu_width = eval_units(style.width, w)

        main_view:draw(w, h)

        love.graphics.push()
        love.graphics.translate((w - state.menu_width) - w, 0)
        love.graphics.translate(state.offset_x, 0)
        love.graphics.push("all")
        love.graphics.setColor(style.backgroundColor)
        love.graphics.rectangle("fill", -state.offset_x, 0, state.menu_width + state.offset_x, h)
        love.graphics.pop()

        if state.offset_x > 0 then
            clickables = { }
        end

        -- table.insert(draggables, self)
        table.insert(clickables, self)

        menu:draw(state.menu_width, h)
        love.graphics.pop()

        love.graphics.push()
        
        love.graphics.translate(22, 22)
        button:draw(44, 44)
        love.graphics.pop()

        table.insert(updateables, self)

        
    end

    self.id = "hamburger"

    return self
end

return HamburgerMenu
