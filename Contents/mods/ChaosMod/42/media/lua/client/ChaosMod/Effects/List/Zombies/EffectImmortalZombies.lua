---@class EffectImmortalZombies : ChaosEffectBase
---@field immortalZombies table<IsoZombie, boolean>
EffectImmortalZombies = ChaosEffectBase:derive("EffectImmortalZombies", "immortal_zombies")

local RADIUS = 30

function EffectImmortalZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.immortalZombies = {}
end

---@param deltaMs integer
function EffectImmortalZombies:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie then return end
        if not zombie:isAlive() then return end

        if self.immortalZombies[zombie] == nil then
            self.immortalZombies[zombie] = true
        end

        zombie:setInvulnerable(true)
    end, true, nil)
end

function EffectImmortalZombies:OnEnd()
    ChaosEffectBase:OnEnd()

    for zombie in pairs(self.immortalZombies) do
        if zombie then
            zombie:setInvulnerable(false)
        end
    end

    self.immortalZombies = {}
end
