---@class ChaosZombieNicknameColor
---@field r number
---@field g number
---@field b number

---@class ChaosNicknameEntry
---@field name string
---@field color ChaosZombieNicknameColor

---@class ChaosNicknameRawData
---@field name string
---@field color table<integer, integer>

---@class ChaosNicknames
---@field availableNicknames table<integer, ChaosNicknameEntry>
---@field updateTickCounter integer
---@field modDataNameKey string
---@field modDataColorKey string
ChaosNicknames = ChaosNicknames or {
    availableNicknames = {},
    updateTickCounter = 0,

    modDataNameKey = "ChaosModNickname",
    modDataColorKey = "ChaosModNicknameColor"
}

---@param s string
---@return string nickname, integer r, integer g, integer b
local function parseNickColor(s)
    -- split by first "/" into nickname + "255,127,80"
    local nickname, rgb = s:match("^([^/]+)/(.+)$")
    if not nickname or not rgb then
        return "", 0, 0, 0
    end

    -- extract 3 numbers (allows spaces too)
    local r, g, b = rgb:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if not r then
        return nickname, 255, 0, 0
    end

    local rInt = math.floor(tonumber(r) or 255)
    local gInt = math.floor(tonumber(g) or 0)
    local bInt = math.floor(tonumber(b) or 0)
    return nickname, rInt, gInt, bInt
end

---@param r integer
---@param g integer
---@param b integer
---@return ChaosZombieNicknameColor
local function convertIntegerColorsToFloat(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

function ChaosNicknames.LoadNicknamesFromDisk()
    ChaosNicknames.updateTickCounter = 0
    local path = "ChaosMod/Nicknames.txt"

    local lines = ChaosFileReader.ReadFileArrayFromCacheAllLines(path)

    if not lines then
        print("[ChaosNicknames] Failed to load nicknames from disk")
        return
    end

    ChaosNicknames.availableNicknames = {}

    local totalNicknames = 0

    -- Add new nickname by line
    for _, line in ipairs(lines) do
        local nickname, r, g, b = parseNickColor(line)
        if nickname then
            local color = convertIntegerColorsToFloat(r, g, b)
            if color then
                table.insert(ChaosNicknames.availableNicknames,
                    { name = nickname, color = color })
                totalNicknames = totalNicknames + 1
            end
        end
    end

    print("[ChaosNicknames] Loaded " .. tostring(totalNicknames) .. " nicknames")
end

---@param deltaMs integer
function ChaosNicknames.OnTick(deltaMs)
    local maxUpdateTime = 5000 -- 5 seconds
    ChaosNicknames.updateTickCounter = ChaosNicknames.updateTickCounter + deltaMs
    if ChaosNicknames.updateTickCounter >= maxUpdateTime then
        ChaosNicknames.LoadNicknamesFromDisk()
    end
end

---@return string, ChaosZombieNicknameColor
function ChaosNicknames.GetRandomNickname()
    local randomIndex = math.floor(ZombRandBetween(1, #ChaosNicknames.availableNicknames + 1))
    if randomIndex < 1 or randomIndex > #ChaosNicknames.availableNicknames then
        return "", { r = 1.00, g = 0.00, b = 0.00 }
    end

    local nickname = ChaosNicknames.availableNicknames[randomIndex].name
    local color = ChaosNicknames.availableNicknames[randomIndex].color
    return nickname, color
end

---@param zombie IsoZombie
---@return string nickname, ChaosZombieNicknameColor color
function ChaosNicknames.ensureZombieNicknameAndColor(zombie)
    if not zombie then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    local md = zombie:getModData()
    if not md then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    if not md[ChaosNicknames.modDataNameKey] or not md[ChaosNicknames.modDataColorKey] then
        local newName, newColor = ChaosNicknames.GetRandomNickname()
        md[ChaosNicknames.modDataNameKey] = newName
        md[ChaosNicknames.modDataColorKey] = newColor
    end
    return md[ChaosNicknames.modDataNameKey], md[ChaosNicknames.modDataColorKey]
end

---@param zombie IsoZombie
function ChaosNicknames.RenderNickname(zombie)
    if not zombie then return end
    if zombie:isDead() then return end

    -- Nicknames not loaded
    if ChaosNicknames.availableNicknames == nil or #ChaosNicknames.availableNicknames == 0 then
        return
    end

    local player = getPlayer()
    if not player then
        return
    end

    local playerX = player:getX()
    local playerY = player:getY()

    local maxDist = 15 -- meters

    local zombieX = zombie:getX()
    local zombieY = zombie:getY()

    -- Zombie is not in range
    if not ChaosUtils.isInRange(playerX, playerY, zombieX, zombieY, maxDist) then
        return
    end


    -- Player can't see zombie, hide nickname
    if not ChaosZombie.CanPlayerSeeZombie(player, zombie, true, true) then
        zombie:addLineChatElement("")
        return
    end

    -- Get nickname and color from zombie save data or generate new one
    local name, color = ChaosNicknames.ensureZombieNicknameAndColor(zombie)
    if not color then
        color = { r = 1.00, g = 0.00, b = 0.00 }
    end

    local nicknameString = string.format("%s", name)

    -- Show nickname for visible zombies
    if zombie.addLineChatElement then
        zombie:addLineChatElement(nicknameString, color.r, color.g, color.b)
    end
end
