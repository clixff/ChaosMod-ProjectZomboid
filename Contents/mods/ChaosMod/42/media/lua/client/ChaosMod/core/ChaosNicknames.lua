---@class ChaosZombieNicknameColor
---@field r number
---@field g number
---@field b number

---@class ChaosNicknameEntry
---@field name string
---@field color ChaosZombieNicknameColor
---@field chatMessage string|nil
---@field externalTimestampMs integer
---@field internalTimestampMs integer

---@class ChaosNicknameRawData
---@field name string
---@field color table<integer, integer>

---@class ChaosNicknames
---@field availableNicknames table<integer, ChaosNicknameEntry>
---@field availableNicknamesByName table<string, ChaosNicknameEntry>
---@field updateTickCounter integer
---@field modDataNameKey string
---@field modDataColorKey string
ChaosNicknames = ChaosNicknames or {
    availableNicknames = {},
    availableNicknamesByName = {},
    updateTickCounter = 0,
    visibleZombiesForLabel = {},

    modDataNameKey = "ChaosModNickname",
    modDataColorKey = "ChaosModNicknameColor"
}

local NICKNAME_CHAT_MESSAGE_MAX_AGE_MS = 30000
local NICKNAME_CHAT_MESSAGE_RENDER_MS = 7000
local NICKNAME_CHAT_MESSAGE_FADE_MS = 1000
local NICKNAME_CHAT_MESSAGE_WRAP_CHARS = 50
local NICKNAME_CHAT_MESSAGE_LIMIT_CHARS = 150

---@param s string
---@return string nickname, string rgb, string|nil chatMessage, integer|nil chatMessageTimestampMs
local function parseNicknameLine(s)
    -- split by first "/" into nickname + "255,127,80[/message[/timestamp]]"
    local nickname, rest = s:match("^([^/]+)/(.+)$")
    if not nickname or not rest then
        return "", "", nil, nil
    end

    local rgb, suffix = rest:match("^([^/]+)/*(.*)$")
    if not rgb then
        return nickname, "", nil, nil
    end

    if suffix == "" or suffix == nil then
        return nickname, rgb, nil, nil
    end

    local chatMessage, timestampString = suffix:match("^(.*)/([^/]*)$")
    if not chatMessage then
        return nickname, rgb, suffix, nil
    end

    local timestampMs = tonumber(timestampString)
    if not timestampMs then
        return nickname, rgb, suffix, nil
    end

    return nickname, rgb, chatMessage, math.floor(timestampMs)
end

---@param rgb string
---@return integer r, integer g, integer b
local function parseRgbColor(rgb)
    if not rgb or rgb == "" then
        return 0, 0, 0
    end

    -- extract 3 numbers (allows spaces too)
    local r, g, b = rgb:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if not r then
        return 255, 0, 0
    end

    local rInt = math.floor(tonumber(r) or 255)
    local gInt = math.floor(tonumber(g) or 0)
    local bInt = math.floor(tonumber(b) or 0)
    return rInt, gInt, bInt
end

