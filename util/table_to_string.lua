function table_to_string(o, prettyprint, depth)
    depth = depth or 0

    if type(o) ~= "table" then
        if type(o) == "string" then
            return string.format("%q", o)
        else
            return tostring(o)
        end
    end

    local indent = prettyprint and string.rep("    ", depth) or ""
    local next_indent = prettyprint and string.rep("    ", depth + 1) or ""
    local newline = prettyprint and "\n" or ""
    local space = prettyprint and " " or ""

    local s = "{" .. newline

    for k, v in pairs(o) do
        local key
        if type(k) == "string" then
            key = string.format("%q", k)
        else
            key = tostring(k)
        end

        s = s
            .. next_indent
            .. "[" .. key .. "]"
            .. space .. "=" .. space
            .. table_to_string(v, prettyprint, depth + 1)
            .. ","
            .. newline
    end

    s = s .. indent .. "}"

    return s
end