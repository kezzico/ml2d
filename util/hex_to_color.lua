function hexToColor(hex, alpha)
    local r = bit.rshift(bit.band(hex, 0xFF0000), 16)
    local g = bit.rshift(bit.band(hex, 0x00FF00), 8)
    local b = bit.band(hex, 0x0000FF)
    local a = alpha or 1
    return {r/255, g/255, b/255, a}
end

function stringHexToColor(hex, alpha)
    while #hex < 6 do
        hex = "0" .. hex
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    local a = alpha or 1
    return {r/255, g/255, b/255, a}
end