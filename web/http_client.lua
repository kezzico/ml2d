function HttpClient()
    local request_channel = love.thread.getChannel("request")
    local response_channel = love.thread.getChannel("response")
    local callbacks = { }
    local next_id = 1

    local thread = love.thread.newThread("app/web/http_thread.lua")
    thread:start()
    
    return {
        kill = function()
            request_channel:push("quit")
        end,

        poll = function(self) 
            local msg = response_channel:pop()
            while msg ~= nil do
                local id = msg.id
                local code = msg.code
                local response = msg.response

                if callbacks[id] then
                    callbacks[id](code, response)
                    callbacks[id] = nil
                end

                msg = response_channel:pop()
            end
        end,

        request = function(self, params, callback)
            if not params or not params.url then
                error("Missing required fields: url")
            end

            local id = next_id
            next_id = next_id + 1

            if callback ~= nil then
                callbacks[id] = callback
            end

            request_channel:push({ 
                id = id, 
                url = params.url, 
                method = params.method, 
                headers = params.headers, 
                body = params.body 
            })
        end,
    }
end

return HttpClient()