----------------------------------------------------------------------
-- Love2D Mobile Template
-- ml2d/gui/View.lua
--
-- Reactive view drawable.
-- Provides a container for child drawables that can reactively update its layout and appearance.
--
-- Copyright (c) 2026 Lee Irvine
-- Licensed under the MIT License.

----------------------------------------------------------------------
-- View(style, children)
--
-- View drawable that can draw a background, border, and child 
-- drawables with padding and offset handling.
--
-- Parameters:
--   style  - table of layout and appearance options:
--            backgroundColor: color used for the view fill
--            border: table containing color and width
--            padding: number or {top, left} padding values
--            offset: number or {top, left} offset values
--   children - array of child drawables, each implementing :draw(width, height)
--
-- Returns:
--   a table with a draw(self, width, height) method.

-- Usage example:
-- local view = View {
--   backgroundColor = {1, 0, 0, 1},
--   border = { color = {0, 0, 0, 1}, width = 2 },
--   padding = {10, 10},
--   offset = {5, 5},
--   View { }, View { }
-- } 
-- OR --
-- local view = View(
--   { backgroundColor = hexToColor(0xFF0000, 1.0) }, -- style
--   { View { }, View { } }) -- children


local eval_units = require "ml2d.gui.eval_units"

local function View(state, children)
  state = state or {}
  children = children or state or { }
  
  return {
    draw = function(self, w, h)
      local lx, ly = love.graphics.transformPoint(0, 0)
      state.frame = { x = lx, y = ly, w = w, h = h }

      local border_width = state.border and state.border.width or 0

      local padding = state.padding or { 0, 0 }
      local total_padding_x = eval_units((type(padding) == "table" and padding[2] or padding or 0), w) + border_width
      local total_padding_y = eval_units((type(padding) == "table" and padding[1] or padding or 0), h) + border_width

      local offset = state.offset
      local offset_x = eval_units((type(offset) == "table" and offset[2] or offset or 0), w)
      local offset_y = eval_units((type(offset) == "table" and offset[1] or offset or 0), h)

      love.graphics.push()
      love.graphics.translate(offset_x, offset_y)

      if state.backgroundColor then
        love.graphics.push("all")
        love.graphics.setColor(state.backgroundColor)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.pop()
      end
      
      if state.border then
        love.graphics.push("all")
        love.graphics.setColor(state.border.color)
        love.graphics.setLineWidth(state.border.width)
        love.graphics.rectangle("line", 0, 0, w, h)
        love.graphics.pop()
      end

      love.graphics.push()
      love.graphics.translate(total_padding_x, total_padding_y)

      for i = 1, #children do
        local child = children[i]
        child:draw(w - total_padding_x * 2, h - total_padding_y * 2)
      end
      love.graphics.pop()
      love.graphics.pop()

      return w, h
    end
  }
end

return View