local function segments_in_vector(v, segments)
  segments = segments or {}

  if v.type == "group" then
    for i = 1, #v do segments_in_vector(v[i], segments) end
  elseif v.type == "circle" then
    -- fuck off
  elseif v.type == "rect" then
    local x, y, w, h = v[1], v[2], v[3], v[4]
    -- (x,y) ───────── (x+w,y)
    --   │                 │
    --   │                 │
    -- (x,y+h) ─────── (x+w,y+h)
    table.insert(segments, {{x, y}, {x + w, y}})
    table.insert(segments, {{x + w, y}, {x + w, y + h}})
    table.insert(segments, {{x + w, y + h}, {x, y + h}})
    table.insert(segments, {{x, y + h}, {x, y}})
  elseif v.type == "path" then
    for i = 1, #v do
      for j = 1, (#v[i] - 3), 2 do
        table.insert(segments, {
          {v[i][j],     v[i][j + 1]},
          {v[i][j + 2], v[i][j + 3]}
        })
      end
    end
  end
  return segments
end

return segments_in_vector