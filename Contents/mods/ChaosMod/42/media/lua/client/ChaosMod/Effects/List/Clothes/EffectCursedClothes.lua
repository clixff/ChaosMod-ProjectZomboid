---@class EffectCursedClothes : ChaosEffectBase
---@field elapsedMs integer
EffectCursedClothes = ChaosEffectBase:derive("EffectCursedClothes", "cursed_clothes")

local DAMAGE_DELAY_MS = 5000
local DAMAGE_PER_SECOND = 100.0 / (4 * 60)

function EffectCursedClothes:OnStart()
    ChaosEffectBase:OnStart()
    self.elapsedMs = 0
end

---@param deltaMs integer
function EffectCursedClothes:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.elapsedMs = self.elapsedMs + deltaMs
    if self.elapsedMs < DAMAGE_DELAY_MS then return end

    local worn = player:getWornItems()
    if not worn or worn:size() == 0 then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    bodyDamage:ReduceGeneralHealth((deltaMs / 1000) * DAMAGE_PER_SECOND)
end

function EffectCursedClothes:OnEnd()
    ChaosEffectBase:OnEnd()
end
