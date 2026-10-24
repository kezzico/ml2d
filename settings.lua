local json = require "ml2d.web.json"
local SETTINGS_FILE = "settings.json"

local function Settings()
    local self = { }

    local function save()
        local ok, encoded = pcall(json.encode, self)
        if not ok then
            print("[SETTINGS] failed to encode settings json", encoded)
            return false
        end

        local result = love.filesystem.write(SETTINGS_FILE, encoded)
        print("[SETTINGS] saved settings to " .. love.filesystem.getSaveDirectory() .. "/" .. SETTINGS_FILE)
        
        if not result then
            print("[SETTINGS] failed to write settings json")
            return false
        end

        return true
    end

    local function reload()
        local data = love.filesystem.read(SETTINGS_FILE) or json.encode({ version = "1.0" })
        local success, settings_obj = pcall(json.decode, data)

        if not success then
            print("[SETTINGS] failing to parse settings json")
            print("[SETTINGS] " .. data)
            print("[SETTINGS] " .. table_to_string(settings_obj))
        else
            table.mush(self, settings_obj)
        end

        self.save = save
    end

    reload()

    return self
end


return Settings