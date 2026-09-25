-- fill a table with a value, repeating if necessary
-- @param n number
-- @param value any
-- @return table
table.fill = function(n, value)
  local t = {}
  if type(value) == 'table' then
    local i = 0
    while i < n do
      -- for i, row in pairs(tbl) do

      -- for j = 1, #value do 
      for j, _ in pairs(value) do
        -- print(j, table_to_string(value))
        if i+(j-1) < n then t[i+j] = value[j] end
      end
      i = (i + #value) or 1
    end
  else
    for i = 1, n do t[i] = value end
  end
  -- print(n, table_to_string(t))
  return t
end

-- clone a table (shallow copy)
-- @param orig table
-- @return table
function table.clone(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end

    return copy
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.mush(...)
  local mush = { }
  for _, tbl in ipairs({...}) do
    if type(tbl) == 'table' then
      for key, value in pairs(tbl) do
        mush[key] = value
      end
    end
  end
  return mush
end

-- split a string by a separator
-- @param str string
-- @param sep string
-- @return table
string.split = function(str, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

--- clamp a number between a lower and upper bound (by @clem)
--- @param x number
--- @param lower_bound number
--- @param upper_bound number
--- @return number
function math.clamp(x, lower_bound, upper_bound)
    if lower_bound == nil then lower_bound = -math.huge end
    if upper_bound == nil then upper_bound = math.huge end

    if x < lower_bound then
        x = lower_bound
    end

    if x > upper_bound then
        x = upper_bound
    end

    return x
end

function math.magnitude(v)
  return math.sqrt(v[1]^2 + v[2]^2)
end

function math.distance(a, b)
  return math.sqrt((b[1] - a[1])^2 + (b[2] - a[2])^2 )
end

-- pseudo-random number generator based on a seed and a string input
-- @param seed string -- the seed for the pseudo-random number generator
-- @param str hash -- different hashes generate different numbers
-- @return number
function math.prandom(seed, str)
  -- print(str)
  local hash = love.data.hash( "string", "sha256", seed..str )

  local hex = love.data.encode("string", "hex", hash)

  local number = tonumber(hex:sub(1,8), 16)
  -- print(number)
  return number / 4294967295 -- 2^32
end

function math.random_color(mask)
  mask = mask or 0xFFFFFF

  -- Treat the mask as RGB channel flags and return Love2D-style normalized
  -- color components. For example, 0xFF0000 produces a random red color.
  local red = math.floor(mask / 0x10000) % 0x100
  local green = math.floor(mask / 0x100) % 0x100
  local blue = mask % 0x100

  return {
    red > 0 and math.random() or 0,
    green > 0 and math.random() or 0,
    blue > 0 and math.random() or 0
  }
end

function math.displacement(p1, p2)
  return { 
    p2[1] - p1[1],
    p2[2] - p1[2]
  }
end

function math.sign(x)
  if x > 0 then return 1 end
  return -1
end
function math.cardinality(p)
  if p[1] > 0 then return 1 end
  return -1
end
function math.step(n, ...)
  local p = 0
  for _, x in ipairs({...}) do
    if x <= n then
      p = x
    end
  end

  return p
end