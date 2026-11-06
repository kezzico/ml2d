local svg_render = require "ml2d.svg.renderer"
local calc_vector_rect = require "ml2d.svg.calc_vector_rect"
local View = require "ml2d.gui.view"

local function extract_id(asset)
  local asset_path, element_id = string.match((asset or ""), "([^#]+)#?(.*)")
  return asset_path, element_id
end

local function SvgButton(style_or_asset, onclick)
  local self = { }
  local state = nil
  if type(style_or_asset) == "table" then
    state = style_or_asset
    local a, e = extract_id(style_or_asset[1])
    state.asset = state.asset or a
    state.element_id = state.element_id or e
    
  elseif type(style_or_asset) == "string" then
    state = { }
    state.asset, state.element_id = extract_id(style_or_asset)
  end

  state.highlight_fill = state.highlight_fill or { type = "color", color = hexToColor(0xFFFFFF, 0.5, 0.0) }

  -- local frame = { x = 0, y = 0, w = 0, h = 0 }
  local pressed = false

  self.onpress = function() 
    -- print("SvgButton.onpress")
    pressed = true
  end

  self.onrelease = function()
    -- print("SvgButton.onrelease")
    pressed = false
  end

  self.onclick = function() 
    -- print("SvgButton.onclick")
    pressed = false
    if onclick then onclick() end
  end

  self.hit = function(self, x, y)
    return x >= state.frame.x and x <= state.frame.x + state.frame.w and y >= state.frame.y and y <= state.frame.y + state.frame.h
  end

  self.draw = function(self, w, h)
    local svg = cache.svg(state.asset)
    local vector = (state.element_id and svg[state.element_id]) or svg
    local rect = calc_vector_rect(vector)

    local s = math.min(w / rect[3], h / rect[4])
    love.graphics.push()
    love.graphics.scale(s, s)

    if pressed then 
      local pop_fill = vector[1].fill
      vector[1].fill = state.highlight_fill
      svg_render(vector)
      vector[1].fill = pop_fill
    else
      svg_render(vector)
    end

    love.graphics.pop()

    table.insert(clickables, self)
  end

  return View(state, { self })
end

return SvgButton