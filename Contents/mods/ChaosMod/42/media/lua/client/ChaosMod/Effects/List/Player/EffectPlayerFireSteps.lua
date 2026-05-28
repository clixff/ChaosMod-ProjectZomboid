---@class EffectPlayerFireSteps : ChaosEffectBase
---@field lastSquare IsoGridSquare?
EffectPlayerFireSteps = ChaosEffectBase:derive("EffectPlayerFireSteps", "player_fire_steps")

function EffectPlayerFireSteps:OnStart()
    ChaosEffectBase:OnStart()
    self.lastSquare = nil
    local player = getPlayer()
    if player then
        self.lastSquare = player:getSquare()
    end
end

---@param deltaMs integer
function EffectPlayerFireSteps:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end
    local cell = getCell()
    if not cell then return end

    local currentSquare = player:getSquare()
    if not currentSquare then return end

    if self.lastSquare and self.lastSquare ~= currentSquare then
        IsoFireManager.StartFire(cell, self.lastSquare, true, 100, 3000)
    end
    self.lastSquare = currentSquare
end

function EffectPlayerFireSteps:OnEnd()
    ChaosEffectBase:OnEnd()
end
