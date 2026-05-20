---@class EffectZombiesCanSmellYou : ChaosEffectBase
---@field timerMs integer
EffectZombiesCanSmellYou = ChaosEffectBase:derive("EffectZombiesCanSmellYou", "zombies_can_smell_you")

local AGGRO_INTERVAL_MS = 5000
local AGGRO_RADIUS = 30

local function attractZombies()
    local player = getPlayer()
    if not player then return end

    local pxFloat = player:getX()
    local pyFloat = player:getY()

    ChaosZombie.ForEachZombieInRange(pxFloat, pyFloat, AGGRO_RADIUS, function(zombie)
        if zombie and zombie:isAlive() and zombie:getTarget() ~= player then
            print("Aggro zombie")
            zombie:setTarget(player)
            zombie:pathToCharacter(player)
            zombie:spotted(player, true)
            -- ChaosZombie.MoveToPlayerSpotted(zombie, player)
        end
    end, true, nil)


    print("[EffectZombiesCanSmellYou] Attracted zombies around player")
end

function EffectZombiesCanSmellYou:OnStart()
    ChaosEffectBase:OnStart()

    self.timerMs = 0

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    ---@diagnostic disable-next-line: param-type-mismatch
    addSound(nil, px, py, pz, AGGRO_RADIUS, 100)
    attractZombies()
end

function EffectZombiesCanSmellYou:OnTick(deltaMs)
    self.timerMs = (self.timerMs or 0) + (deltaMs or 0)
    while self.timerMs >= AGGRO_INTERVAL_MS do
        self.timerMs = self.timerMs - AGGRO_INTERVAL_MS
        attractZombies()
    end
end
