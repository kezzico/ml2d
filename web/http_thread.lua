local https = require("https")

local request_channel = love.thread.getChannel("request")
local response_channel = love.thread.getChannel("response")

local rq = request_channel:demand()

while rq ~= "quit" do
    local url = rq.url
    local rq_headers = rq.headers or {}
    local rq_method = rq.method or "GET"
    local rq_body = rq.body or nil
    local rq_id = rq.id
    
    local code, body, headers = https.request(url, {
        method = rq_method,
        headers = rq_headers,
        data = rq_body,
    })

    print("[HTTP] response", url, code)
    -- 200 ok for resources that that are cached is normal
    -- 0 code means no connection
    -- HTTP BODY! >>   https://analytics.kezzi.co/pixel.jpg?ctm=doomtruck/game_start   0
    -- HTTP BODY! >>   https://dev.kezzi.co/ads        0
    -- HTTP BODY! >>   https://kezzico-bucket.sfo2.digitaloceanspaces.com/ads.kezzi.co/ad_advertise_survive.jpg        200
    -- HTTP BODY! >>   https://kezzico-bucket.sfo2.digitaloceanspaces.com/ads.kezzi.co/ad_pair_code.jpg        200

    response_channel:push({
        id = rq_id,
        code = code,
        response = body,
        url = url,
    })

    rq = request_channel:demand()
end

print("HTTP thread exiting")