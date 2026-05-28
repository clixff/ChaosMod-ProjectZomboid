---@class EffectInvisibleCharacters : ChaosEffectBase
EffectInvisibleCharacters = ChaosEffectBase:derive("EffectInvisibleCharacters", "invisible_characters")

local MAX_DIST = 25

---@param zombie IsoZombie
local function handleZombieUpdate(zombie)
    if not zombie then return end

    local player = getPlayer()
    if not player then return end
    if not ChaosUtils.isInRange(player:getX(), player:getY(), zombie:getX(), zombie:getY(), MAX_DIST) then
        return
    end

    zombie:setTargetAlpha(0.0)
end

function EffectInvisibleCharacters:OnStart()
    ChaosEffectBase:OnStart()
    getCore():setDisplayPlayerModel(false)
    Events.OnZombieUpdate.Add(handleZombieUpdate)
end

---@param deltaMs integer
function EffectInvisibleCharacters:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local cell = getCell()
    if not cell then return end

    local allZombies = cell:getZombieList()
    if not allZombies then return end

    local px = player:getX()
    local py = player:getY()

    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and ChaosUtils.isInRange(px, py, zombie:getX(), zombie:getY(), MAX_DIST) then
            zombie:addLineChatElement("")
        end
    end
end

function EffectInvisibleCharacters:OnEnd()
    ChaosEffectBase:OnEnd()

    getCore():setDisplayPlayerModel(true)
    Events.OnZombieUpdate.Remove(handleZombieUpdate)
end
