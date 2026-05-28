---@class EffectZombiesTPose : ChaosEffectBase
---@field affectedZombies table<IsoZombie, boolean>
EffectZombiesTPose = ChaosEffectBase:derive("EffectZombiesTPose", "zombies_tpose")

local RANGE = 30

function EffectZombiesTPose:OnStart()
    ChaosEffectBase:OnStart()
    self.affectedZombies = {}
end

function EffectZombiesTPose:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end

    local x, y = player:getX(), player:getY()

    ChaosZombie.ForEachZombieInRange(x, y, RANGE, function(zombie)
        if not self.affectedZombies[zombie] then
            self.affectedZombies[zombie] = true
        end
        zombie:setBumpType("ZombieTPose")
    end)
end

function EffectZombiesTPose:OnEnd()
    ChaosEffectBase:OnEnd()
    for zombie, _ in pairs(self.affectedZombies) do
        if not zombie:isDead() then
            zombie:setBumpType("")
        end
    end
    self.affectedZombies = {}
end
