---@param character IsoGameCharacter
function ChaosNPC:MoveToCharacter(character)
    if not self.zombie then return end
    if not character then return end

    local zombie = self.zombie
    if zombie:getVehicle() then
        return
    end

    local actionState = zombie:getActionStateName()
    local allowActionState = actionState == "walktoward" or actionState == "idle" or
        actionState == "pathfinding" or actionState == "run"

    if not allowActionState then
        self:StopMoving(true, "not_allowed_action_state")
        return
    end

    local oldCharacter = self.moveTargetCharacter
    local sameCharacter = oldCharacter == character

    self.moveTargetCharacter = character
    self.moveTargetLocation = character:getSquare()

    if not self.moveTargetLocation then
        return
    end

    local x = 0
    local y = 0
    local z = 0

    if self.moveTargetLocation then
        x = self.moveTargetLocation:getX()
        y = self.moveTargetLocation:getY()
        z = self.moveTargetLocation:getZ()
    end

    if not sameCharacter then
        zombie:getPathFindBehavior2():reset()
        zombie:getPathFindBehavior2():cancel()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
    end

    if not self.moveTargetCharacter then
        return
    end

    local characterVehicle = self.moveTargetCharacter:getVehicle()
    if characterVehicle then
        zombie:getPathFindBehavior2():pathToLocation(x, y, z)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:getPathFindBehavior2():pathToCharacter(self.moveTargetCharacter)
    end

    self.pathfindUpdateMs = 0
    self.moving = true

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), x, y)
    if dist >= 6.5 or dist <= 3.0 then
        self.walkType = self.canRun and "Run" or "Walk"
    else
        self.walkType = "Walk"
    end

    self.debugLastTimePathfindMs = ChaosMod.lastTimeTickMs
end

---@param force? boolean
---@param reason? string
function ChaosNPC:StopMoving(force, reason)
    force = force or false

    if not self.moving and not force then
        return
    end

    if not self.zombie then
        return
    end

    local zombie = self.zombie
    zombie:getPathFindBehavior2():reset()
    zombie:getPathFindBehavior2():cancel()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)

    zombie:setVariable("bPathfind", false)
    zombie:setVariable("bMoving", false)
    self.moving = false
end

---@param square IsoGridSquare
function ChaosNPC:MoveToLocation(square)
    if not self.zombie or not square then return end

    local zombie = self.zombie
    if zombie:getVehicle() then return end

    local actionState = zombie:getActionStateName()
    local allowActionState = actionState == "walktoward" or actionState == "idle" or
        actionState == "pathfinding" or actionState == "run"
    if not allowActionState then
        self:StopMoving(true, "not_allowed_action_state")
        return
    end

    self.moveTargetCharacter = nil
    self.moveTargetLocation = square

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    zombie:getPathFindBehavior2():reset()
    zombie:getPathFindBehavior2():cancel()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)

    zombie:getPathFindBehavior2():pathToLocation(x, y, z)
    self.pathfindUpdateMs = 0
    self.moving = true
    self.walkType = self.canRun and "Run" or "Walk"
    self.debugLastTimePathfindMs = ChaosMod.lastTimeTickMs
end

function ChaosNPC:UpdateNextTargetMoveCharacter()
    if not self.zombie then
        return
    end

    local zombie = self.zombie
    if zombie:isDead() then return end

    local followTarget = self:GetFollowTarget()
    if followTarget then
        self.enemy = nil
        self:MoveToCharacter(followTarget)
    end
end

function ChaosNPC:UpdateWanderTarget()
    if not self.zombie then return end

    local x = math.floor(self.zombie:getX())
    local y = math.floor(self.zombie:getY())
    local z = math.floor(self.zombie:getZ())
    for _ = 1, 20 do
        local dx = ZombRand(5, 16) * (ZombRand(2) == 0 and 1 or -1)
        local dy = ZombRand(5, 16) * (ZombRand(2) == 0 and 1 or -1)
        local sq = getSquare(x + dx, y + dy, z)
        if sq then
            self:MoveToLocation(sq)
            return
        end
    end
end

function ChaosNPC:UpdateSneakAnim()
    if not self.zombie then return end

    local followTarget = self:GetFollowTarget()
    local isSneak = false
    if followTarget and self.enemy == nil then
        local player = getPlayer()
        if player and player:isSneaking() then
            isSneak = true
        end
    end

    self.zombie:setVariable("ChaosSneak", isSneak)
end

function ChaosNPC:VehiclesTick()
    if not self.zombie then return end

    local zombieVehicle = self.zombie:getVehicle()
    ---@type BaseVehicle?
    local moveTargetVehicle = nil

    if self.moveTargetCharacter ~= nil and self.enemy == nil then
        moveTargetVehicle = self.moveTargetCharacter:getVehicle()
    end

    if zombieVehicle and moveTargetVehicle ~= zombieVehicle then
        zombieVehicle:exit(self.zombie)
        self.zombie:setGodMod(false, true)
        return
    end

    if zombieVehicle == nil and moveTargetVehicle ~= nil and self.enemy == nil then
        local seat = ChaosVehicle.FindFreeSeat(moveTargetVehicle, true)
        if seat < 1 then
            return
        end

        local x1, y1 = moveTargetVehicle:getSquare():getX(), moveTargetVehicle:getSquare():getY()
        local x2, y2 = self.zombie:getX(), self.zombie:getY()

        if not ChaosUtils.isInRange(x1, y1, x2, y2, 4.0) then
            return
        end

        moveTargetVehicle:enter(seat, self.zombie)
        self.zombie:setGodMod(true, true)
        return
    end

    if zombieVehicle ~= nil and self.enemy ~= nil then
        zombieVehicle:exit(self.zombie)
        self.zombie:setGodMod(false, true)
        return
    end
end
