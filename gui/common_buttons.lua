local TextView = require "ml2d.gui.text_view"
local Clickable = require "ml2d.gui.clickable"

local function BackButton()
	local go_back = function() navigator:pop()  end

	return Clickable(go_back, { 
		TextView("<", { size = 18, color = hexToColor(0xFFFFFF) })
	})
end

local function CloseButton()
	local reset = function() navigator:reset()  end

	return Clickable(reset, { 
		TextView("x", { size = 15, color = hexToColor(0xFFFFFF) })
	})
end

local function PlusButton(onclick)
	return Clickable(onclick, { 
		TextView("+", { size = 15, color = hexToColor(0xFFFFFF) })
	})
end


local function IconButton(icon, onclick)
  local self = { }
  local clickable = Clickable(onclick)
  local icon_height = icon:getWidth()

  self.draw = function(self, w, h)
    clickable:draw(w,h)
    love.graphics.draw(icon, 0, 0, 0, w/icon_height, h/icon_height)
  end

  return self
end

local function PlayButton(state, onclick)
  state = state or { paused = false}
  
  local self = { }
  local clickable = Clickable(onclick)

  local pause_icon = cache.image("assets/icons/pause.png")
  local play_icon = cache.image("assets/icons/play.png")
  local icon_height = play_icon:getWidth()

  self.draw = function(self, w, h)
    clickable:draw(w,h)
    -- print(">>>>>>>>>>", state.paused)
    if not state.paused then
      love.graphics.draw(pause_icon, 0, 0, 0, w/icon_height, h/icon_height)
    else
      love.graphics.draw(play_icon, 0, 0, 0, w/icon_height,h/icon_height)
    end
  end

  return self
end


return {
  Back = BackButton,
  Close = CloseButton,
  Plus = PlusButton,
  Icon = IconButton,
  Play = PlayButton,
}