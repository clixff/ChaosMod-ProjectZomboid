---@class EffectSpinningCharactersZombieData
---@field wasUseless boolean
---@field initialX number
---@field initialY number
---@field initialZ number

---@class EffectSpinningCharacters : ChaosEffectBase
---@field playerHeading number
---@field zombieHeading number
---@field affectedZombies table<IsoZombie, EffectSpinningCharactersZombieData>
EffectSpinningCharacters = ChaosEffectBase:derive("EffectSpinningCharacters", "spinning_characters")

local RADIUS = 45
local PLAYER_YAW_SPEED_DEG = 360.0 * 2.0
local ZOMBIE_YAW_SPEED_DEG = 360.0 * 2.0

function EffectSpinningCharacters:OnStart()
    ChaosEffectBase:OnStart()

    self.playerHeading = 0.0
    self.zombieHeading = 0.0
    self.affectedZombies = {}

    local player = getPlayer()
    if player then
        ChaosVehicle.ExitVehicle(player)
    end

    ChaosNPCUtils.AddNPCIgnorePlayerEffect("spinning_characters")
end

---@param deltaMs integer
function EffectSpinningCharacters:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local deltaSec = deltaMs / 1000.0

    self.playerHeading = (self.playerHeading + PLAYER_YAW_SPEED_DEG * deltaSec) % 360.0
    local pRad = math.rad(self.playerHeading)
    player:setTargetAndCurrentDirection(math.cos(pRad), math.sin(pRad))

    self.zombieHeading = (self.zombieHeading + ZOMBIE_YAW_SPEED_DEG * deltaSec) % 360.0
    local zRad = math.rad(self.zombieHeading)
    local zfx = math.cos(zRad)
    local zfy = math.sin(zRad)

    local px = player:getX()
    local py = player:getY()

    local affectedZombies = self.affectedZombies

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
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
            if not ChaosNPCUtils.IsNPC(zombie) then
                zombie:setUseless(true)
            else
                local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
                if npc then
                    npc:AddDisableAiEffect("spinning_characters")
                end
            end
        end

        zombie:setX(data.initialX)
        zombie:setY(data.initialY)
        zombie:setZ(data.initialZ)
        zombie:setTargetAndCurrentDirection(zfx, zfy)
    end, false, nil)
end

function EffectSpinningCharacters:OnEnd()
    ChaosEffectBase:OnEnd()

    ChaosNPCUtils.RemoveNPCIgnorePlayerEffect("spinning_characters")

    if self.affectedZombies then
        for zombie, data in pairs(self.affectedZombies) do
            if zombie and zombie:isAlive() then
                if not ChaosNPCUtils.IsNPC(zombie) then
                    zombie:setUseless(data.wasUseless)
                else
                    local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
                    if npc then
                        npc:RemoveDisableAiEffect("spinning_characters")
                    end
                end
            end
        end
        self.affectedZombies = {}
    end
end
