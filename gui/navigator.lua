local function Navigator(stack)
  local stack = stack or {}
  local style = {}

  style.friction = 8

  local state = { }
  state.dragging = false
  state.offset_x = 0
  state.velocity = 0

  return {
    id = "navigator",

    reset = function(self)
      local current = stack[#stack]

      if current ~= nil and current.suspend then
        current:suspend()
      end

      while #stack > 0 do
        table.remove(stack)
      end
    end,

    push = function(self, destination)
      local current = stack[#stack]

      if current ~= nil and current.suspend then
        current:suspend()
      end

      table.insert(stack, destination)

      if destination.activate then
        destination:activate()
      end
    end,
    
    peek = function(self)
      return #stack
    end,

    pop = function(self)
      local current = stack[#stack] 

      if current ~= nil and current.suspend then
        current:suspend()
      end

      table.remove(stack)

      local new_top = stack[#stack]
      if new_top ~= nil and new_top.activate then
        new_top:activate()
      end

      return #stack
    end,
    
    hit = function(self, x, y)
      local w, h = love.graphics.getDimensions()
      return state.dragging == true or x < w * 0.2
    end,

    ondrag = function(self, dx, dy)
      state.offset_x = state.offset_x + dx
      state.dragging = true
      return dx > 1
    end,

    onrelease = function(self, x, y)
      state.dragging = false
    end,

    onkeydown = function(self, key)
      if key == "escape" then
        if navigator:peek() > 0 then navigator:pop() end
      end
    end,

    update = function(self, dt)
        state.offset_x = math.max(0, state.offset_x)

        local w, h = love.graphics.getDimensions()
        local max_velocity = w * style.friction * 1.25

        if state.velocity > 0 then
            state.velocity = math.min(max_velocity, state.velocity)
        elseif state.velocity < 0 then
            state.velocity = math.max(max_velocity * -1, state.velocity)
        end

        if state.dragging == false then
            local target = (state.offset_x > w / 3) and w or 0

            local stiffness = 20 + (state.offset_x / w) * 80
            local damping = style.friction

            local displacement = target - state.offset_x

            state.velocity = state.velocity + displacement * stiffness * dt
            state.velocity = state.velocity * math.exp(-damping * dt)

            state.offset_x = state.offset_x + state.velocity * dt
        end

        if state.dragging == false and state.offset_x >= w then
          state.offset_x = 0
          state.velocity = 0
          self:pop()
        end
    end,

    draw = function(self, w, h)
      if #stack > 1 then
        if state.offset_x > 0 then
          love.graphics.setScissor(0, 0, state.offset_x+2, h)
          stack[#stack-1]:draw(w, h)
          love.graphics.setScissor()
        end
        -- block clicks / key events for underlying elements
        clickables = { }
        keyables = { }
        
        table.insert(clickables, self)
        table.insert(updateables, self)
        table.insert(keyables, self)

        love.graphics.push()
        love.graphics.translate(state.offset_x, 0)
        stack[#stack]:draw(w, h)
        love.graphics.pop()
      elseif #stack > 0 then
        stack[#stack]:draw(w, h)
      end
    end
  }
end

return Navigator