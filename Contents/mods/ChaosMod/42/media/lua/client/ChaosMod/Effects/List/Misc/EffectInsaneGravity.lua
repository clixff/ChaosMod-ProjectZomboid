---@class EffectInsaneGravityZombieData
---@field wasUseless boolean
---@field initialX number
---@field initialY number
---@field initialZ number

---@class EffectInsaneGravity : ChaosEffectBase
---@field initialPlayerX number
---@field initialPlayerY number
---@field initialPlayerZ number
---@field affectedZombies table<IsoZombie, EffectInsaneGravityZombieData>
EffectInsaneGravity = ChaosEffectBase:derive("EffectInsaneGravity", "insane_gravity")

local RADIUS = 75
local VEHICLE_DOWN_IMPULSE = 100000 * 5 * 2

function EffectInsaneGravity:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    self.initialPlayerX = player:getX()
    self.initialPlayerY = player:getY()
    self.initialPlayerZ = player:getZ()
    self.affectedZombies = {}
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
    player:setKnockedDown(true)

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
            }
            affectedZombies[zombie] = data
            zombie:setUseless(true)
        end

        zombie:setX(data.initialX)
        zombie:setY(data.initialY)
        zombie:setZ(data.initialZ)
        zombie:setKnockedDown(true)
    end, true, nil)
end

function EffectInsaneGravity:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.affectedZombies then
        for zombie, data in pairs(self.affectedZombies) do
            if zombie and zombie:isAlive() then
                zombie:setUseless(data.wasUseless)
            end
        end
        self.affectedZombies = {}
    end
end
