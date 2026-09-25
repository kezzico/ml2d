-- Utility functions for table manipulation, functional programming, and string operations
-- @param m_initial table or iterator function
-- @param callback function
-- @return table
function map(m_initial, map_func)
  local m_transform = { }
  
  if(type(m_initial) == "function") then
    print(table_to_string(m_initial))
    for element in m_initial do
      table.insert(m_transform, map_func(element) )
    end
  elseif type(m_initial) == "table" then
    for i=1, #m_initial do
      table.insert(m_transform, map_func(m_initial[i]) )
    end
  end

  return m_transform
end

function map_pairs(tbl, map_func)
  local m_transform = { }
  for key, value in pairs(tbl) do
    table.insert(m_transform, map_func(key, value) )
  end

  return m_transform
end



-- flatten an array of tables into a single table
-- @param ... tables
-- @return table
function flatten(...)
  local args = { ... }

  function f(t, flat)
    for k, v in pairs(t) do -- iterate all keys, numeric or string
      if type(v) == "table" then
        f(v, flat)        -- recurse into inner table
      else
        table.insert(flat, v)   -- insert leaf value
      end
    end

    return flat
  end

  return f(args, { })
end

-- reduce a table to a single value using a reducer function
-- @param tbl table
-- @param reducer function
-- @return number
function reduce(tbl, reducer)
  local s = 0
  -- using pairs here so that nil entries in the table won't truncate the loop
  -- side effect: named table entries will be included in the loop, so filter for numbers only
  for i, row in pairs(tbl) do
    if type(i) == 'number' then s = reducer(s, tbl[i], i) end
  end

  return s
end

-- ternary operator function
-- @param condition boolean
-- @param a any
-- @param b any
-- @return any
function ternary(condition, a, b)
  if condition then
    return a
  else
    return b
  end
end

-- filter a table using a filter function
-- @param tbl table
-- @param filter_func function
-- @return table
function filter(tbl, filter_func)
  local ftbl = { }
  for i, row in ipairs(tbl) do
    if filter_func(row, i) then
      table.insert(ftbl, row)
    end
  end

  return ftbl
end

function filter_pairs(tbl, filter_func)
  local ftbl = { }
  for key, value in pairs(tbl) do
    if filter_func(key, value) then
      table.insert(ftbl, value)
    end
  end

  return ftbl
end

function pairs_matching(tbl, pattern)
    local matches = {}    
    for key in pairs(tbl) do
        if type(key) == "string" and string.find(key, pattern) then
            table.insert(matches, key) -- Build a sequential array
        end
    end
    
    return matches
end

function concat(tables)
  local result = { }

  for _, tbl in ipairs(tables) do
    for _, value in ipairs(tbl) do
      table.insert(result, value)
    end
  end

  return result
end

return {
    map = map,
    flatten = flatten,
    reduce = reduce,
    ternary = ternary,
    filter = filter,
    filter_pairs = filter_pairs,
    map_pairs = map_pairs,
    concat = concat
}