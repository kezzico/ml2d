local View = require "ml2d.gui.view"
local eval_units = require "ml2d.gui.eval_units"

local function FrameView(state, child)
  local self = { }
  child = child or state[1]

  self.draw = function(self, w, h)
    local fw = eval_units(state.rect[3], w)
    local fh = eval_units(state.rect[4], h)
    local fx = eval_units(state.rect[1], w)
    local fy = eval_units(state.rect[2], h)
    love.graphics.push()
    -- print(fw, fh, fx, fy, w, h)
    love.graphics.translate((w-fw)/2, (h-fh)/2)
    love.graphics.translate(fx, fy)
    child:draw(eval_units(state.rect[3], w), eval_units(state.rect[4], h))
    love.graphics.pop()
      

  end

  return View(state, { self })
end

return FrameView