---@class EffectLaunchEveryoneUp : ChaosEffectBase
EffectLaunchEveryoneUp = ChaosEffectBase:derive("EffectLaunchEveryoneUp", "launch_everyone_up")

local LAUNCH_HEIGHT = 3.0
local UP_MS = 350
local DOWN_MS = 650

local function easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

local function easeInQuad(t)
    return t * t
end

---@param player IsoPlayer
---@param count integer
---@param allLayers boolean?
local function AddRandomClothingHoles(player, count, allLayers)
    if not player then return end

    if allLayers == nil then
        allLayers = true
    end

    for i = 1, count do
        ---@diagnostic disable-next-line: param-type-mismatch, redundant-parameter
        player:addHole(nil, allLayers == true)
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)

    if player.syncVisuals then
        player:syncVisuals()
    end
end

---@param player IsoGameCharacter
local function lockFallPhysics(player)
    player:setbClimbing(true)
    player:setbFalling(false)
    player:setFallTime(0)
    player:setLastFallSpeed(0)
    player:setLastZ(player:getZ())
end

---@param player IsoGameCharacter
local function unlockFallPhysics(player)
    player:setbClimbing(false)
    player:setbFalling(false)
    player:setFallTime(0)
    player:setLastFallSpeed(0)
    player:setLastZ(player:getZ())
    player:setCurrentSquareFromPosition()
end

---@param player IsoGameCharacter
local function triggerFallVisualOnly(player)
    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end

---@param deltaMs integer
---@param data { elapsedMs: integer, peakZ: number, startZ: number }
local function LaunchPlayerSpecialActionTick(deltaMs, data)
    local player = getPlayer()
    if not player then return end

    data.elapsedMs = data.elapsedMs + deltaMs

    local z

    if data.elapsedMs <= UP_MS then
        local t = data.elapsedMs / UP_MS
        z = data.startZ + LAUNCH_HEIGHT * easeOutQuad(t)
    else
        local t = (data.elapsedMs - UP_MS) / DOWN_MS
        if t > 1 then t = 1 end
        z = data.peakZ - LAUNCH_HEIGHT * easeInQuad(t)
    end

    player:setZ(z)
    lockFallPhysics(player)

    if data.elapsedMs >= UP_MS + DOWN_MS then
        player:setZ(data.startZ)
        unlockFallPhysics(player)
        triggerFallVisualOnly(player)
    end
end

---@param data table
local function LaunchPlayerSpecialActionEnd(data)
    local player = getPlayer()
    if player then
        player:setZ(data.startZ or player:getZ())
        unlockFallPhysics(player)

        local bodyDamage = player:getBodyDamage()
        if not bodyDamage then return end

        local partType
        if ChaosUtils.RandInteger(2) == 0 then
            partType = BodyPartType.LowerLeg_L
        else
            partType = BodyPartType.LowerLeg_R
        end

        local part = bodyDamage:getBodyPart(partType)
        part:setScratched(true, true)

        if bodyDamage:getHealth() > 70 then
            bodyDamage:ReduceGeneralHealth(ChaosUtils.RandFloat(10, 25))
        end

        AddRandomClothingHoles(player, 10, true)

        bodyDamage:Update()
    end
end

function EffectLaunchEveryoneUp:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    lockFallPhysics(player)

    ChaosSpecialAction.AddNewAction({ startZ = player:getZ(), peakZ = player:getZ() + LAUNCH_HEIGHT, elapsedMs = 0 },
        UP_MS + DOWN_MS,
        LaunchPlayerSpecialActionTick,
        LaunchPlayerSpecialActionEnd,
        LaunchPlayerSpecialActionEnd)

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    local zombies = getCell():getZombieList()
    if not zombies then return end

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local x2 = zombie:getX()
            local y2 = zombie:getY()

            if ChaosUtils.isInRange(x1, y1, x2, y2, 30) then
                ChaosVehicle.ExitVehicle(zombie)
                zombie:setZ(zombie:getZ() + 3)
            end
        end
    end
end
