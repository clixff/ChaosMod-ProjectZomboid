---@param deltaMs integer
function ChaosNPC:update(deltaMs)
    if not self.zombie then
        return
    end

    self.hasBlockingCollisionToTargetThisFrame = false

    local zombie = self.zombie
    if zombie:isDead() then
        self:OnZombieDead()
        return
    end

    self:UpdateEndurance(deltaMs)

    local timestampMs = ChaosMod.lastTimeTickMs

    self:DisableZombieVoice()

    if self.isAttacking then
        self:OnAttackTick(deltaMs)
    end

    if self.findEnemyTimeoutMs < CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS then
        self.findEnemyTimeoutMs = self.findEnemyTimeoutMs + deltaMs
    end

    if self.findGroundWeaponTimeoutMs < CHAOS_NPC_FIND_GROUND_WEAPON_TIMEOUT_MS then
        self.findGroundWeaponTimeoutMs = self.findGroundWeaponTimeoutMs + deltaMs
    end

    local canFindNewEnemyThisFrame = self.findEnemyTimeoutMs >= CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS and
        not self.isAttacking
    local canFindGroundWeaponThisFrame = self.findGroundWeaponTimeoutMs >= CHAOS_NPC_FIND_GROUND_WEAPON_TIMEOUT_MS and
        not self.isAttacking

    if not self.moving then
        self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
    end

    local shouldUpdatePathfind = false
    if not self.isAttacking then
        self.pathfindUpdateMs = self.pathfindUpdateMs + deltaMs
        if self.pathfindUpdateMs >= CHAOS_NPC_MAX_PATHFIND_UPDATE_MS then
            shouldUpdatePathfind = true
            self.pathfindUpdateMs = 0
        end
    end

    if zombie:isUseless() then
        zombie:setUseless(false)
    end

    zombie:setWalkType(self.walkType)
    zombie:setNoTeeth(true)

    self:UnstuckNPC()

    if timestampMs - self.spawnTimeMs < CHAOS_NPC_TIME_TO_ENABLE_AI_AFTER_SPAWN_MS then
        -- intentionally left disabled for now
    end

    local actionState = zombie:getActionStateName()
    if actionState == "lunge" then
        zombie:setUseless(true)
        zombie:clearAggroList()
    elseif actionState == "turnalerted" then
        zombie:clearAggroList()
        zombie:Wander()
        self:StopMoving(true, "turnalerted")
    else
        zombie:setUseless(true)
    end

    ChaosNPC.SetTargetInner(zombie, nil)

    if self.enemy and self.enemy:isDead() then
        if self.enemy == self.moveTargetCharacter then
            self.moveTargetCharacter = nil
            self:StopMoving(true, "enemy_dead")
        end
        self.enemy = nil
    end

    local shouldFindNewEnemy = self.enemy == nil and not self.isAttacking
    if shouldFindNewEnemy and canFindNewEnemyThisFrame then
        self:UpdateNextEnemyTarget()
    end

    if self.enemy then
        local followTarget = self:GetFollowTarget()
        if followTarget then
            local enemyDist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), self.enemy:getX(), self.enemy:getY())
            if enemyDist > CHAOS_NPC_FOLLOW_PRIORITY_DIST then
                self.enemy = nil
            end
        end
    end

    if self.enemy then
        if self.actionType == "pickup_ground_weapon" then
            self:StopMoving(true, "pickup_ground_weapon_enemy_override")
        end
        self:ClearAction()
        self.moveTargetCharacter = self.enemy
        shouldUpdatePathfind = true
    end

    if self.actionType == "pickup_ground_weapon" then
        local actionWorldObj = self.actionWorldObjectTarget
        if not actionWorldObj or not self:IsGroundMeleeWeaponWorldObject(actionWorldObj) then
            self:StopMoving(true, "pickup_ground_weapon_invalid")
            self:ClearAction()
        else
            local actionSquare = actionWorldObj:getSquare()
            if not actionSquare or actionSquare:getZ() ~= zombie:getZ() then
                self:StopMoving(true, "pickup_ground_weapon_square_invalid")
                self:ClearAction()
            else
                local zombieSquare = zombie:getSquare()
                local isOnActionSquare = zombieSquare and
                    zombieSquare:getX() == actionSquare:getX() and
                    zombieSquare:getY() == actionSquare:getY() and
                    zombieSquare:getZ() == actionSquare:getZ()

                if isOnActionSquare then
                    self:pickGroundItemToPrimary(actionWorldObj)
                    self:StopMoving(true, "pickup_ground_weapon")
                    self:ClearAction()
                    shouldUpdatePathfind = false
                elseif shouldUpdatePathfind then
                    self:MoveToLocation(actionSquare)
                end
            end
        end
    end

    if not self.moveTargetCharacter and not self.isAttacking and self.actionType == nil then
        self:UpdateNextTargetMoveCharacter()
        shouldUpdatePathfind = true
    end

    if not self.moveTargetCharacter and not self.isAttacking and self.actionType == nil and self:HasTag("item_robber") then
        if not self.moving then
            self:UpdateWanderTarget()
        end
    end

    local shouldFindGroundWeapon = self.enemy == nil and self.moveTargetCharacter == nil and self.actionType == nil and
        not self:HasEquippedWeapon()
    if shouldFindGroundWeapon and canFindGroundWeaponThisFrame and zombie:getVehicle() == nil then
        self.findGroundWeaponTimeoutMs = 0

        local px = math.floor(zombie:getX())
        local py = math.floor(zombie:getY())
        local pz = math.floor(zombie:getZ())

        ChaosUtils.SquareRingSearchTile_2D(px, py, function(square)
            local foundWorldObj = nil
            local hasWeapon = ChaosUtils.ForAllWorldObjectsOnSquare(square, function(worldObj)
                if self:CanUseGroundMeleeWeaponWorldObject(worldObj) then
                    foundWorldObj = worldObj
                    return true
                end
                return false
            end)

            if hasWeapon and foundWorldObj then
                self:StartPickupGroundWeaponAction(foundWorldObj)
                return self.actionType == "pickup_ground_weapon" and self.actionWorldObjectTarget == foundWorldObj
            end

            return false
        end, 0, 3, false, false, true, pz, pz)
    end

    local isNearby = false
    local dist = 0.0
    if self.moveTargetCharacter then
        dist = ChaosUtils.distTo(
            zombie:getX(), zombie:getY(),
            self.moveTargetCharacter:getX(), self.moveTargetCharacter:getY()
        )
    end

    if self.moveTargetCharacter then
        local maxDist = 3.0
        if self.enemy ~= nil then
            maxDist = self:GetMaxDistanceAttack() + 0.1
        end

        if dist <= maxDist and zombie:getZ() == self.moveTargetCharacter:getZ() then
            isNearby = true
        end

        if isNearby then
            self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        end

        if isNearby and not self.isAttacking and zombie:getVehicle() == nil then
            self:StopMoving(true, "nearby")
            self.moving = false

            if actionState ~= "onground" then
                pcall(function()
                    zombie:faceThisObject(self.moveTargetCharacter)
                end)
            end

            if self.enemy then
                self:StartAttackEnemy()
            end
        end
    end

    if self.isAttacking then
        shouldUpdatePathfind = false
        if self.moving then
            self:StopMoving(true, "attacking")
        end
    end

    if shouldUpdatePathfind and self.moveTargetCharacter and not isNearby then
        self:MoveToCharacter(self.moveTargetCharacter)
    end

    if self.moving then
        local moveResult = zombie:getPathFindBehavior2():update()
        if moveResult == BehaviorResult.Succeeded or moveResult == BehaviorResult.Failed then
            if isNearby then
                self:StopMoving(true, "nearby_finished")
            elseif self.actionType == "pickup_ground_weapon" then
                self:StopMoving(true, "pickup_ground_weapon_reached")
            elseif not self.moveTargetCharacter and self:HasTag("item_robber") then
                self:StopMoving(true, "wander_reached")
            end
            self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        elseif moveResult == BehaviorResult.Working then
            self.moving = true
        end
    end

    if actionState == "walktoward" or actionState == "idle" or actionState == "pathfinding" or actionState == "run" then
        self:HandleCollisions()
    end

    self:UpdateSneakAnim()
    self:VehiclesTick()
    self:UpdateStalker(deltaMs)
end
