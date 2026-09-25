local function messageForCode(code)
    if code == -1 then return "Invalid JSON"
    elseif code == 0 then return "Offline"
    elseif code >= 200 and code < 300 then return nil
    elseif code == 400 then return "Bad Request"
        elseif code == 401 then return "Unauthorized"
        elseif code == 403 then return "Forbidden"
        elseif code == 404 then return "Not Found"
        elseif code == 500 then return "Internal Server Error"
        elseif code == 502 then return "Bad Gateway"
        elseif code == 503 then return "Service Unavailable"
        else return "Unknown Error"
    end
end

return {
    messageForCode = messageForCode
}