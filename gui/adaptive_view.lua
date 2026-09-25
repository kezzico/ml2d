local function AdaptiveView(state)
    local self = { }
    local state = state or { }
    state.portrait = state.portrait or View { }
    state.landscape = state.landscape or View { }

    self.draw = function(self, w, h)
        local viewport_w, viewport_h = love.graphics.getDimensions()
        
        if viewport_h > viewport_w then
            state.portrait:draw(w, h)
        else
            state.landscape:draw(w, h)
        end
    end
    return self
end

return AdaptiveView