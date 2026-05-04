---@class EffectPlayerIsObese : ChaosEffectBase
EffectPlayerIsObese = ChaosEffectBase:derive("EffectPlayerIsObese", "player_is_obese")

function EffectPlayerIsObese:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    local weight = nutrition:getWeight()
    if weight < 100 then
        weight = 100
        nutrition:setWeight(weight)
        nutrition:applyTraitFromWeight()
    end

    player:Say(string.format(ChaosLocalization.GetString("misc", "new_weight"), ChaosUtils.FormatWeight(weight)))
end
