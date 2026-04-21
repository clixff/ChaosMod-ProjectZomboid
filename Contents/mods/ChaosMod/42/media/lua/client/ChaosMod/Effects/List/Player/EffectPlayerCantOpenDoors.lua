---@class EffectPlayerCantOpenDoors : ChaosEffectBase
---@field originalComplete unknown
---@field originalOnOpenCloseDoor unknown
---@field originalIgnoreContextKey boolean
EffectPlayerCantOpenDoors = ChaosEffectBase:derive("EffectPlayerCantOpenDoors", "player_cant_open_doors")

local function playLockedSoundForPlayer(player)
    if not player then return end
    local square = player:getSquare()
    if square then
        square:playSound("DoorIsLocked")
    end
end

function EffectPlayerCantOpenDoors:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if player then
        self.originalIgnoreContextKey = player:isIgnoreContextKey()
        player:setIgnoreContextKey(true)
    end

    self.originalOnOpenCloseDoor = ISWorldObjectContextMenu.onOpenCloseDoor
    ISWorldObjectContextMenu.onOpenCloseDoor = function(worldobjects, door, player)
        playLockedSoundForPlayer(getSpecificPlayer(player))
    end

    self.originalComplete = ISOpenCloseDoor.complete
    function ISOpenCloseDoor:complete()
        playLockedSoundForPlayer(self.character or getPlayer())
        return true
    end
end

function EffectPlayerCantOpenDoors:OnEnd()
    ChaosEffectBase:OnEnd()

    local player = getPlayer()
    if player then
        player:setIgnoreContextKey(self.originalIgnoreContextKey or false)
    end

    if self.originalOnOpenCloseDoor then
        ISWorldObjectContextMenu.onOpenCloseDoor = self.originalOnOpenCloseDoor
    end

    if self.originalComplete then
        ISOpenCloseDoor.complete = self.originalComplete
    end
end
