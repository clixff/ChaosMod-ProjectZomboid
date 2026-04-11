---@class EffectAddPermanentAsthma : ChaosEffectBase
EffectAddPermanentAsthma = ChaosEffectBase:derive("EffectAddPermanentAsthma", "add_permanent_asthma")

function EffectAddPermanentAsthma:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local traits = player:getCharacterTraits()

    local traitName = CharacterTrait.ASTHMATIC

    if not traits:get(traitName) then
        traits:add(traitName)
    end
end

function EffectAddPermanentAsthma:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
