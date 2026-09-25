-- idea: l=180,p=120 , adaptive evals
local function eval_units(value_plus_unit, relative_to)
  local r = value_plus_unit

  if type(r) == "string" and (r:find("[+-]", 2)) then
    local val1, val2 = r:match("^([%+-]?[^%+-]+)([+-].+)$")
-- "^([%+-]?[^%+-]+)([+-].+)$"
-- "^[%+-]?[%d%.]+[eE]?[%+-]?%d*"
    local a = eval_units(val1, relative_to)
    local b = eval_units(val2, relative_to)

    if type(a) ~= "number" or type(b) ~= "number" then
      error("attempt to perform arithmetic on" .. " (" .. table_to_string(val1)  .. ") (" ..  table_to_string(val2)  .. ") " ..  table_to_string(value_plus_unit))
      return 0
    end
    
    return a + b
  end

  if type(r) == "string" and r:sub(-1) == "%" then
    r = tonumber(r:sub(1, -2)) * relative_to / 100
  elseif type(r) == "string" and r:sub(-2) == "px" then
    r = tonumber(r:sub(1, -3))
  elseif type(r) == "string" then
    r = tonumber(r)
  end

  return r
end

return eval_units
