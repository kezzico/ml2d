local View = require "ml2d.gui.view"
local TextView = require "ml2d.gui.text_view"

local function SafeAreaView(state_and_children)
    local self = { }
    local text_state = { text = "" }
    local diag = TextView(text_state)
    function self:draw(w, h)
        local frame = love.graphics.transformPoint(0, 0)
        local sx, sy, sw, sh = love.window.getSafeArea()
        
        -- sx = math.max(sx, frame)
        -- print(sx, sy, sw, sh)
       
        love.graphics.translate(sx, sy)
        
        for i = 1, #state_and_children do
            local child = state_and_children[i]
            child:draw(sw - sx, sw - sx)
        end

        text_state.text = string.mush("--", "sx", sx, "sy", sy, "sw", sw, "sh", sh)
        diag:draw(w, h)
    end
    return View(state_and_children, { self })
end

return SafeAreaView