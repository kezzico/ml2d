local function ControlModule()
  local self = { }
  local mouse_down = false
  local mouse_drag = false
  local mouse_delta = 0
  local clicked = { }

  self.onpress = function(self, x, y)
    -- print("🐁 press the mouse down")
    mouse_down = true
    mouse_drag = false
    clicked = { }

    -- print("searching for clickable onpress >>")
    for i = #clickables, 1, -1 do
      local clickable = clickables[i]
      -- print("🐁 " .. (clickable.id or "noid"))
      if clickable.hit and clickable:hit(x, y) then
        table.insert(clicked, clickable)
        
        if clickable.onpress then 
          -- print("<< pressed", clickable.id)
          clickable:onpress(x, y) 
        end
      end
      -- print(clickable.id)
    end
  end

  self.onmove = function(self, x, y, dx, dy)
    if mouse_down then
      mouse_delta = mouse_delta + math.abs(dx) + math.abs(dy)
    else
      mouse_delta = 0
    end

    if mouse_delta > 5 then
      mouse_drag = true
    end

    if mouse_down == true then
      for i = #clicked, 1, -1 do
        local c = clicked[i]
        if c.ondrag then 
          c:ondrag(dx, dy, x, y) 
          -- once a clickable responds to drag 
        else
          if c.onrelease then c:onrelease(x, y) end
          table.remove(clicked, i)
        end
      end
    end
  end

  self.onrelease = function(self, x, y)
    -- print("🐁 release the mouse", "number of clickables:", #clickables)
    mouse_down = false
    for i = #clickables, 1, -1 do
      local clickable = clickables[i]
      local hit = clickable.hit and clickable:hit(x, y)
      if hit and clickable.onclick and mouse_drag == false then
        -- print(table_to_string(map(clickables, function(c) return c.id end)))
        clickable:onclick(x, y)
        return
      elseif table.contains(clicked, clickable) then
        -- print(table_to_string(map(clickables, function(c) return c.id end)))
        if clickable.onrelease then clickable:onrelease(x, y) end
      end
    end
  end

  return self
end

return ControlModule