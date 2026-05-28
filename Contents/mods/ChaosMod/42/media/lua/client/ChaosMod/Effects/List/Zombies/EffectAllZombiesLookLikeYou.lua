---@class EffectAllZombiesLookLikeYou : ChaosEffectBase
EffectAllZombiesLookLikeYou = ChaosEffectBase:derive("EffectAllZombiesLookLikeYou", "all_zombies_look_like_you")

function EffectAllZombiesLookLikeYou:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 80
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if zombie:isDead() then return end
        ChaosZombie.CopyAppearanceToNormalZombie(player, zombie)
        updatedCount = updatedCount + 1
    end, true, z)

    print("[EffectAllZombiesLookLikeYou] Updated " .. tostring(updatedCount) .. " zombies")
end

function EffectAllZombiesLookLikeYou:OnEnd()
    ChaosEffectBase:OnEnd()
end
