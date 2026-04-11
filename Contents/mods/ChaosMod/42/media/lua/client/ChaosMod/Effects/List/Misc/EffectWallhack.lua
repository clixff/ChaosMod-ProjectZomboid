EffectWallhack = ChaosEffectBase:derive("EffectWallhack", "wallhack")

---@param zombie IsoZombie
local function WallhackOnZombieUpdate(zombie)
    if not zombie then return end

    if not ChaosMod.wallhack then
        return
    end


    zombie:setTargetAlpha(1.0)
end

function EffectWallhack:OnStart()
    ChaosEffectBase:OnStart()
    ChaosMod.wallhack = true
    Events.OnZombieUpdate.Add(WallhackOnZombieUpdate)
end

function EffectWallhack:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if ChaosConfig.IsZombieNicknamesEnabled() then
        return
    end

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end
    local x1 = square:getX()
    local y1 = square:getY()
    local z1 = square:getZ()
    local maxDist = 15

    local allZombies = getCell():getZombieList()
    if not allZombies then return end
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        local x2 = zombie:getX()
        local y2 = zombie:getY()
        local z2 = zombie:getZ()
        if ChaosUtils.isInRange(x1, y1, x2, y2, maxDist) then
            zombie:addLineChatElement("Zombie", 1.0, 0.0, 0.0)
        else
            zombie:addLineChatElement("")
        end
    end
end

function EffectWallhack:OnEnd()
    ChaosEffectBase:OnEnd()
    ChaosMod.wallhack = false
    Events.OnZombieUpdate.Remove(WallhackOnZombieUpdate)
end
