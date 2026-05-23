---@class EffectInvisibleCharacters : ChaosEffectBase
EffectInvisibleCharacters = ChaosEffectBase:derive("EffectInvisibleCharacters", "invisible_characters")

local MAX_DIST = 25

---@param character IsoGameCharacter
local function handleCharacterUpdate(character)
    if not character then return end

    if instanceof(character, "IsoZombie") then
        local player = getPlayer()
        if not player then return end
        if not ChaosUtils.isInRange(player:getX(), player:getY(), character:getX(), character:getY(), MAX_DIST) then
            return
        end
    end

    character:setTargetAlpha(0.0)
end

function EffectInvisibleCharacters:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnPlayerUpdate.Add(handleCharacterUpdate)
    Events.OnZombieUpdate.Add(handleCharacterUpdate)
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

    Events.OnPlayerUpdate.Remove(handleCharacterUpdate)
    Events.OnZombieUpdate.Remove(handleCharacterUpdate)
end
