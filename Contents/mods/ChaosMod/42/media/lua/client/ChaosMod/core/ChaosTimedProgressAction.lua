---@class ChaosTimedProgressAction : ISBaseTimedAction
---@field maxTime number
---@field onComplete (fun(character: IsoGameCharacter)) | nil
ChaosTimedProgressAction = ISBaseTimedAction:derive("ChaosTimedProgressAction")

---@return boolean
function ChaosTimedProgressAction:isValid()
    return true
end

function ChaosTimedProgressAction:start()
end

function ChaosTimedProgressAction:update()
end

function ChaosTimedProgressAction:perform()
    if self.onComplete then
        self.onComplete(self.character)
    end
    ISBaseTimedAction.perform(self)
end

---@param character IsoGameCharacter
---@param time number -- duration in ticks
---@param onComplete (fun(character: IsoGameCharacter)) | nil
---@return ChaosTimedProgressAction
function ChaosTimedProgressAction:new(character, time, onComplete)
    ---@type ChaosTimedProgressAction
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = time or 100
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.useProgressBar = true
    o.onComplete = onComplete
    return o
end

---Queue a new timed progress action for the player.
---@param player IsoGameCharacter
---@param time number -- duration in ticks
---@param onComplete (fun(character: IsoGameCharacter)) | nil
function ChaosTimedProgressAction.AddNewTimedAction(player, time, onComplete)
    ISTimedActionQueue.add(ChaosTimedProgressAction:new(player, time, onComplete))
end

return ChaosTimedProgressAction
