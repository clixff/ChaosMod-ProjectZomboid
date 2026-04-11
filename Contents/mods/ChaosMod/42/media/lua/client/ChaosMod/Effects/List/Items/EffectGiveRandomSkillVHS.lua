EffectGiveRandomSkillVHS = ChaosEffectBase:derive("EffectGiveRandomSkillVHS", "give_random_skill_vhs")

---@param codes string
local function hasSkillCode(codes)
    if not codes or codes == "" then return false end
    for _, part in ipairs(string.split(codes, ",")) do
        local code = string.sub(part, 1, 3)
        if code ~= "BOR" then return true end
    end
    return false
end

---@return table<integer, { id: string, type: boolean }>
local function getSkillVHSList()
    local results = {}
    local recordedMedia = ZomboidRadio.getInstance():getRecordedMedia()
    local categories = { "Retail-VHS", "Home-VHS" }

    for _, cat in ipairs(categories) do
        local mediaList = recordedMedia:getAllMediaForCategory(cat)
        if mediaList then
            for i = 0, mediaList:size() - 1 do
                local media = mediaList:get(i)
                local lines = media:getLineCount()
                for j = 0, lines - 1 do
                    local line = media:getLine(j)
                    if hasSkillCode(line:getCodes()) then
                        table.insert(results, { id = media:getId(), type = cat == "Retail-VHS" })
                        break
                    end
                end
            end
        end
    end

    return results
end

function EffectGiveRandomSkillVHS:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomSkillVHS] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local vhsTable = getSkillVHSList()
    if #vhsTable == 0 then return end

    local randomIndex = math.floor(ZombRand(1, #vhsTable + 1))
    local randomVHSData = vhsTable[randomIndex]
    if not randomVHSData then return end

    local itemId = randomVHSData.type and "Base.VHS_Retail" or "Base.VHS_Home"

    local item = inventory:AddItem(itemId)
    if not item then return end


    print("[EffectGiveRandomSkillVHS] Giving VHS: " .. randomVHSData.id)

    local recordedMedia = ZomboidRadio.getInstance():getRecordedMedia()
    local mediaData = recordedMedia:getMediaData(randomVHSData.id)
    if not mediaData then return end

    item:setRecordedMediaData(mediaData)

    ChaosPlayer.SayLineNewItem(player, item, 1)
end
