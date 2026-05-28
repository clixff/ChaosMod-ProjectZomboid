---@class EffectKillZombiesWithLightning : ChaosEffectBase
EffectKillZombiesWithLightning = ChaosEffectBase:derive("EffectKillZombiesWithLightning", "kill_zombies_with_lightning")

local RADIUS = 50

function EffectKillZombiesWithLightning:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    local killedCount = 0

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or not zombie:isAlive() then return end

        local sq = zombie:getSquare()
        if not sq then return end

        ChaosUtils.SpawnLightningStrikeAt(sq:getX(), sq:getY(), sq:getZ(), false, false, false, false, false)

        zombie:setOnFire(true)
        zombie:Kill(getFakeAttacker())


        killedCount = killedCount + 1
    end, true, nil)

    getClimateManager():getThunderStorm():triggerThunderEvent(
        px, py,
        true, -- doStrike: plays "Thunder"
        true, -- doLightning: visual flash
        false -- doRumble
    )
end

function EffectKillZombiesWithLightning:OnEnd()
    ChaosEffectBase:OnEnd()
end
