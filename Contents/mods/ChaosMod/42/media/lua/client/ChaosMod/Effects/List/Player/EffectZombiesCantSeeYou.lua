---@class EffectZombiesCantSeeYou : ChaosEffectBase
---@field previousInvisible boolean
EffectZombiesCantSeeYou = ChaosEffectBase:derive("EffectZombiesCantSeeYou", "zombies_cant_see_you")

function EffectZombiesCantSeeYou:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.previousInvisible = player:isInvisible()
    player:setInvisible(true, true)
end

function EffectZombiesCantSeeYou:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    player:setInvisible(self.previousInvisible, true)
end
