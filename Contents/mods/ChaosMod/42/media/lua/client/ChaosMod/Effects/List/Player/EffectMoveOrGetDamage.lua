---@class EffectMoveOrGetDamage : ChaosEffectBase
---@field checkIntervalMs integer
---@field cooldownMs integer
---@field lastX number
---@field lastY number
---@field lastZ number
EffectMoveOrGetDamage = ChaosEffectBase:derive("EffectMoveOrGetDamage", "move_or_get_damage")

local CHECK_INTERVAL_MS = 1000
local MOVE_THRESHOLD = 1.0
local DAMAGE_COOLDOWN_MS = 5000

function EffectMoveOrGetDamage:OnStart()
    ChaosEffectBase:OnStart()
    self.checkIntervalMs = 0
    self.cooldownMs = 0

    ChaosPlayer.SayLineByColor(getPlayer(), "Move or get damage", ChaosPlayerChatColors.red)

    local player = getPlayer()
    if player then
        self.lastX = player:getX()
        self.lastY = player:getY()
        self.lastZ = player:getZ()
    end
end

---@param deltaMs integer
function EffectMoveOrGetDamage:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    self.cooldownMs = self.cooldownMs - deltaMs
    self.checkIntervalMs = self.checkIntervalMs + deltaMs

    if self.checkIntervalMs < CHECK_INTERVAL_MS then return end
    self.checkIntervalMs = self.checkIntervalMs - CHECK_INTERVAL_MS

    local x, y, z = player:getX(), player:getY(), player:getZ()

    local dist = ChaosUtils.distTo(x, y, self.lastX, self.lastY)
    local movedEnough = dist >= MOVE_THRESHOLD or z ~= self.lastZ

    self.lastX = x
    self.lastY = y
    self.lastZ = z

    if movedEnough then return end
    if self.cooldownMs > 0 then return end

    self.cooldownMs = DAMAGE_COOLDOWN_MS

    local square = player:getSquare()
    if not square then return end

    ChaosUtils.TriggerExplosionAt(square, 3)
    player:setKnockedDown(true)

    ChaosPlayer.SayLineByColor(player, "BOOM!", ChaosPlayerChatColors.red)
end

function EffectMoveOrGetDamage:OnEnd()
    ChaosEffectBase:OnEnd()
end
