local prepare_for_triangulation = require "ml2d.svg.prepare_for_triangulation"

local function valid_triangle(t)
    local x1, y1 = t[1], t[2]
    local x2, y2 = t[3], t[4]
    local x3, y3 = t[5], t[6]

    local area =
        (x2 - x1) * (y3 - y1) -
        (y2 - y1) * (x3 - x1)

    return math.abs(area) > 0.001
end

local function add_vector_shapes_to_body(body, v)
    if v.type == "group" then
        for i = 1, #v do add_vector_shapes_to_body(body, v[i]) end
        return
    elseif v.type == "circle" then
        love.physics.newCircleShape(body, v[1], v[2], v[3])
        return

    elseif v.type == "rect" then
        local x, y, w, h = v[1], v[2], v[3], v[4]
        love.physics.newPolygonShape(body,
            x,     y,
            x + w, y,
            x + w, y + h,
            x,     y + h)
        return

    elseif v.type == "path" then
        for i = 1, #v do
            local path = v[i]

            if path.triangles == nil then 
                path.triangles = love.math.triangulate(prepare_for_triangulation(path))
            end

            for k = 1, #path.triangles do
                local tri = path.triangles[k]
                if valid_triangle(tri) then
                    -- print("[add_vector_to_body] adding tri to body", tri[1], tri[2], tri[3], tri[4], tri[5], tri[6])
                    love.physics.newPolygonShape(body,
                        tri[1], tri[2],
                        tri[3], tri[4],
                        tri[5], tri[6])
                else
                    print("[add_vector_to_body] bad triangle!", tri[1], tri[2], tri[3], tri[4], tri[5], tri[6])
                end
            end
        end
        return
    end
end

local function body_from_vector(world, v, params)
    params = params or { }

    params.position = params.position or { 0, 0 }
    params.friction = params.friction or 1
    params.sensor = params.sensor or false
    params.type = params.type or "static"

    local body = love.physics.newBody(
        world, params.position[1], params.position[2], 
        params.type)

    if v ~= nil then
        add_vector_shapes_to_body(body, v)
    end

    for _, shape in ipairs(body:getShapes()) do
        shape:setSensor(params.sensor)
        shape:setFriction(params.friction)
    end

    return body
end

return body_from_vector