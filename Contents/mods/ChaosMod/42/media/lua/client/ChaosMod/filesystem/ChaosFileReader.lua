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

---@param filename string
---@return string | nil
function ChaosFileReader.ReadFileFromCacheAllLines(filename)
    local lines = ChaosFileReader.ReadFileArrayFromCacheAllLines(filename)
    if not lines then
        return nil
    end
    return table.concat(lines, "\n")
end

---@param line1 string | number -- timestamp or "0"
---@param iterationIndex integer -- current interval iteration count
---@param votingActive integer -- 1 if voting is active, 0 otherwise
function ChaosFileReader.WriteSyncFile(line1, iterationIndex, votingActive)
    local writer = getFileWriter("ChaosMod/mod-sync.txt", true, false)
    if not writer then
        print("[ChaosMod] Failed to open mod-sync.txt for writing")
        return
    end
    writer:write(tostring(line1) .. "\n" .. tostring(iterationIndex) .. "\n" .. tostring(votingActive))
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

    ---@type table | nil
    local data = nil
    local ok, err = pcall(function()
        data = json.Decode(content)
        return data
    end)

    if not ok then
        print("[ChaosMod] Failed to decode json " .. tostring(filename) .. ": " .. tostring(err))
        return nil
    end

    return data
end

---@param filename string
---@return table | nil
function ChaosFileReader.ReadJsonFromCache(filename)
    local content = ChaosFileReader.ReadFileFromCacheAllLines(filename)
    if not content then
        return nil
    end

    ---@type table | nil
    local data = nil
    local ok, err = pcall(function()
        data = json.Decode(content)
        return data
    end)

    if not ok then
        print("[ChaosMod] Failed to decode json " .. tostring(filename) .. ": " .. tostring(err))
        return nil
    end

    return data
end

---@param value any
---@return boolean
local function isArray(value)
    if type(value) ~= "table" then
        return false
    end
    local count = 0
    for _ in pairs(value) do
        count = count + 1
    end
    if count == 0 then
        -- Treat empty tables as empty arrays
        return true
    end
    -- Check sequential integer keys 1..count
    for i = 1, count do
        if value[i] == nil then
            return false
        end
    end
    return true
end

---@param s string
---@return string
local function escapeJsonString(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\b', '\\b')
    s = s:gsub('\f', '\\f')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

---@param value any
---@param indent integer
---@param out table<integer, string>
local function encodePretty(value, indent, out)
    local valueType = type(value)
    if value == nil then
        table.insert(out, "null")
    elseif valueType == "boolean" then
        table.insert(out, tostring(value))
    elseif valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            table.insert(out, "null")
        else
            -- integers without trailing .0
            if value == math.floor(value) and math.abs(value) < 1e15 then
                table.insert(out, string.format("%d", value))
            else
                table.insert(out, tostring(value))
            end
        end
    elseif valueType == "string" then
        table.insert(out, '"' .. escapeJsonString(value) .. '"')
    elseif valueType == "table" then
        local pad = string.rep(" ", indent * 4)
        local innerPad = string.rep(" ", (indent + 1) * 4)
        if isArray(value) then
            if #value == 0 then
                table.insert(out, "[]")
            else
                table.insert(out, "[\n")
                for i = 1, #value do
                    table.insert(out, innerPad)
                    encodePretty(value[i], indent + 1, out)
                    if i < #value then
                        table.insert(out, ",")
                    end
                    table.insert(out, "\n")
                end
                table.insert(out, pad)
                table.insert(out, "]")
            end
        else
            local keys = {}
            for k in pairs(value) do
                table.insert(keys, k)
            end
            if #keys == 0 then
                table.insert(out, "{}")
            else
                table.insert(out, "{\n")
                for i, k in ipairs(keys) do
                    table.insert(out, innerPad)
                    table.insert(out, '"' .. escapeJsonString(tostring(k)) .. '": ')
                    encodePretty(value[k], indent + 1, out)
                    if i < #keys then
                        table.insert(out, ",")
                    end
                    table.insert(out, "\n")
                end
                table.insert(out, pad)
                table.insert(out, "}")
            end
        end
    else
        table.insert(out, "null")
    end
end

---@param data any
---@return string
function ChaosFileReader.EncodeJsonPretty(data)
    local out = {}
    encodePretty(data, 0, out)
    return table.concat(out)
end

---@param filename string
---@param data any
---@return boolean
function ChaosFileReader.WriteJsonToCache(filename, data)
    if not json.Encode then
        print("[ChaosMod] json.Encode is not available; cannot write " .. tostring(filename))
        return false
    end

    local writer = getFileWriter(filename, true, false)
    if not writer then
        print("[ChaosMod] Failed to open " .. tostring(filename) .. " for writing")
        return false
    end

    local ok, content = pcall(ChaosFileReader.EncodeJsonPretty, data)
    if not ok or type(content) ~= "string" then
        print("[ChaosMod] Failed to encode json for " .. tostring(filename) .. ": " .. tostring(content))
        writer:close()
        return false
    end

    writer:write(content)
    writer:close()
    return true
end
