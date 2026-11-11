local function SlideView(slide_state, cellForRow) 
  local self = { }
  local frame = { x = 0, y = 0, w = 0, h = 0 }

  slide_state = slide_state or { }
  slide_state.items = slide_state.items or { }
  slide_state.widths = slide_state.widths or { }
  slide_state.offset = slide_state.offset or 0
  slide_state.velocity = slide_state.velocity or 0

  local cell_queue = { }

  self.id = "slide_view"
  
  self.dequeue_cell = function(self, reuseIdentifier)
    -- TODO: actually dequeue cell with matching reuse identifier
    if #cell_queue > 0 then
      local cell = table.remove(cell_queue, 1)
      return cell
    end

    return nil
  end

  self.hit = function(self, x, y)
    return x >= frame.x and x <= frame.x + frame.w and y >= frame.y and y <= frame.y + frame.h
  end

  self.ondrag = function(self, dx, dy)
    slide_state.velocity = dx 
  end

  local function width_at_index(index)
    return slide_state.widths[index] or slide_state.all_widths or 200
  end
  -- sum child_heights from child_heights[1], child_heights[2], ... until the sum is greater than offset
  local function child_index_after_offset(offset)
    local index = 1
    local child_width_sum = 0
    while child_width_sum < offset and index <= #slide_state.items do
      local child_width = width_at_index(index)
      child_width_sum = child_width_sum + child_width
      index = index + 1
    end
    return index
  end

  slide_state.get_current_index = function()
    local buffer = width_at_index(child_index_after_offset(slide_state.offset)) * 0.3
    return math.clamp(child_index_after_offset(slide_state.offset + buffer), 1, #slide_state.items)
  end

  local function slide_offset_at_index(index)
    local width = 0
    for i=1,index do
      width = width + width_at_index(i)
    end
    return width
  end

  slide_state.slide_to_index = function(index, animated)
    if animated then
      local distance_to_slide = slide_offset_at_index(index - 1) - slide_state.offset
      -- print("distance_to_slide", distance_to_slide)

      local dt = love.timer and love.timer.getDelta() or (1 / 60)
      local decay_per_frame = 0.1 ^ dt
    
    -- Calculate exact initial velocity so total decay brings offset to target
      slide_state.velocity = -distance_to_slide * ((1 - decay_per_frame) / decay_per_frame)      
    else
      -- print("Sliding instantly to index", index)
      slide_state.offset = slide_offset_at_index(index - 1)
    end
  end

  self.update = function(self, dt)
    local content_width = slide_offset_at_index(#slide_state.items)
    local max_offset = math.max(0, content_width - frame.w)
    local overslide = 0

    if slide_state.offset < 0 then
        overslide = slide_state.offset
    elseif slide_state.offset > max_offset then
        overslide = slide_state.offset - max_offset
    end
    
    local min_velocity = 0.5
    if math.abs(slide_state.velocity) > min_velocity then
      local inertia = 0.2

      slide_state.velocity = slide_state.velocity * inertia ^ dt
    else
      slide_state.velocity = 0
    end

    local min_offset = 1
    if math.abs(slide_state.offset) < min_offset then
      slide_state.offset = 0
      overslide = 0
    end

    if math.abs(overslide) > 0 then
      local stiffness = 3
      local damping = 20
      local spring_force = overslide * stiffness
      local damping_force = -slide_state.velocity * damping
      local acceleration = spring_force + damping_force
      slide_state.velocity = slide_state.velocity + acceleration * dt
    end

    slide_state.offset = slide_state.offset - slide_state.velocity
  end

  self.draw = function(self, w, h)
    if w < 0 then return end
    if #slide_state.items == 0 then return end
    local lx, ly = love.graphics.transformPoint(0, 0)
    frame = { x = lx, y = ly, w = w, h = h}

    -- slide_state.width = math.max(child_width * #slide_state.items - w, 0)
    local render_start_index = math.clamp(child_index_after_offset(slide_state.offset) - 1, 1, #slide_state.items)
    local render_end_index = math.clamp(child_index_after_offset(slide_state.offset + w), 1, #slide_state.items)
    
    -- recycle cells for best slide performance
    local cells_for_reuse = { }

    -- print("render indices", render_start_index, render_end_index)
    -- setScissor uses screen coordinates. it does not respond to transformations
    love.graphics.setScissor(lx, ly, w, h)
    love.graphics.push()
    love.graphics.translate(slide_state.offset * -1, 0)
    -- local t = slide_state.offset * -1
    -- print("offset t = ", t)
    for i=1,render_start_index-1 do
      local child_width = width_at_index(i)
      love.graphics.translate(child_width, 0)
      -- t = t + child_width
      -- print("precalc t = ", t)
    end
    for i=render_start_index,render_end_index do
      local child_width = width_at_index(i)
      local cell = cellForRow(self, slide_state.items[i], i)
      table.insert(cells_for_reuse, cell)

      -- t = t + child_width
      -- print("procalc t = ", t, i, child_width)
      cell:draw(child_width, h)
      love.graphics.translate(child_width, 0)
    end
    love.graphics.pop()
    love.graphics.setScissor()

    cell_queue = cells_for_reuse

    table.insert(clickables, self)
    table.insert(updateables, self)
  end

  return self
end

return SlideView