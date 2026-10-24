local function add_point(rect, x, y)
    if rect[1] == nil then
        rect[1] = x
        rect[2] = y
        rect[3] = 0
        rect[4] = 0
        return
    end

    local min_x = math.min(rect[1], x)
    local min_y = math.min(rect[2], y)
    local max_x = math.max(rect[1] + rect[3], x)
    local max_y = math.max(rect[2] + rect[4], y)

    rect[1] = min_x
    rect[2] = min_y
    rect[3] = max_x - min_x
    rect[4] = max_y - min_y
end

local function calc_vector_rect(v, rect)
    rect = rect or {}

    if v.type == "group" or v.type == nil then
        for i = 1, #v do
            calc_vector_rect(v[i], rect)
        end

    elseif v.type == "circle" then
        local x, y, r = v[1], v[2], v[3]

        add_point(rect, x - r, y - r)
        add_point(rect, x + r, y + r)

    elseif v.type == "rect" then
        local x, y, w, h = v[1], v[2], v[3], v[4]
        add_point(rect, x, y)
        add_point(rect, x + w, y + h)

    elseif v.type == "path" then
        for i = 1, #v do
            local path = v[i]

            for j = 1, #path, 2 do
                add_point(rect, path[j], path[j + 1])
            end
        end
    end

    return rect
end

return calc_vector_rect