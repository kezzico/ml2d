----------------------------------------------------------------------
-- Love2D Mobile Template
-- ml2d/gui/TextView.lua
--
-- Drawable that renders text using a font descriptor and supports alignment and justification.
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
-- local textView = TextView("Hello World", {
--   color = {1, 1, 1, 1},
--   font = { "assets/fonts/HelveticaNeueMedium.otf", size = 24 }
-- })
-- local textView = TextView("Hello World")

local styles = require "app.styles"
local View = require "ml2d.gui.view"

local function TextView(text_state_or_text, style)
  local self = { }
  local text_state = { text = "" }
  style = table.clone(style) or { }

  if type(text_state_or_text) == "string" or type(text_state_or_text) == "number" then
    text_state.text = text_state_or_text
  elseif text_state_or_text ~= nil then
    text_state = text_state_or_text
    text_state.text = text_state.text or ""
  end

  self.draw = function(self, w, h)
    local font_spec = text_state.font or style.font or styles.fonts.default
    local font = type(font_spec) == "table" and cache.font(font_spec) or font_spec
    local _, wrappedtext = font:getWrap(text_state.text, w)
    local text_height = font:getHeight() * #wrappedtext
    local align = text_state.align or style.align or "center"
    local justify = text_state.justify or style.justify or "center"
    local text_color = text_state.color or style.color or styles.colors.text

    love.graphics.push("all")
    if DEBUG then
      love.graphics.setColor(0, 1, 0, 0.5)
      love.graphics.rectangle("fill", 0, 0, w, h)
    end

    love.graphics.setFont(font)
    love.graphics.setColor(text_color)

    if align == "center" then
      love.graphics.translate(0, -text_height * 0.5 + h * 0.5)
    elseif align == "bottom" then
      love.graphics.translate(0, h - text_height)
    end

    love.graphics.printf(text_state.text, 0, 0, w, justify)
    love.graphics.pop()
  end

  return View(table.mush({}, text_state, style), { self })
end

return TextView
