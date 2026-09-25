local function encode_str(str)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((str:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#str%3+1])
end

local function decode_png(b64)
    b64 = b64:match("^data:image/png;base64,(.+)$") or b64

    local success, image_or_message = pcall(function()
        -- 1. base64 → raw bytes
        local raw = love.data.decode("string", "base64", b64)
        
        -- 2. raw bytes → FileData
        local fileData = love.filesystem.newFileData(raw, "image.png")
        
        -- 3. FileData → ImageData
        local imageData = love.image.newImageData(fileData)
        
        -- 4. ImageData → GPU image
        return love.graphics.newImage(imageData)
    end)

    if not success then
        print("faiekld to load image")
        print(image_or_message)
        return love.graphics.newImage(1, 1)
    end
    
    return image_or_message

end

return {
    decode_png = decode_png,
    encode_str = encode_str
}