---@class EffectFreezeZombies : ChaosEffectBase
---@field frozenZombies table<IsoZombie, boolean>
EffectFreezeZombies = ChaosEffectBase:derive("EffectFreezeZombies", "freeze_zombies")

local RADIUS = 30

function EffectFreezeZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.frozenZombies = {}
end

---@param deltaMs integer
function EffectFreezeZombies:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie then return end
        if zombie:isDead() then return end

        if self.frozenZombies[zombie] == nil then
            self.frozenZombies[zombie] = zombie:isUseless()
        end

        zombie:clearAggroList()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setTarget(nil)
        zombie:getPathFindBehavior2():reset()
        zombie:getPathFindBehavior2():cancel()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
        zombie:setUseless(true)
        zombie:changeState(ZombieIdleState.instance())
    end, true, nil)
end

function EffectFreezeZombies:OnEnd()
    ChaosEffectBase:OnEnd()

    for zombie, wasUselessBefore in pairs(self.frozenZombies) do
        if zombie and zombie:isAlive() then
            zombie:setUseless(wasUselessBefore)
        end
    end

    local count = 0
    for _ in pairs(self.frozenZombies) do count = count + 1 end
    self.frozenZombies = {}
    print("[EffectFreezeZombies] Restored " .. tostring(count) .. " zombies")
end
