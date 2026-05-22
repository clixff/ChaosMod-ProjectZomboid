function ChaosNPC:UnstuckNPC()
    if not self.zombie then return end
    if self.unstuckPassed or self.isAttacking or not self.moving then return end

    local zombie = self.zombie
    if zombie:getActionStateName() ~= "idle" then return end

    local player = getPlayer()
    if player then
        local playerSquare = player:getSquare()
        if playerSquare then
            self:StopMoving(true, "unstuck")
            zombie:setTurnAlertedValues(playerSquare:getX(), playerSquare:getY())
        end
    end

    self.unstuckPassed = true
end

---@return boolean
function ChaosNPC:IsPanicking()
    return self:HasTag(CHAOS_NPC_PANIC_TAG)
end

---@return integer
function ChaosNPC:CountThreateningZombiesNearby()
    if not self.zombie then return 0 end
    local npcZombie = self.zombie
    local nx = npcZombie:getX()
    local ny = npcZombie:getY()
    local nz = npcZombie:getZ()
    local triggerDist = CHAOS_NPC_PANIC_TRIGGER_DIST

    local count = 0
    local cell = getCell()
    if not cell then return 0 end
    local allZombies = cell:getZombieList()
    if not allZombies then return 0 end

    for i = allZombies:size() - 1, 0, -1 do
        local z = allZombies:get(i)
        if z and z:isAlive() and z ~= npcZombie and not ChaosNPCUtils.IsNPC(z) then
            if math.abs(z:getZ() - nz) < 0.5 then
                if ChaosUtils.distTo(nx, ny, z:getX(), z:getY()) < triggerDist then
                    count = count + 1
                end
            end
        end
    end

    return count
end

---@return IsoGridSquare?
function ChaosNPC:FindPanicFleeSquare()
    if not self.zombie then return nil end
    local zombie = self.zombie
    local square = zombie:getSquare()
    if not square then return nil end

    local cell = square:getCell()
    if not cell then return nil end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    local minRadius = CHAOS_NPC_PANIC_FLEE_MIN_RADIUS
    local maxRadius = CHAOS_NPC_PANIC_FLEE_MAX_RADIUS
    local minSq = minRadius * minRadius
    local maxSq = maxRadius * maxRadius

    for _ = 1, CHAOS_NPC_PANIC_FLEE_MAX_TRIES do
        local dx = ChaosUtils.RandIntegerRange(-maxRadius, maxRadius + 1)
        local dy = ChaosUtils.RandIntegerRange(-maxRadius, maxRadius + 1)
        local distSq = dx * dx + dy * dy
        if distSq >= minSq and distSq <= maxSq then
            local sq = cell:getGridSquare(x + dx, y + dy, z)
            if sq and sq:isSolidFloor() and sq:isFree(false) then
                return sq
            end
        end
    end

    return nil
end

---@param reason string
function ChaosNPC:EnterPanic(reason)
    if not self.zombie then return end
    if self:IsPanicking() then return end

    local fleeSquare = self:FindPanicFleeSquare()
    if not fleeSquare then return end

    self:DebugLog("enter_panic " .. tostring(reason), false)

    self:ClearAction()
    self:CancelAttackState("enter_panic")

    self.enemy = nil
    self.moveTargetCharacter = nil
    self.panicTargetSquare = fleeSquare
    self.panicStartTimeMs = ChaosMod.lastTimeTickMs
    self:AddTag(CHAOS_NPC_PANIC_TAG)

    self.walkType = self.canRun and "Run" or "Walk"
    self:MoveToLocation(fleeSquare)
end

---@param reason string
function ChaosNPC:ExitPanic(reason)
    if not self:IsPanicking() then return end

    self:DebugLog("exit_panic " .. tostring(reason), false)
    self:RemoveTag(CHAOS_NPC_PANIC_TAG)
    self.panicTargetSquare = nil
    self.panicCooldownEndMs = ChaosMod.lastTimeTickMs + CHAOS_NPC_PANIC_COOLDOWN_MS
    self:StopMoving(true, "panic_end_" .. tostring(reason))
end

---@param deltaMs integer
function ChaosNPC:UpdatePanic(deltaMs)
    if not self.zombie then return end
    local zombie = self.zombie

    if self:IsPanicking() then
        local now = ChaosMod.lastTimeTickMs
        local elapsed = now - self.panicStartTimeMs
        if elapsed >= CHAOS_NPC_PANIC_DURATION_MS then
            self:ExitPanic("timeout")
            return
        end

        local target = self.panicTargetSquare
        local zombieSquare = zombie:getSquare()
        local reached = target and zombieSquare and
            zombieSquare:getX() == target:getX() and
            zombieSquare:getY() == target:getY() and
            zombieSquare:getZ() == target:getZ()

        if not target or reached then
            local newTarget = self:FindPanicFleeSquare()
            if newTarget then
                self:DebugLog("panic_reroll_target", false)
                self.panicTargetSquare = newTarget
                self.walkType = self.canRun and "Run" or "Walk"
                self:MoveToLocation(newTarget)
            end
        end
        return
    end

    if zombie:getVehicle() then return end

    local now = ChaosMod.lastTimeTickMs
    if now < (self.panicCooldownEndMs or 0) then return end

    self.panicCheckTimeoutMs = (self.panicCheckTimeoutMs or 0) + deltaMs
    if self.panicCheckTimeoutMs < CHAOS_NPC_PANIC_CHECK_INTERVAL_MS then return end
    self.panicCheckTimeoutMs = 0

    local threshold = self:HasEquippedWeapon() and
        CHAOS_NPC_PANIC_THRESHOLD_ARMED or CHAOS_NPC_PANIC_THRESHOLD_UNARMED
    local count = self:CountThreateningZombiesNearby()
    if count >= threshold then
        self:EnterPanic("threat_count=" .. tostring(count) .. "/" .. tostring(threshold))
    end
end

function ChaosNPC:UpdateStalker(deltaMs)
    if not self:HasTag("stalker") then return end
    if not self.zombie then return end

    local zombie = self.zombie
    local player = getPlayer()
    if not player then return end

    if zombie:getActionStateName() ~= "onground" then
        pcall(function()
            zombie:faceThisObject(player)
        end)
    end

    self.stalkerTeleportCooldownMs = (self.stalkerTeleportCooldownMs or 0) + deltaMs
    if self.stalkerTeleportCooldownMs < CHAOS_NPC_STALKER_TELEPORT_COOLDOWN_MS then
        return
    end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    local tooClose = dist < CHAOS_NPC_STALKER_MIN_DIST
    if tooClose or dist > CHAOS_NPC_STALKER_MAX_DIST then
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(
            player,
            0,
            CHAOS_NPC_STALKER_TELEPORT_MIN_RADIUS,
            CHAOS_NPC_STALKER_TELEPORT_MAX_RADIUS,
            20,
            true,
            false,
            false
        )
        if square then
            zombie:teleportTo(square:getX(), square:getY(), square:getZ())
            self:StopMoving(true, "stalker_teleport")
            self.stalkerTeleportCooldownMs = 0

            if tooClose then
                self.stalkerInteractionCount = (self.stalkerInteractionCount or 0) + 1
                if self.stalkerInteractionCount >= 2 then
                    self:RemoveTag("stalker")
                    self.npcGroup = ChaosNPCGroupID.RAIDERS
                end
            end
        end
    end
end
