---@class EffectReplaceZombiesWithProps : ChaosEffectBase
EffectReplaceZombiesWithProps = ChaosEffectBase:derive("EffectReplaceZombiesWithProps", "replace_zombies_with_props")


function EffectReplaceZombiesWithProps:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceZombiesWithProps] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end
    local x1 = square:getX()
    local y1 = square:getY()

    ChaosZombie.ForEachZombieInRange(x1, y1, 50, function(zombie)
        if zombie and zombie:isAlive() then
            local zSquare = zombie:getSquare()
            local x2 = math.floor(zombie:getX())
            local y2 = math.floor(zombie:getY())
            local z2 = math.floor(zombie:getZ())

            zombie:removeFromWorld()
            zombie:removeFromSquare()

            local propName = ChaosProps.GetRandomPropName()
            if propName then
                local prop = ChaosProps.SpawnProp(zSquare, propName)
            end
        end
    end, true, nil)
end

function EffectReplaceZombiesWithProps:OnEnd()
    ChaosEffectBase:OnEnd()
end
