---@class EffectZombiesLowRenderDistance : ChaosEffectBase
EffectZombiesLowRenderDistance = ChaosEffectBase:derive("EffectZombiesLowRenderDistance", "zombies_low_render_distance")

local RADIUS = 3

---@param zombie IsoZombie
local function OnZombieUpdateHandler(zombie)
    if not zombie then return end
    if zombie:isSceneCulled() then return end

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    local x1 = square:getX()
    local y1 = square:getY()
    local x2 = zombie:getX()
    local y2 = zombie:getY()

    if ChaosUtils.isInRange(x1, y1, x2, y2, RADIUS) == false then
        zombie:setTargetAlpha(0)
    end
end

function EffectZombiesLowRenderDistance:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnZombieUpdate.Add(OnZombieUpdateHandler)
end

---@param deltaMs integer
function EffectZombiesLowRenderDistance:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    local allZombies = getCell():getZombieList()
    if not allZombies then return end

    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie then
            local x2 = zombie:getX()
            local y2 = zombie:getY()
            if ChaosUtils.isInRange(x1, y1, x2, y2, RADIUS) == false then
                -- Hide nickname
                zombie:addLineChatElement("")
            end
        end
    end
end

function EffectZombiesLowRenderDistance:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnZombieUpdate.Remove(OnZombieUpdateHandler)
end
