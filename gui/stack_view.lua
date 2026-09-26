-- Love2D Mobile Template
-- ml2d/gui/StackView.lua
--
-- Reactive stack view drawable.
-- Provides a vertical stack layout for child drawables with configurable heights and gaps.
--
-- Copyright (c) 2026 Lee Irvine
-- Licensed under the MIT License.

----------------------------------------------------------------------
-- StackView(style, children)
--
-- Stack view drawable that arranges child drawables vertically with optional heights and gaps.
--
-- Parameters:
--   style - table containing layout options:
--            heights: array of heights for each child (can be nil for flexible sizing)
--            gap: number specifying the gap between children
--   children - array of child drawables, each implementing :draw(width, height)
--
-- Returns:
--   a View containing the stack view drawable.
-- Usage example:
-- local stackView = StackView({ heights = { 100, nil, 50 }, gap = 10 }, { child1, child2, child3 })
----------------------------------------------------------------------


local eval_units = require "ml2d.gui.eval_units"
local View = require "ml2d.gui.view"

local function StackView(style, children)
  local self = { }
  style = style or { heights = { }, gap = 0 }
  children = children or style or {}

  self.draw = function(self, w, h)
    local gap = eval_units(style.gap, h) or 0
    local heights = style.heights or { }

    local total_gaps = gap * (#children - 1)

    local height_minus_gaps = h - total_gaps
-- print(table_to_string(heights))
    -- calculate the amount of height needed for children with a specified height
    local height_budget = height_minus_gaps - reduce(heights, function(s, r, i) 
      return s + (eval_units(r, height_minus_gaps) or 0)
    end)
-- print("height budget", height_budget)
    -- divide the remaining 'budget' amongst the remaining children with a nil height
    local count_needy_children = reduce(children, function(s, r, index) 
      return s + ternary(heights[index] == nil, 1, 0) 
    end)
-- print("needy children", count_needy_children)
    love.graphics.push()
    for i=1,#children do
      local cell_height = eval_units(heights[i], height_minus_gaps) or eval_units(style.all_heights, h) or (height_budget / count_needy_children)
      local child = children[i]

      -- some how the height budget is 620, when I need 180+44 for static cells... expected 576
-- local lx, ly = love.graphics.transformPoint(0, 0)
-- print(ly, cell_height)
      child:draw(w, cell_height)
      love.graphics.translate(0, cell_height)
      love.graphics.translate(0, gap)

    end
    love.graphics.pop()
  end

  return View(style, { self })
end

return StackView