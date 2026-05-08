EffectStartFire = ChaosEffectBase:derive("EffectStartFire", "start_fire")

local FIRE_COUNT = 8
local MIN_DISTANCE = 3
local MAX_DISTANCE = 8
local MAX_TRIES = 50

function EffectStartFire:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local z = square:getZ()

    for _ = 1, FIRE_COUNT do
        local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, z, MIN_DISTANCE, MAX_DISTANCE, MAX_TRIES, true, true,
            false)
        if sq then
            IsoFireManager.StartFire(getCell(), sq, true, 100)
        end
    end
end
