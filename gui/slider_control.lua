local styles = require "app.styles"
local counter = 0

local function SliderControl(slider_state, onchange)
    local self = { }
    local frame = { x = 0, y = 0, w = 0, h = 0 }

    counter = counter + 1
    self.id = "slider-control-" .. counter

    self.hit = function(self, x, y)
      return 
        x >= frame.x and x <= frame.x + frame.w and 
        y >= frame.y and y <= frame.y + frame.h
    end

    self.onrelease = function(self, x, y)
        local v = math.floor(((x - frame.x) / frame.w) * 100) / 100
        v = math.max(v, 0)
        v = math.min(v, 1)

        if slider_state.value ~= v then
            slider_state.value = v
            onchange(v)
        end
    end

    self.ondrag = function(self, dx, dy, x, y)
        local v = math.floor(((x - frame.x) / frame.w) * 100) / 100
        v = math.max(v, 0)
        v = math.min(v, 1)
        
        if slider_state.value ~= v then
            slider_state.value = v
            onchange(v)
        end

        return true
    end

    self.draw = function(self, w , h)
        local lx, ly = love.graphics.transformPoint(0, 0)
        frame = { x = lx, y = ly, w = w, h = h }

        love.graphics.push("all")
        love.graphics.setColor(styles.sliders.blue.backgroundColor)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.pop()

        love.graphics.push("all")
        love.graphics.setColor(styles.sliders.blue.color)
        -- love.graphics.translate(slider_state.value * w, 0)
        love.graphics.rectangle("fill", 0, 0, slider_state.value * w, h)
        love.graphics.pop()

        table.insert(draggables, self)
        table.insert(clickables, self)
    end
    return self
end
return SliderControl