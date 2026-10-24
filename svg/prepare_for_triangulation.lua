local function prepare_for_triangulation(vertices)
    if #vertices < 6 then return nil end -- Need at least 3 points (6 numbers)

    local cleaned = {}
    
    -- 1. Remove consecutive duplicates
    for i = 1, #vertices, 2 do
        local x, y = vertices[i], vertices[i+1]
        local prevX, prevY = cleaned[#cleaned-1], cleaned[#cleaned]
        
        if x ~= prevX or y ~= prevY then
            table.insert(cleaned, x)
            table.insert(cleaned, y)
        end
    end

    -- 2. If the path closed itself by explicitly repeating the first point, remove the duplicate end point
    if #cleaned >= 8 and cleaned[1] == cleaned[#cleaned-1] and cleaned[2] == cleaned[#cleaned] then
        table.remove(cleaned)
        table.remove(cleaned)
    end

    -- Must have at least 3 distinct vertices (6 numbers) to triangulate
    if #cleaned < 6 then return nil end

    return cleaned
end

return prepare_for_triangulation