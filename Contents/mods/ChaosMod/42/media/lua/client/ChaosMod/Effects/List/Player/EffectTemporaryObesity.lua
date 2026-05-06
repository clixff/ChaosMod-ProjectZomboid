---@class EffectTemporaryObesity : ChaosEffectBase
---@field originalWeight number
EffectTemporaryObesity = ChaosEffectBase:derive("EffectTemporaryObesity", "temporary_obesity")

function EffectTemporaryObesity:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local nutrition = player:getNutrition()
    self.originalWeight = nutrition:getWeight()

    local weight = self.originalWeight
    if weight < 100 then
        weight = 100
        nutrition:setWeight(weight)
        nutrition:applyTraitFromWeight()
    end

    ChaosPlayer.SayLineByColor(player, string.format("Temporary obesity: %s", ChaosUtils.FormatWeight(weight)),
        ChaosPlayerChatColors.red)
end

function EffectTemporaryObesity:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    if not self.originalWeight then return end

    local nutrition = player:getNutrition()
    nutrition:setWeight(self.originalWeight)
    nutrition:applyTraitFromWeight()
    ChaosPlayer.SayLineByColor(player, string.format("Weight restored: %s", ChaosUtils.FormatWeight(self.originalWeight)),
        ChaosPlayerChatColors.green)
end
