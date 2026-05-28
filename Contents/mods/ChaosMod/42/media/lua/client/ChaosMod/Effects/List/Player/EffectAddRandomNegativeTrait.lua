---@class EffectAddRandomNegativeTrait : ChaosEffectBase
EffectAddRandomNegativeTrait = ChaosEffectBase:derive("EffectAddRandomNegativeTrait", "add_random_negative_trait")

function EffectAddRandomNegativeTrait:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local trait = ChaosTraits.AddRandomNegativeTrait(player)
    if not trait then return end

    local label = ChaosTraits.GetTraitLabel(trait)
    ChaosPlayer.SayLineByColor(player, "+" .. label, ChaosPlayerChatColors.red)
end
