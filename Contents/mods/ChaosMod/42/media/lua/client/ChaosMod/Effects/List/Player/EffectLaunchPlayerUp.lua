---@class EffectLaunchPlayerUp : ChaosEffectBase
EffectLaunchPlayerUp = ChaosEffectBase:derive("EffectLaunchPlayerUp", "launch_player_up")

local LAUNCH_HEIGHT = 3.0
local UP_MS = 350
local DOWN_MS = 650
local ZOMBIE_PACIFY_MS = 5000
local ZOMBIE_PACIFY_RANGE = 20

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
    -- Climbing prevents shouldBeFalling() from applying normal gravity.
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

---@param deltaMs integer
---@param data { affectedZombies: table<IsoZombie, boolean> }
local function PacifyZombiesTick(deltaMs, data)
    local player = getPlayer()
    if not player then return end

    local px, py = player:getX(), player:getY()
    ChaosZombie.ForEachZombieInRange(px, py, ZOMBIE_PACIFY_RANGE, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        if zombie:getTarget() == player then
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setTarget(nil)
            zombie:setTargetSeenTime(0)
        end
        if not data.affectedZombies[zombie] then
            zombie:clearAggroList()
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setTarget(nil)
            zombie:setTargetSeenTime(0)
            zombie:setUseless(true)
            data.affectedZombies[zombie] = true
        end
    end, true, nil)
end

---@param data { affectedZombies: table<IsoZombie, boolean> }
local function PacifyZombiesEnd(data)
    if not data or not data.affectedZombies then return end
    for zombie, _ in pairs(data.affectedZombies) do
        if zombie then
            zombie:setUseless(false)
        end
    end
    data.affectedZombies = nil
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

function EffectLaunchPlayerUp:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    lockFallPhysics(player)

    print(string.format("[EffectLaunchPlayerUp] UP_MS: %d, DOWN_MS: %d", UP_MS, DOWN_MS))

    ChaosSpecialAction.AddNewAction({ startZ = player:getZ(), peakZ = player:getZ() + LAUNCH_HEIGHT, elapsedMs = 0 },
        UP_MS + DOWN_MS,
        LaunchPlayerSpecialActionTick,
        LaunchPlayerSpecialActionEnd,
        LaunchPlayerSpecialActionEnd)

    ChaosSpecialAction.AddNewAction({ affectedZombies = {} },
        ZOMBIE_PACIFY_MS,
        PacifyZombiesTick,
        PacifyZombiesEnd,
        PacifyZombiesEnd)
end

---@param deltaMs integer
function EffectLaunchPlayerUp:OnTick(deltaMs)

end

function EffectLaunchPlayerUp:OnEnd()
    ChaosEffectBase:OnEnd()
end
