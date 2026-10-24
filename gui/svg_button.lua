local svg_render = require "ml2d.svg.renderer"
local calc_vector_rect = require "ml2d.svg.calc_vector_rect"

local function extract_id(asset)
  local asset_path, element_id = string.match((asset or ""), "([^#]+)#?(.*)")
  return asset_path, element_id
end

local function SvgButton(style_or_asset, onclick)
  local self = { }
  local style = nil
  if type(style_or_asset) == "table" then
    style = style_or_asset
    local a, e = extract_id(style_or_asset[1])
    style.asset = style.asset or a
    style.element_id = style.element_id or e
    
  elseif type(style_or_asset) == "string" then
    style = { }
    style.asset, style.element_id = extract_id(style_or_asset)
  end

  style.highlight_fill = style.highlight_fill or { type = "color", color = hexToColor(0xFFFFFF, 0.5, 0.0) }

  local frame = { x = 0, y = 0, w = 0, h = 0 }
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
    return x >= frame.x and x <= frame.x + frame.w and y >= frame.y and y <= frame.y + frame.h
  end

  self.draw = function(self, w, h)
    local lx, ly = love.graphics.transformPoint(0, 0)
    frame = { x = lx, y = ly, w = w, h = h }

    local svg = cache.svg(style.asset)
    local vector = (style.element_id and svg[style.element_id]) or svg
    local rect = calc_vector_rect(vector)

    local s = w / rect[3]
    love.graphics.push()
    love.graphics.scale(s, s)

    if pressed then 
      local pop_fill = vector[1].fill
      vector[1].fill = style.highlight_fill
      svg_render(vector)
      vector[1].fill = pop_fill
    else
      svg_render(vector)
    end

    love.graphics.pop()

    table.insert(clickables, self)
  end

  return self
end

return SvgButton