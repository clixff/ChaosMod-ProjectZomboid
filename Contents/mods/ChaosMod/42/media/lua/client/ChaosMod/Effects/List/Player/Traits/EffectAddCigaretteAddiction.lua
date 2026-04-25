---@class EffectAddCigaretteAddiction : ChaosEffectBase
EffectAddCigaretteAddiction = ChaosEffectBase:derive("EffectAddCigaretteAddiction", "add_cigarette_addiction")

function EffectAddCigaretteAddiction:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local traits = player:getCharacterTraits()

    local traitName = CharacterTrait.SMOKER

    if not traits:get(traitName) then
        traits:add(traitName)
    end
end

function EffectAddCigaretteAddiction:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
