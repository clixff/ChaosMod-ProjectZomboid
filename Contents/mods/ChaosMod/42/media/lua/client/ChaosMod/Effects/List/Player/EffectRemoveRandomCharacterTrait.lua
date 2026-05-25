---@class EffectRemoveRandomCharacterTrait : ChaosEffectBase
EffectRemoveRandomCharacterTrait = ChaosEffectBase:derive("EffectRemoveRandomCharacterTrait", "remove_random_character_trait")

function EffectRemoveRandomCharacterTrait:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local trait = ChaosTraits.RemoveRandomTrait(player)
    if not trait then return end

    local label = ChaosTraits.GetTraitLabel(trait)
    ChaosPlayer.SayLineByColor(player, "-" .. label, ChaosPlayerChatColors.green)
end
