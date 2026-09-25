----------------------------------------------------------------------
-- Love2D Mobile Template
-- app/gui/View.lua
--
-- Reactive view drawable.
-- Provides a container for child drawables that can reactively update its layout and appearance.
--
-- Copyright (c) 2026 Lee Irvine
-- Licensed under the MIT License.

----------------------------------------------------------------------
-- TextView(text_state_or_text, style)
--
-- Text view drawable that displays text with alignment, justification, and styling options.
--
-- Parameters:
--   text_state_or_text - string, number, or table containing text and optional styling information
--   style - table containing style overrides for the text view
--
-- Returns:
--   a View containing the text view drawable.
-- Usage example:
-- local textView = TextView("Hello World", { color = {1, 1, 1, 1}, size = 24 })
-- local textView = TextView({ text = "Hello World", color = {1, 1, 1, 1}, size = 24 })
-- local textView = TextView("Hello World")

local styles = require "app.styles"
local View = require("app.gui.view")

local function TextView(text_state_or_text, style)
  local self = { }
  -- style is cloned to prevent weird side effects --
  style = table.clone(style) or { }

  -- local text_state = style or { text = "" }
  local text_state = { text = "" }

  if type(text_state_or_text) == "string" or type(text_state_or_text) == "number" then
    text_state.text = text_state_or_text
  elseif text_state_or_text ~= nil then
    text_state = text_state_or_text
    text_state.text = text_state.text or ""
  end

  self.draw = function(self, w, h)
      local font_scale = (text_state.size or style.size or 30.0) / 60.0
      local font = 
        text_state.font or 
        style.font or 
        styles.fonts.default
        cache.font({"assets/fonts/joystix.ttf"})
        
      local maxWidth, wrappedtext = font:getWrap( text_state.text, w / font_scale )
      local textWidth = maxWidth
      local textHeight = font:getHeight(text_state.text) * #wrappedtext

      local align = text_state.align or style.align or "center" -- top, center, bottom
      local justify = text_state.justify or style.justify or "center" -- left, center, right
      local text_color = text_state.color or style.color or styles.colors.text

      love.graphics.push("all")

      if DEBUG then
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, w, h)
      end

      -- using a large font and scaling it down to get better visual quality
      -- there seems to be some side effects from doing this however.
      -- certains fonts will display strange artifacts. 
      love.graphics.scale(font_scale, font_scale)
      love.graphics.setColor(text_color)
      love.graphics.setFont(font)

      if align == "center" then
        love.graphics.translate(0, -textHeight * 0.5 + h / font_scale * 0.5)
      elseif align == "bottom" then
        love.graphics.translate(0, h / font_scale - textHeight)
      end
      
      love.graphics.printf(text_state.text, 0, 0, w / font_scale, justify)

      love.graphics.pop()
    end

    return View(table.mush(text_state, style), { self })
end

return TextView