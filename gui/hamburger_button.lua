local Clickable = require "app.gui.clickable"
local styles = require "app.styles"

local function HamburgerButton(onclick)
    local self = { }

    local clickable = Clickable(onclick, { })

    self.draw = function(self, w, h)
        local padding = h * 1/3

        love.graphics.push()
        -- translate to center hamburger vertically
        love.graphics.translate(0, h * 1/12)

        -- push all to include shadow color
        love.graphics.push("all")        
        love.graphics.translate(0, h*1/18)
        love.graphics.setColor(styles.colors.shadow)
        
        for i = 0, 2 do
            love.graphics.rectangle("fill", 
                0, 0 + i * h * 1/3, 
                h, h * 1/9)
        end
        love.graphics.pop()

        -- pop back and draw the hamburger stripes
        love.graphics.push("all")        
        love.graphics.setColor(styles.colors.text)

        for i = 0, 2 do
            love.graphics.rectangle("fill", 0, 
                0 + i * h * 1/3, 
                h, h * 1/9)
        end
        love.graphics.pop()
        -- pop again for the vertical centering
        love.graphics.pop()


        love.graphics.push()
        love.graphics.translate(-padding, -padding)
        -- intentially made to be a square h x h
        clickable:draw(h + padding*2, h + padding*2)
        love.graphics.pop()
    end
    return self
end

return HamburgerButton