---@class EffectBlurryVision : ChaosEffectBase
---@field previousTraitValue boolean
EffectBlurryVision = ChaosEffectBase:derive("EffectBlurryVision", "blurry_vision")

local function updateVisuals()
    local player = getPlayer()
    player:updateVisionEffects()
    player:updateVisionEffectTargets()
end

local traitName = CharacterTrait.SHORT_SIGHTED
function EffectBlurryVision:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local traits = player:getCharacterTraits()

    self.previousTraitValue = traits:get(traitName) or false

    traits:set(traitName, true)
    updateVisuals()
end

function EffectBlurryVision:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    local traits = player:getCharacterTraits()
    if not traits then return end


    traits:set(traitName, self.previousTraitValue)
    updateVisuals()
end
