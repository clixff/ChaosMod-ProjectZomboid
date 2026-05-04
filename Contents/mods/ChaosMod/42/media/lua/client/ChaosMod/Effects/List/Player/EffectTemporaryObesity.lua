---@class EffectTemporaryObesity : ChaosEffectBase
---@field originalWeight number
EffectTemporaryObesity = ChaosEffectBase:derive("EffectTemporaryObesity", "temporary_obesity")

function EffectTemporaryObesity:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    self.originalWeight = nutrition:getWeight()

    if self.originalWeight < 100 then
        nutrition:setWeight(100)
        nutrition:applyTraitFromWeight()
        player:Say(string.format(ChaosLocalization.GetString("misc", "new_weight"), ChaosUtils.FormatWeight(100)))
    end
end

function EffectTemporaryObesity:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    nutrition:setWeight(self.originalWeight)
    nutrition:applyTraitFromWeight()
    player:Say(string.format(ChaosLocalization.GetString("misc", "new_weight"), ChaosUtils.FormatWeight(self.originalWeight)))
end
