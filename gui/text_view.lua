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

local _, styles = pcall(require, 'app.styles')
local View = require "ml2d.gui.view"

local function TextView(text_state_or_text, style)
  local self = { }
  local text_state = { text = "" }

  if type(text_state_or_text) == "string" or type(text_state_or_text) == "number" then
    text_state.text = text_state_or_text
  elseif text_state_or_text ~= nil then
    text_state = text_state_or_text
    text_state.text = text_state.text or ""
  end

  table.mush(text_state, style)

  self.draw = function(self, w, h)
      -- { "assets/fonts/HelveticaNeueMedium.otf", size = 30, hinting = "normal", dpi = 3.0 }
      local font = cache.font( text_state.font or styles.fonts.default )
        
      local maxWidth, wrappedtext = font:getWrap( text_state.text, w )
      local textWidth = maxWidth

      local textHeight = font:getAscent() * #wrappedtext

      local align = text_state.align or "center" -- top, center, bottom
      local justify = text_state.justify or "center" -- left, center, right

      love.graphics.push("all")
      if DEBUG then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, w, textHeight)
      end

      if align == "center" then
        love.graphics.translate(0, -textHeight * 0.5 + h * 0.5)
      elseif align == "bottom" then
        love.graphics.translate(0, h - textHeight)
      end

      if text_state.color ~= nil then love.graphics.setColor(text_state.color) end
      if font ~= nil then love.graphics.setFont(font) end
      love.graphics.printf(text_state.text, 0, 0, w, justify)

      love.graphics.pop()
    end

    return View(text_state, { self })
end

return TextView