---@class EffectZombiesCantSeeYou : ChaosEffectBase
---@field affectedZombies table<IsoZombie, boolean>
EffectZombiesCantSeeYou = ChaosEffectBase:derive("EffectZombiesCantSeeYou", "zombies_cant_see_you")

function EffectZombiesCantSeeYou:OnStart()
    ChaosEffectBase:OnStart()
    self.affectedZombies = {}
end

function EffectZombiesCantSeeYou:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local px, py, pz = player:getX(), player:getY(), player:getZ()
    ChaosZombie.ForEachZombieInRange(px, py, 30, function(zombie)
        if zombie and zombie:getTarget() == player then
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setTarget(nil)
            zombie:setTargetSeenTime(0)
        end
        if zombie and not self.affectedZombies[zombie] then
            zombie:setUseless(true)
            self.affectedZombies[zombie] = true
        end
    end, true, pz)
end

function EffectZombiesCantSeeYou:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.affectedZombies then
        for zombie, _ in pairs(self.affectedZombies) do
            if zombie then
                zombie:setUseless(false)
            end
        end
        self.affectedZombies = nil
    end
end
