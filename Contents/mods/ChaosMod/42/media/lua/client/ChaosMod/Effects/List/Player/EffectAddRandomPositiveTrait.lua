---@class EffectAddRandomPositiveTrait : ChaosEffectBase
EffectAddRandomPositiveTrait = ChaosEffectBase:derive("EffectAddRandomPositiveTrait", "add_random_positive_trait")

function EffectAddRandomPositiveTrait:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local trait = ChaosTraits.AddRandomPositiveTrait(player)
    if not trait then return end

    local label = ChaosTraits.GetTraitLabel(trait)
    ChaosPlayer.SayLineByColor(player, "+" .. label, ChaosPlayerChatColors.green)
end
