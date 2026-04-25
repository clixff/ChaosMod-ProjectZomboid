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
    if dist < CHAOS_NPC_STALKER_MIN_DIST or dist > CHAOS_NPC_STALKER_MAX_DIST then
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
        end
    end
end
