local Clickable = require "app.gui.clickable"

local function MediaPlayButton(state, onclick)
    local self = { }

    local clickable = Clickable(function()
        onclick(state)
    end)

    self.draw = function(self, w, h)
        local width = 25
        local height = 30
        local padding_w = w - width
        local padding_h = h - height

        love.graphics.push()
        clickable:draw(width + padding_w, height + padding_h)
        love.graphics.translate(padding_w / 2, padding_h / 2)

        if state.paused == true then
            love.graphics.polygon("fill", { 5,0, 5,30, 10,30 })
            love.graphics.polygon("fill", { 15,0, 15,30, 20,30 })
            love.graphics.polygon("fill", { 15,0, 20,30, 20,0 })
            love.graphics.polygon("fill", { 5,0, 10,30, 10,0 })
        else
            love.graphics.polygon("fill", { 25,15, -0,30, -0,0 })
        end
        love.graphics.pop()
    end

    return self
end
local function MediaPrevButton(onclick)
    local self = { }

    local clickable = Clickable(onclick)

    self.draw = function(self, w, h)
        local width = 25
        local height = 30
        local padding_w = w - width
        local padding_h = h - height

        love.graphics.push()
        clickable:draw(width + padding_w, height + padding_h)
        love.graphics.translate(padding_w / 2, padding_h / 2)

        love.graphics.polygon("fill", { 5,15, 25,30, 25,0 })
        love.graphics.polygon("fill", { 0,0, 0,30, 5,30 })
        love.graphics.polygon("fill", { 0,0, 5,30, 5,0 })

        love.graphics.pop()
    end

    return self
end
local function MediaNextButton(onclick)
    local self = { }

    local clickable = Clickable(onclick)

    self.draw = function(self, w, h)
        local width = 25
        local height = 30
        local padding_w = w - width
        local padding_h = h - height

        love.graphics.push()
        clickable:draw(width + padding_w, height + padding_h)
        love.graphics.translate(padding_w / 2, padding_h / 2)
        
        love.graphics.polygon("fill", { 20,15, 0,30, 0,0 })
        love.graphics.polygon("fill", { 25,0, 25,30, 20,30 })
        love.graphics.polygon("fill", { 25,0, 20,30, 20,0 })

        love.graphics.pop()
    end

    return self
end

return {
    PlayButton = MediaPlayButton,
    NextButton = MediaNextButton,
    PrevButton = MediaPrevButton
}