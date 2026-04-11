EffectPlayerLoseWeight = ChaosEffectBase:derive("EffectPlayerLoseWeight", "player_lose_weight")

function EffectPlayerLoseWeight:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()

    local weight = nutrition:getWeight()
    weight = weight - 3.5
    nutrition:setWeight(weight)
    nutrition:applyTraitFromWeight()

    player:Say("New weight: " .. ChaosUtils.FormatWeight(weight))
end
