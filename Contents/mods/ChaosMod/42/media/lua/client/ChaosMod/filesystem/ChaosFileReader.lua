local json = require("ChaosMod/thirdparty/Json")

ChaosFileReader = ChaosFileReader or {}

---@param filename string
---@return string | nil
function ChaosFileReader.ReadFileAllLines(filename)
    local modId = ChaosMod.modId
    local reader = getModFileReader(modId, filename, false)
    if not reader then
        print("[ChaosMod] File not found: " .. tostring(filename))
        return nil
    end

    local lines = {}
    while true do
        local line = reader:readLine()
        if line == nil then break end
        table.insert(lines, line)
    end

    reader:close()
    return table.concat(lines, "\n")
end

---@param filename string
---@return table<integer, string> | nil
function ChaosFileReader.ReadFileArrayFromCacheAllLines(filename)
    local reader = getFileReader(filename, false)
    if not reader then
        print("[ChaosMod] File not found: " .. tostring(filename))
        return nil
    end

    ---@type table<integer, string>
    local lines = {}
    while true do
        local line = reader:readLine()
        if line == nil then break end
        table.insert(lines, line)
    end

    reader:close()
    return lines
end

---@param value string | nil -- value to write; defaults to current timestamp
function ChaosFileReader.WriteSyncFile(value)
    local writer = getFileWriter("ChaosMod/mod-sync.txt", true, false)
    if not writer then
        print("[ChaosMod] Failed to open mod-sync.txt for writing")
        return
    end
    writer:write(value ~= nil and tostring(value) or tostring(getTimestampMs()))
    writer:close()
end

---@param filename string
---@return table | nil
function ChaosFileReader.ReadJsonFile(filename)
    local content = ChaosFileReader.ReadFileAllLines(filename)
    if not content then
        print("[ChaosMod] File not found: " .. tostring(filename))
        return nil
    end

    print("[ChaosMod] Content: " .. tostring(content))

    print("json module is " .. tostring(json))

    ---@type table | nil
    local data = nil
    local ok, _ = pcall(function()
        data = json.Decode(content)
        return data
    end)

    print("[ChaosMod] OK: " .. tostring(ok))
    print("[ChaosMod] Data or Error: " .. tostring(data))

    if data then
        for key, value in pairs(data) do
            print("[ChaosMod] Key: " .. tostring(key) .. " Value: " .. tostring(value))
        end
    end

    return data
end
