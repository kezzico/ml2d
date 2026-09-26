-- Love2D Mobile Template
-- ml2d/gui/ShelfView.lua
--
-- Reactive shelf view drawable.
-- Provides a horizontal shelf layout for child drawables with configurable widths and gaps.
--
-- Copyright (c) 2026 Lee Irvine
-- Licensed under the MIT License.
----------------------------------------------------------------------
-- ShelfView(style, children)
--
-- Shelf view drawable that arranges child drawables horizontally with optional widths and gaps.
--
-- Parameters:
--   style - table containing layout options:
--            widths: array of widths for each child (can be nil for flexible sizing)
--            gap: number specifying the gap between children
--   children - array of child drawables, each implementing :draw(width, height)
--
-- Returns:
--   a View containing the shelf view drawable.
----------------------------------------------------------------------

local eval_units = require "ml2d.gui.eval_units"
local View = require "ml2d.gui.view"

local function ShelfView(style, children)
  local self = { }
  style = style or { widths = { }, gap = 0 }
  children = children or style or {}

  self.draw = function(self, w, h)
    local gap = eval_units(style.gap, w) or 0
    local widths = style.widths or { }

    local total_gaps = gap * (#children - 1)
    local width_minus_gaps = w - total_gaps
    local width_budget = width_minus_gaps - reduce(widths, function(s, r, i) 
      return s + (eval_units(r, width_minus_gaps) or 0)
    end)

    local count_needy_children = reduce(children, function(s, r, index) 
      return s + ternary(widths[index] == nil, 1, 0) 
    end)

    love.graphics.push()
    for i=1,#children do
      local cell_width = eval_units(widths[i], width_minus_gaps) or (width_budget / count_needy_children)
      -- print(cell_width, widths[i], ternary(widths[i] ~= nil, "not nil", "is nil"))
      local child = children[i]
        -- local s = spread[i] or 1
      child:draw(cell_width, h)
      love.graphics.translate(cell_width, 0)
      love.graphics.translate(gap, 0)
    end
    love.graphics.pop()
  end

  return View(style, { self })
end

return ShelfView