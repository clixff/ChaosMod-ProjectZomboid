---@class EffectPlayerCanOpenAnyDoor : ChaosEffectBase
---@field originalComplete unknown
---@field originalOnOpenCloseDoor unknown
EffectPlayerCanOpenAnyDoor = ChaosEffectBase:derive("EffectPlayerCanOpenAnyDoor", "player_can_open_any_door")

local function unlockDoor(door)
    if not door then return end
    if door.setIsLocked then
        door:setIsLocked(false)
    end
    if door.setLockedByKey then
        door:setLockedByKey(false)
    end
    if door.setLockedByPadlock then
        door:setLockedByPadlock(false)
    end
    if door.setLockedByCode then
        door:setLockedByCode(0)
    end
end

function EffectPlayerCanOpenAnyDoor:OnStart()
    ChaosEffectBase:OnStart()

    self.originalComplete = ISOpenCloseDoor.complete
    self.originalOnOpenCloseDoor = ISWorldObjectContextMenu.onOpenCloseDoor

    function ISOpenCloseDoor:complete()
        unlockDoor(self.item)
        self.item:ToggleDoor(self.character)
        return true
    end

    local originalOnOpenCloseDoor = self.originalOnOpenCloseDoor
    ISWorldObjectContextMenu.onOpenCloseDoor = function(worldobjects, door, player)
        unlockDoor(door)
        return originalOnOpenCloseDoor(worldobjects, door, player)
    end
end

function EffectPlayerCanOpenAnyDoor:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.originalComplete then
        ISOpenCloseDoor.complete = self.originalComplete
    end

    if self.originalOnOpenCloseDoor then
        ISWorldObjectContextMenu.onOpenCloseDoor = self.originalOnOpenCloseDoor
    end
end
