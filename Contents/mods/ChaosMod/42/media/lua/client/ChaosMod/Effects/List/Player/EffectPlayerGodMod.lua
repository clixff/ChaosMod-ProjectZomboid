---@class EffectPlayerGodMod : ChaosEffectBase
---@field previousGodMod boolean
EffectPlayerGodMod = ChaosEffectBase:derive("EffectPlayerGodMod", "player_god_mod")

function EffectPlayerGodMod:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.previousGodMod = player:isGodMod()
    player:setGodMod(true, true)
end

function EffectPlayerGodMod:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    player:setGodMod(self.previousGodMod, true)
end
