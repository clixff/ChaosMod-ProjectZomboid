---@class EffectInsaneGravityZombieData
---@field wasUseless boolean
---@field initialX number
---@field initialY number
---@field initialZ number
---@field fallTriggered boolean

---@class EffectInsaneGravity : ChaosEffectBase
---@field initialPlayerX number
---@field initialPlayerY number
---@field initialPlayerZ number
---@field affectedZombies table<IsoZombie, EffectInsaneGravityZombieData>
---@field playerFallTriggered boolean
EffectInsaneGravity = ChaosEffectBase:derive("EffectInsaneGravity", "insane_gravity")

local RADIUS = 75
local VEHICLE_DOWN_IMPULSE = 100000 * 5 * 2
local PLAYER_REANIMATE_TIMER = 1
local ZOMBIE_REANIMATE_TIMER = 10

local function IsPlayerDownState(player)
    return player:isCurrentState(PlayerFallDownState.instance())
        or player:isCurrentState(PlayerOnGroundState.instance())
        or player:isCurrentState(PlayerKnockedDown.instance())
end

local function TriggerPlayerFall(player)
    if not player then return end

    player:setFallOnFront(true)
    player:setKnockedDown(true)
    player:setOnFloor(false)
    player:setReanimateTimer(PLAYER_REANIMATE_TIMER)
    player:setIgnoreMovement(true)
    player:setBlockMovement(true)
    player:changeState(PlayerFallDownState.instance())
end

local function MaintainPlayerDown(player)
    if not player then return end

    player:setReanimateTimer(PLAYER_REANIMATE_TIMER)
    player:setIgnoreMovement(true)
    player:setBlockMovement(true)
end

local function TriggerZombieFall(zombie)
    if not zombie or zombie:isDead() then return end

    zombie:setFallOnFront(true)
    zombie:setKnockedDown(true)
    zombie:setOnFloor(false)
    zombie:setReanimateTimer(ZOMBIE_REANIMATE_TIMER)
    zombie:changeState(ZombieFallDownState.instance())
end

local function MaintainZombieDown(zombie)
    if not zombie or zombie:isDead() then return end

    zombie:setReanimateTimer(ZOMBIE_REANIMATE_TIMER)
end

function EffectInsaneGravity:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    self.initialPlayerX = player:getX()
    self.initialPlayerY = player:getY()
    self.initialPlayerZ = player:getZ()
    self.affectedZombies = {}
    self.playerFallTriggered = false
end

---@param deltaMs integer
function EffectInsaneGravity:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local multiplier = deltaMs / 1000

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            local downStrength = -VEHICLE_DOWN_IMPULSE * multiplier
            local impulse = Vector3f.new(0, downStrength, 0)
            local relPos = Vector3f.new(0, 0, 0)
            vehicle:addImpulse(impulse, relPos)
        end
    end

    player:setX(self.initialPlayerX)
    player:setY(self.initialPlayerY)
    player:setZ(self.initialPlayerZ)

    if not self.playerFallTriggered then
        TriggerPlayerFall(player)
        self.playerFallTriggered = true
    elseif not IsPlayerDownState(player) then
        player:setFallOnFront(true)
        player:setOnFloor(true)
        player:changeState(PlayerOnGroundState.instance())
    end

    MaintainPlayerDown(player)

    local affectedZombies = self.affectedZombies
    ChaosZombie.ForEachZombieInRange(self.initialPlayerX, self.initialPlayerY, RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end

        local data = affectedZombies[zombie]
        if data == nil then
            data = {
                wasUseless = zombie:isUseless(),
                initialX = zombie:getX(),
                initialY = zombie:getY(),
                initialZ = zombie:getZ(),
                fallTriggered = false,
            }
            affectedZombies[zombie] = data

            local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
            if npc then
                npc:AddDisableAiEffect("insane_gravity")
            end
        end

        zombie:setX(data.initialX)
        zombie:setY(data.initialY)
        zombie:setZ(data.initialZ)

        if not data.fallTriggered then
            TriggerZombieFall(zombie)
            data.fallTriggered = true
            zombie:setUseless(true)
        elseif not zombie:isCurrentState(ZombieFallDownState.instance()) and not zombie:isCurrentState(ZombieOnGroundState.instance()) then
            zombie:setFallOnFront(true)
            zombie:setOnFloor(true)
            zombie:changeState(ZombieOnGroundState.instance())
        end

        MaintainZombieDown(zombie)
    end, false, nil)
end

function EffectInsaneGravity:OnEnd()
    ChaosEffectBase:OnEnd()

    local player = getPlayer()
    if player then
        player:setIgnoreMovement(false)
        player:setBlockMovement(false)
        player:setBumpType("")
        player:setBumpDone(true)

        if player:isCurrentState(PlayerOnGroundState.instance()) then
            player:changeState(PlayerGetUpState.instance())
        end
    end

    if self.affectedZombies then
        for zombie, data in pairs(self.affectedZombies) do
            if zombie and zombie:isAlive() then
                zombie:setUseless(data.wasUseless)
                zombie:setReanimateTimer(0)
                local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
                if npc then
                    npc:RemoveDisableAiEffect("insane_gravity")
                end
            end
        end
        self.affectedZombies = {}
    end
end
