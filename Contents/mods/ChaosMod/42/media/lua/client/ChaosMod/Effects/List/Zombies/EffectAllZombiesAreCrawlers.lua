---@class EffectAllZombiesAreCrawlers : ChaosEffectBase
EffectAllZombiesAreCrawlers = ChaosEffectBase:derive("EffectAllZombiesAreCrawlers", "all_zombies_are_crawlers")

local RADIUS = 50

function EffectAllZombiesAreCrawlers:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end

        zombie:setCrawler(true)
        zombie:setCanWalk(false)
        zombie:setOnFloor(true)
        zombie:setKnockedDown(true)
        zombie:setFallOnFront(true)
        zombie:setCrawlerType(1)
        zombie:DoZombieStats()
    end, true, nil)
end

function EffectAllZombiesAreCrawlers:OnEnd()
    ChaosEffectBase:OnEnd()
end
