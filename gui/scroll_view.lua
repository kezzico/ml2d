-- Love2D Mobile Template
-- app/gui/ScrollView.lua
--
-- Reactive scroll view drawable.
-- Provides a vertically scrollable container for child drawables with reusable cells.
--
-- Copyright (c) 2026 Lee Irvine
-- Licensed under the MIT License.
----------------------------------------------------------------------
-- ScrollView(scroll_state, cellForRow)
--
-- Scroll view drawable that provides a vertically scrollable container for child drawable cells with reusable cells.
--
-- Parameters:
--   scroll_state - table containing scroll state (items, heights, offset, velocity, all_heights)
--   cellForRow   - function(scrollview, item, index) returning a drawable for the given item and index
--
-- Returns:
--   a table implementing :draw(width, height), :update(dt), :hit(x, y), :ondrag(dx, dy), and :dequeue_cell(reuseIdentifier)

-- Drawable cell requirements:
--   Each cell returned by cellForRow must implement :draw(width, height) and optionally other methods for interaction.
--   The scroll view relies on these cells to render the content correctly and to support reuse for performance.
--   The cell should have an accessible state parameter for mutating the cell state, allowing the scroll view to reuse cells
-- Usage example:
-- local scrollView = ScrollView(scroll_state, function(scrollview, item, index)
--     local cell = scrollview:dequeue_cell("cell_identifier")
--     if cell == nil then
--         cell = MyCell()
--     end
--     return cell
-- end)

-- ScrollView Cell example:
-- local MyCell = function()
--     local self = { state = { text = "Jello, World"  } }
--     local view = TextView(self.state)
--     self.draw = function(self, w, h)
--         view:draw(w, h)
--     end
--     return self
-- end


local function ScrollView(scroll_state, cellForRow) 
  local self = { }
  local frame = { x = 0, y = 0, w = 0, h = 0 }

  scroll_state = scroll_state or { }
  scroll_state.items = scroll_state.items or { }
  scroll_state.heights = scroll_state.heights or { }
  scroll_state.offset = scroll_state.offset or 0
  scroll_state.velocity = scroll_state.velocity or 0

  local cell_queue = { }

  self.id = "scroll_view"
  
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
    scroll_state.velocity = dy 
  end

  local function height_at_index(index)
    return scroll_state.heights[index] or scroll_state.all_heights or 200
  end
  -- sum child_heights from child_heights[1], child_heights[2], ... until the sum is greater than offset
  local function child_index_after_offset(offset)
    local index = 1
    local child_height_sum = 0
    while child_height_sum < offset and index <= #scroll_state.items do
      local child_height = height_at_index(index)
      child_height_sum = child_height_sum + child_height
      index = index + 1
    end
    return index
  end

  scroll_state.get_current_index = function()
    local buffer = height_at_index(child_index_after_offset(scroll_state.offset)) * 0.3
    return math.min(child_index_after_offset(scroll_state.offset + buffer) - 1, #scroll_state.items)
  end

  local function scroll_offset_at_index(index)
    local height = 0
    for i=1,index do
      height = height + height_at_index(i)
    end
    return height
  end

  scroll_state.scroll_to_index = function(index, animated)
    if animated then
      local distance_to_scroll = scroll_offset_at_index(index - 1) - scroll_state.offset
      print("distance_to_scroll", distance_to_scroll)

      local dt = love.timer and love.timer.getDelta() or (1 / 60)
      local decay_per_frame = 0.1 ^ dt
    
    -- Calculate exact initial velocity so total decay brings offset to target
      scroll_state.velocity = -distance_to_scroll * ((1 - decay_per_frame) / decay_per_frame)      
    else
      print("Scrolling instantly to index", index)
      scroll_state.offset = scroll_offset_at_index(index - 1)
    end
  end

  self.update = function(self, dt)
    local content_height = scroll_offset_at_index(#scroll_state.items)
    local max_offset = math.max(0, content_height - frame.h)

    local overscroll = 0

    if scroll_state.offset < 0 then
        overscroll = scroll_state.offset
    elseif scroll_state.offset > max_offset then
        overscroll = scroll_state.offset - max_offset
    end
    
    local min_velocity = 0.5
    if math.abs(scroll_state.velocity) > min_velocity then
      local inertia = 0.1

      scroll_state.velocity = scroll_state.velocity * inertia ^ dt
    else
      scroll_state.velocity = 0
    end

    if math.abs(overscroll) > 0 then
      local stiffness = 1
      local damping = 10
      local spring_force = overscroll * stiffness
      local damping_force = -scroll_state.velocity * damping
      local acceleration = spring_force + damping_force
      scroll_state.velocity = scroll_state.velocity + acceleration * dt
    end

    scroll_state.offset = scroll_state.offset - scroll_state.velocity
  end

  self.draw = function(self, w, h)
    if h < 0 then return end
    local lx, ly = love.graphics.transformPoint(0, 0)
    frame = { x = lx, y = ly, w = w, h = h}

    -- scroll_state.height = math.max(child_height * #scroll_state.items - h, 0)
    local render_start_index = math.clamp(child_index_after_offset(scroll_state.offset) - 1, 1, #scroll_state.items)
    local render_end_index = math.clamp(child_index_after_offset(scroll_state.offset + h), 1, #scroll_state.items)
    
    -- recycle cells for best scroll performance
    local cells_for_reuse = { }

    -- print("render indices", render_start_index, render_end_index)
    -- setScissor uses screen coordinates. it does not respond to transformations
    love.graphics.setScissor(lx, ly, w, h)
    love.graphics.push()
    love.graphics.translate(0, scroll_state.offset * -1)
    -- local t = scroll_state.offset * -1
    -- print("offset t = ", t)
    for i=1,render_start_index-1 do
      local child_height = height_at_index(i)
      love.graphics.translate(0, child_height)
      -- t = t + child_height
      -- print("precalc t = ", t)
    end
    for i=render_start_index,render_end_index do
      local child_height = height_at_index(i)
      local cell = cellForRow(self, scroll_state.items[i], i)
      table.insert(cells_for_reuse, cell)

      -- t = t + child_height
      -- print("procalc t = ", t, i, child_height)
      cell:draw(w, child_height)
      love.graphics.translate(0, child_height)
    end
    love.graphics.pop()
    love.graphics.setScissor()

    cell_queue = cells_for_reuse

    table.insert(clickables, self)
    table.insert(updateables, self)
  end

  return self
end

return ScrollView