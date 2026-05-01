---@class EffectDisableAttack : ChaosEffectBase
---@field previousBannedAttacking boolean
EffectDisableAttack = ChaosEffectBase:derive("EffectDisableAttack", "disable_attack")

function EffectDisableAttack:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player or not player.setBannedAttacking then return end

    if player.isBannedAttacking then
        self.previousBannedAttacking = player:isBannedAttacking()
    else
        self.previousBannedAttacking = false
    end

    player:setBannedAttacking(true)
end

function EffectDisableAttack:OnTick(_deltaMs)
    local player = getPlayer()
    if not player or not player.setBannedAttacking then return end

    player:setBannedAttacking(true)
end

function EffectDisableAttack:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player or not player.setBannedAttacking then return end

    player:setBannedAttacking(self.previousBannedAttacking == true)
end
