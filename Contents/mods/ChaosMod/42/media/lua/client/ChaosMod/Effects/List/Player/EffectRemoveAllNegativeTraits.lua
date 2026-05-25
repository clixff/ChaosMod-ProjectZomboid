---@class EffectRemoveAllNegativeTraits : ChaosEffectBase
EffectRemoveAllNegativeTraits = ChaosEffectBase:derive("EffectRemoveAllNegativeTraits", "remove_all_negative_traits")

function EffectRemoveAllNegativeTraits:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local removed = ChaosTraits.RemoveAllNegativeTraits(player)
    if removed <= 0 then return end

    local text = string.format(ChaosLocalization.GetString("misc", "traits_removed_count"), removed)
    ChaosPlayer.SayLineByColor(player, text, ChaosPlayerChatColors.green)
end
