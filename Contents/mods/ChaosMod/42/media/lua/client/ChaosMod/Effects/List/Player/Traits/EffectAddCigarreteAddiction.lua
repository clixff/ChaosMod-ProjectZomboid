---@class EffectAddCigarreteAddiction : ChaosEffectBase
EffectAddCigarreteAddiction = ChaosEffectBase:derive("EffectAddCigarreteAddiction", "add_cigarrete_addiction")

function EffectAddCigarreteAddiction:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local traits = player:getCharacterTraits()

    local traitName = CharacterTrait.SMOKER

    if not traits:get(traitName) then
        traits:add(traitName)
    end
end

function EffectAddCigarreteAddiction:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
