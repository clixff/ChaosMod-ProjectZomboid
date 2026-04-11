---@class EffectShakeCamera : ChaosEffectBase
---@field basePlayerOffsetX integer
---@field basePlayerOffsetY integer
EffectShakeCamera = ChaosEffectBase:derive("EffectShakeCamera", "shake_camera")

local SHAKE_AMPLITUDE = 100

---@param player IsoPlayer
local function onPlayerUpdate(player)
    local oldX = IsoCamera.getOffX()
    local oldY = IsoCamera.getOffY()
    local newX = oldX + math.floor(ZombRand(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE))
    local newY = oldY + math.floor(ZombRand(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE))
    -- IsoCamera.setOffX(newX)
    -- IsoCamera.setOffY(newY)
    -- IsoCamera.setLastOffX(newX)
    -- IsoCamera.setLastOffY(newY)

    -- print("Old offset X: " .. tostring(oldX))
    -- print("Old offset Y: " .. tostring(oldY))

    -- print("New offset X: " .. tostring(newX))
    -- print("New offset Y: " .. tostring(newY))

    IsoCamera.playerOffsetX = math.floor(ZombRand(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE + 1))
    IsoCamera.playerOffsetY = math.floor(ZombRand(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE + 1))
end

function EffectShakeCamera:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
end

function EffectShakeCamera:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectShakeCamera:OnEnd()
    ChaosEffectBase:OnEnd()

    IsoCamera.playerOffsetX = 0
    IsoCamera.playerOffsetY = -56

    Events.OnPlayerUpdate.Remove(onPlayerUpdate)
end
