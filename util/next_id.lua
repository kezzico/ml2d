local last_id = 0
local function next_id()
    last_id = last_id + 1
    return tostring(last_id)
end

return next_id