---@class EffectPlayerCantOpenDoors : ChaosEffectBase
---@field _patchedOpenCloseDoor boolean
---@field originalComplete unknown
EffectPlayerCantOpenDoors = ChaosEffectBase:derive("EffectPlayerCantOpenDoors", "player_cant_open_doors")

function EffectPlayerCantOpenDoors:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.originalComplete = ISOpenCloseDoor.complete

    function ISOpenCloseDoor:complete()
        local player = getPlayer()
        if player then
            local square = player:getSquare()
            if square then
                square:playSound("DoorIsLocked")
            end
        end
        return
    end
end

function EffectPlayerCantOpenDoors:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.originalComplete then
        ISOpenCloseDoor.complete = self.originalComplete
    end
end
