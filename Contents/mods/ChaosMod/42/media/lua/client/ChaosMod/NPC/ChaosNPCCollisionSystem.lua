function ChaosNPC:HandleCollisions()
    if not self.zombie then return end
    if self.isAttacking then return end

    local zombie = self.zombie
    local hasCollisionThisFrame = zombie:isCollidedThisFrame()
    local finalCollisionResult = hasCollisionThisFrame or self.hasBlockingCollisionToTargetThisFrame
    if not finalCollisionResult then
        return
    end

    local x1 = zombie:getX()
    local y1 = zombie:getY()
    local z1 = zombie:getZ()
    local forwardX = zombie:getForwardDirectionX()
    local forwardY = zombie:getForwardDirectionY()

    local squaresToCheck = {
        { x = math.floor(x1), y = math.floor(y1), z = z1 },
        { x = math.floor(x1 + forwardX), y = math.floor(y1 + forwardY), z = z1 },
    }

    local cell = getCell()
    for _, coord in ipairs(squaresToCheck) do
        local square = cell:getGridSquare(coord.x, coord.y, coord.z)
        if square then
            local objectsList = square:getObjects()
            for i = 0, objectsList:size() - 1 do
                local object = objectsList:get(i)
                if object and self:HandleCollisionWithObject(zombie, object) then
                    return
                end
            end
        end
    end
end

---@param zombie IsoZombie
---@param object IsoObject
---@return boolean
function ChaosNPC:HandleCollisionWithObject(zombie, object)
    if not zombie then return false end
    if not object then return false end
    if not object:getProperties() then return false end

    local isHostileToPlayer = ChaosNPCRelations.CanNPCDestroyObjects(self)

    if instanceof(object, "IsoWindow") then
        ---@type IsoWindow
        local window = object

        if not zombie:isFacingObject(window, 0.8) then
            zombie:faceThisObject(window)
            return true
        end

        if window:isBarricaded() then
            return false
        end

        if not window:IsOpen() and not window:isSmashed() then
            if isHostileToPlayer then
                self:StartAttackingObject(window, "window")
                return true
            end
        elseif window:canClimbThrough(zombie) then
            self:StopMoving(true, "clim_window")
            zombie:climbThroughWindow(window)
            return true
        end
    elseif instanceof(object, "IsoDoor") or instanceof(object, "IsoThumpable") then
        ---@type IsoDoor | IsoThumpable
        local door = object

        if door.isDoor and not door:isDoor() then
            return false
        end
        if door:IsOpen() or door:isBarricaded() then
            return false
        end

        local zombieSquare = zombie:getSquare()
        local isLocked = door:isLocked() or door:isLockedByKey()
        local canOpenDoor = true

        if zombieSquare:isOutside() then
            if isHostileToPlayer or isLocked then
                canOpenDoor = false
            end
        end

        if canOpenDoor then
            door:ToggleDoor(zombie)
            return true
        elseif isHostileToPlayer then
            local isGarageDoor = IsoDoor.getGarageDoorIndex(door) ~= -1
            if isGarageDoor then
                return false
            end

            self:StartAttackingObject(door, "door")
            return true
        end
    elseif object:isHoppable() then
        if not zombie:isFacingObject(object, 0.8) then
            zombie:faceThisObject(object)
            return true
        end

        local forwardDir = zombie:getForwardIsoDirection()
        if forwardDir ~= nil then
            self:StopMoving(true, "clim_fence")
            zombie:climbOverFence(forwardDir)
            return true
        end
    end

    return false
end
