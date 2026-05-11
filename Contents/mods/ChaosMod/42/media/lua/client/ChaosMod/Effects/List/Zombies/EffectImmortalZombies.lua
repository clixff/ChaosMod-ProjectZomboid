---@class EffectImmortalZombies : ChaosEffectBase
---@field immortalZombies table<IsoZombie, { health: number, bodyHealth: number | nil }>
EffectImmortalZombies = ChaosEffectBase:derive("EffectImmortalZombies", "immortal_zombies")

local RADIUS = 30

function EffectImmortalZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.immortalZombies = {}
end

function EffectImmortalZombies:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or not zombie:isAlive() then return end

        local entry = self.immortalZombies[zombie]
        if not entry then
            entry = {
                health = zombie:getHealth(),
                bodyHealth = zombie:getBodyDamage() and zombie:getBodyDamage():getOverallBodyHealth() or nil,
            }
            self.immortalZombies[zombie] = entry
        end

        -- blocks the next normal hit
        zombie:setNoDamage(true)

        -- backup: restore health if something still got through
        if zombie:getHealth() < entry.health then
            zombie:setHealth(entry.health)
        end

        local bd = zombie:getBodyDamage()
        if bd and entry.bodyHealth and bd:getOverallBodyHealth() < entry.bodyHealth then
            bd:setOverallBodyHealth(entry.bodyHealth)
        end
    end, true, nil)
end

function EffectImmortalZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    self.immortalZombies = {}
end