---@param r integer
---@param g integer
---@param b integer
---@return ChaosZombieNicknameColor
local function convertIntegerColorsToFloat(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

---@param s string
---@return table<integer, string>
local function splitUtf8Chars(s)
    local chars = {}
    local i = 1
    local len = string.len(s)

    while i <= len do
        local firstByte = string.byte(s, i)
        if not firstByte then
            break
        end

        local charLen = 1
        if firstByte >= 240 then
            charLen = 4
        elseif firstByte >= 224 then
            charLen = 3
        elseif firstByte >= 192 then
            charLen = 2
        end

        if i + charLen - 1 > len then
            charLen = 1
        end

        local char = string.sub(s, i, i + charLen - 1)
        table.insert(chars, char)
        i = i + charLen
    end

    return chars
end

---@param text string|nil
---@return string|nil
local function formatChatMessage(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    local chars = splitUtf8Chars(text)
    if #chars == 0 then
        return nil
    end

    if #chars > NICKNAME_CHAT_MESSAGE_LIMIT_CHARS then
        while #chars > NICKNAME_CHAT_MESSAGE_LIMIT_CHARS do
            table.remove(chars)
        end
    end

    local lines = {}
    local currentLine = {}
    for i, char in ipairs(chars) do
        table.insert(currentLine, char)
        if #currentLine >= NICKNAME_CHAT_MESSAGE_WRAP_CHARS or i == #chars then
            table.insert(lines, table.concat(currentLine))
            currentLine = {}
        end
    end

    local formatted = table.concat(lines, "\n")
    if formatted == "" then
        return nil
    end

    return formatted
end

---@param entry ChaosNicknameEntry|nil
---@param nowMs integer
---@return string|nil, integer, integer
local function resolveChatMessageState(entry, nowMs)
    if not entry or not entry.chatMessage or entry.chatMessage == "" then
        return nil, 0, 0
    end

    if not ChaosConfig.streamer_mode or ChaosConfig.streamer_mode.render_chat_messages ~= true then
        return nil, 0, 0
    end

    if not entry.internalTimestampMs or entry.internalTimestampMs <= 0 then
        return nil, 0, 0
    end

    local elapsedMs = nowMs - entry.internalTimestampMs
    if elapsedMs < 0 or elapsedMs >= NICKNAME_CHAT_MESSAGE_RENDER_MS then
        return nil, elapsedMs, 0
    end

    local alpha = 1
    local fadeStartMs = NICKNAME_CHAT_MESSAGE_RENDER_MS - NICKNAME_CHAT_MESSAGE_FADE_MS
    if elapsedMs > fadeStartMs then
        alpha = 1 - ((elapsedMs - fadeStartMs) / NICKNAME_CHAT_MESSAGE_FADE_MS)
        if alpha < 0 then
            alpha = 0
        end
    end

    return entry.chatMessage, elapsedMs, alpha
end

function ChaosNicknames.LoadNicknamesFromDisk()
    ChaosNicknames.updateTickCounter = 0
    local path = "ChaosMod/Nicknames.txt"

    local lines = ChaosFileReader.ReadFileArrayFromCacheAllLines(path)

    if not lines then
        print("[ChaosNicknames] Failed to load nicknames from disk")
        return
    end

    local nowMs = getTimestampMs()
    local previousNicknamesByName = ChaosNicknames.availableNicknamesByName or {}
    ChaosNicknames.availableNicknames = {}
    ChaosNicknames.availableNicknamesByName = {}

    local totalNicknames = 0

    -- Add new nickname by line
    for _, line in ipairs(lines) do
        local nickname, rgb, chatMessage, externalTimestampMs = parseNicknameLine(line)
        if nickname and nickname ~= "" then
            local previousEntry = previousNicknamesByName[nickname]
            local r, g, b = parseRgbColor(rgb)
            local color = convertIntegerColorsToFloat(r, g, b)
            if color then
                ---@type ChaosNicknameEntry
                local entry = {
                    name = nickname,
                    color = color,
                    chatMessage = nil,
                    externalTimestampMs = 0,
                    internalTimestampMs = 0
                }

                if chatMessage and externalTimestampMs and externalTimestampMs > 0 then
                    local messageAgeMs = nowMs - externalTimestampMs
                    if messageAgeMs >= 0 and messageAgeMs <= NICKNAME_CHAT_MESSAGE_MAX_AGE_MS then
                        print("[ChaosNicknames] Raw message is " .. tostring(chatMessage))
                        entry.chatMessage = formatChatMessage(chatMessage)
                        print("[ChaosNicknames] Formatted message is " .. tostring(entry.chatMessage))
                        if entry.chatMessage then
                            entry.externalTimestampMs = externalTimestampMs
                            if previousEntry and previousEntry.externalTimestampMs == externalTimestampMs and previousEntry.internalTimestampMs then
                                entry.internalTimestampMs = previousEntry.internalTimestampMs
                            else
                                entry.internalTimestampMs = nowMs
                                print("[ChaosNicknames] Loaded new chat message for nickname '" ..
                                    tostring(nickname) .. "' with timestamp " .. tostring(externalTimestampMs))
                            end
                        end
                    end
                end

                table.insert(ChaosNicknames.availableNicknames, entry)
                ChaosNicknames.availableNicknamesByName[nickname] = entry
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
---@return boolean, IsoPlayer?
local function shouldRenderZombieNickname(zombie)
    if not zombie then return false, nil end
    if zombie:isDead() then return false, nil end

    if ChaosNicknames.availableNicknames == nil or #ChaosNicknames.availableNicknames == 0 then
        return false, nil
    end

    local player = getPlayer()
    if not player then
        return false, nil
    end

    local playerX = player:getX()
    local playerY = player:getY()
    local maxDist = 15

    local zombieX = zombie:getX()
    local zombieY = zombie:getY()

    if not ChaosUtils.isInRange(playerX, playerY, zombieX, zombieY, maxDist) then
        return false, player
    end

    if not ChaosZombie.CanPlayerSeeZombie(player, zombie, true, true) then
        return false, player
    end

    return true, player
end

---@param zombie IsoZombie
local function trackZombieLabel(zombie)
    local id = zombie:getOnlineID()
    if not id or id < 0 then
        id = tostring(zombie)
    end

    ChaosNicknames.visibleZombiesForLabel[id] = zombie
end

---@param text string
---@param font UIFont
---@return number width, integer lineCount
local function measureMultilineText(text, font)
    local tm = getTextManager()
    local maxWidth = 0
    local lineCount = 0

    local textWithSentinel = text .. "\n"
    for line in string.gmatch(textWithSentinel, "(.-)\n") do
        local width = tm:MeasureStringX(font, line)
        if width > maxWidth then
            maxWidth = width
        end
        lineCount = lineCount + 1
    end

    if lineCount <= 0 then
        lineCount = 1
    end

    return maxWidth, lineCount
end

---@param zombie IsoZombie
---@param text string
---@param playerNum integer
---@param alpha number|nil
local function drawZombieLabel(zombie, text, playerNum, alpha)
    if not zombie or zombie:isDead() then return end
    if zombie:getTargetAlpha(0) < 0.5 then return end

    local z = zombie:getZ() + 0.8
    local sx = isoToScreenX(playerNum, zombie:getX(), zombie:getY(), z)
    local sy = isoToScreenY(playerNum, zombie:getX(), zombie:getY(), z)

    local font = UIFont.Dialogue
    local w, lineCount = measureMultilineText(text, font)

    sx = sx - w / 2
    sy = sy - (20 * lineCount)

    -- print("Rendering text " .. text)
    getTextManager():DrawString(font, sx, sy, text, 1, 1, 1, alpha or 0.8)
end

---@param nickname string
---@return ChaosNicknameEntry|nil
local function getNicknameEntryByName(nickname)
    if nickname == "" then
        return nil
    end

    return ChaosNicknames.availableNicknamesByName[nickname]
end

---@param zombie IsoZombie
function ChaosNicknames.RenderNickname(zombie)
    local shouldRender = shouldRenderZombieNickname(zombie)
    if not shouldRender then
        if zombie and zombie.addLineChatElement then
            zombie:addLineChatElement("")
        end
        return
    end

    -- Get nickname and color from zombie save data or generate new one
    local name, color = ChaosNicknames.ensureZombieNicknameAndColor(zombie)
    if not color then
        color = { r = 1.00, g = 0.00, b = 0.00 }
    end

    local nicknameString = string.format("%s", name)
    trackZombieLabel(zombie)

    -- Show nickname for visible zombies
    if zombie.addLineChatElement then
        zombie:addLineChatElement(nicknameString, color.r, color.g, color.b)
    end
end

function ChaosNicknames.OnPreUIDraw()
    if ChaosMod.enabled == false then
        ChaosNicknames.visibleZombiesForLabel = {}
        return
    end

    if not ChaosConfig.IsZombieNicknamesEnabled() then
        ChaosNicknames.visibleZombiesForLabel = {}
        return
    end

    local zombiesToDraw = ChaosNicknames.visibleZombiesForLabel
    ChaosNicknames.visibleZombiesForLabel = {}

    local nowMs = getTimestampMs()
    for _, zombie in pairs(zombiesToDraw) do
        local shouldRender = shouldRenderZombieNickname(zombie)
        if shouldRender then
            local md = zombie:getModData()
            local nickname = ""
            if md then
                nickname = md[ChaosNicknames.modDataNameKey] or ""
            end
            local entry = getNicknameEntryByName(nickname)
            local chatMessage, _, alpha = resolveChatMessageState(entry, nowMs)
            if chatMessage and alpha > 0 then
                drawZombieLabel(zombie, chatMessage, 0, alpha)
            end
        end
    end
end

Events.OnPreUIDraw.Add(ChaosNicknames.OnPreUIDraw)
