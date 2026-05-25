---@class EffectFemaleZombiesSpottedYou : ChaosEffectBase
EffectFemaleZombiesSpottedYou = ChaosEffectBase:derive("EffectFemaleZombiesSpottedYou", "female_zombies_spotted_you")

function EffectFemaleZombiesSpottedYou:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ChaosZombie.ForEachZombieInRange(px, py, 50, function(zombie)
        if zombie and zombie:isAlive() and zombie:isFemale() then
            -- ChaosZombie.MoveToPlayerSpotted(zombie, player)
            zombie:pathToSound(px, py, pz)

            zombie:setLastHeardSound(px, py, pz)
        end
    end, true, nil)
end

function EffectFemaleZombiesSpottedYou:OnEnd()
    ChaosEffectBase:OnEnd()
end
