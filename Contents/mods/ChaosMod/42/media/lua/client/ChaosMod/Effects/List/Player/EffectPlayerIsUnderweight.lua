---@class EffectPlayerIsUnderweight : ChaosEffectBase
EffectPlayerIsUnderweight = ChaosEffectBase:derive("EffectPlayerIsUnderweight", "player_is_underweight")

function EffectPlayerIsUnderweight:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    local weight = nutrition:getWeight()
    if weight > 55 then
        weight = 55
        nutrition:setWeight(weight)
        nutrition:applyTraitFromWeight()
    end

    player:Say(string.format(ChaosLocalization.GetString("misc", "new_weight"), ChaosUtils.FormatWeight(weight)))
end
