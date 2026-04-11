---@class EffectInvisibleCharacters : ChaosEffectBase
EffectInvisibleCharacters = ChaosEffectBase:derive("EffectInvisibleCharacters", "invisible_characters")

---@param character IsoGameCharacter
local function handleCharacterUpdate(character)
    if not character then return end
    if character:isSceneCulled() then return end
    character:setTargetAlpha(0)
end

function EffectInvisibleCharacters:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnPlayerUpdate.Add(handleCharacterUpdate)
    Events.OnZombieUpdate.Add(handleCharacterUpdate)
end

---@param deltaMs integer
function EffectInvisibleCharacters:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectInvisibleCharacters:OnEnd()
    ChaosEffectBase:OnEnd()

    Events.OnPlayerUpdate.Remove(handleCharacterUpdate)
    Events.OnZombieUpdate.Remove(handleCharacterUpdate)
end
