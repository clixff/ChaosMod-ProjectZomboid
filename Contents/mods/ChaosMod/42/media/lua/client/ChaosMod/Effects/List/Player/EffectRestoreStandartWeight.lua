---@class EffectRestoreStandartWeight : ChaosEffectBase
EffectRestoreStandartWeight = ChaosEffectBase:derive("EffectRestoreStandartWeight", "restore_standart_weight")

function EffectRestoreStandartWeight:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    local weight = 80
    nutrition:setWeight(weight)
    nutrition:applyTraitFromWeight()

    player:Say(string.format(ChaosLocalization.GetString("misc", "new_weight"), ChaosUtils.FormatWeight(weight)))
end
