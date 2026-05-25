---@class EffectAddRandomCharacterTrait : ChaosEffectBase
EffectAddRandomCharacterTrait = ChaosEffectBase:derive("EffectAddRandomCharacterTrait", "add_random_character_trait")

function EffectAddRandomCharacterTrait:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local wantPositive = ChaosUtils.RandInteger(2) == 0
    local trait = ChaosTraits.AddRandomTrait(player, wantPositive)
    if not trait then
        trait = ChaosTraits.AddRandomTrait(player, not wantPositive)
        if not trait then return end
        wantPositive = not wantPositive
    end

    local label = ChaosTraits.GetTraitLabel(trait)
    local color = wantPositive and ChaosPlayerChatColors.green or ChaosPlayerChatColors.red
    ChaosPlayer.SayLineByColor(player, "+" .. label, color)
end
