---@param deltaMs integer
function ChaosNPC:UpdateEndurance(deltaMs)
    local deltaSeconds = deltaMs / 1000.0
    local isRunning = self.moving and self.walkType == "Run"

    if isRunning then
        self.endurance = math.max(0, self.endurance - CHAOS_NPC_ENDURANCE_RUN_DRAIN_PER_SEC * deltaSeconds)
    elseif self.isAttacking then
        local pastHalfway = self.attackAnimWindowMs > 0 and
            self.attackAnimTimeMs >= self.attackAnimWindowMs * 0.5
        if pastHalfway then
            self.endurance = math.min(CHAOS_NPC_ENDURANCE_MAX,
                self.endurance + CHAOS_NPC_ENDURANCE_ATTACK_REGEN_PER_SEC * deltaSeconds)
        end
    elseif not self.moving then
        self.endurance = math.min(CHAOS_NPC_ENDURANCE_MAX,
            self.endurance + CHAOS_NPC_ENDURANCE_IDLE_REGEN_PER_SEC * deltaSeconds)
    elseif self.walkType == "Walk" then
        self.endurance = math.min(CHAOS_NPC_ENDURANCE_MAX,
            self.endurance + CHAOS_NPC_ENDURANCE_WALK_REGEN_PER_SEC * deltaSeconds)
    end

    if isRunning then
        if self.endurance <= 0 then
            self.canRun = false
        end
    else
        self.canRun = self.endurance >= CHAOS_NPC_ENDURANCE_RUN_THRESHOLD
    end

    if not self.canRun and isRunning then
        self.walkType = "Walk"
    end
end

function ChaosNPC:UpdateNextEnemyTarget()
    if not self.zombie then
        return
    end

    self.findEnemyTimeoutMs = 0

    if self.zombie:getVehicle() then
        return
    end

    local newEnemy = ChaosNPCUtils.FindNewTargetForNPC(self)
    if newEnemy then
        self:SetAsTargetEnemy(newEnemy)
        return
    end

    local player = getPlayer()
    if player then
        local playerRel = ChaosNPCRelations.GetRelationForNPC(self, player)
        if playerRel == ChaosNPCRelationType.ATTACK then
            self:SetAsTargetEnemy(player)
        end
    end
end

---@param newEnemy IsoGameCharacter
function ChaosNPC:SetAsTargetEnemy(newEnemy)
    if not newEnemy then return end
    if not self.zombie then return end

    self.enemy = newEnemy
    self:MoveToCharacter(newEnemy)
end

function ChaosNPC:StartAttackEnemy()
    if not self.zombie then return end
    if not self.enemy then return end

    local zombie = self.zombie
    if zombie:getVehicle() then
        return
    end

    if zombie:getActionStateName() ~= "idle" then
        return
    end

    ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
    if not zombie:isFacingObject(self.enemy, 0.8) then
        return
    end

    if self:LineTraceToEnemy() ~= "Clear" then
        self.hasBlockingCollisionToTargetThisFrame = true
        self.isAttacking = false
        return
    end

    if not zombie:CanSee(self.enemy) then
        self.isAttacking = false
        return
    end

    if not self.enemy:isZombie() and ChaosPlayer.IsPlayerKnockedDown(self.enemy) then
        return
    end

    self.attackObjectTarget = nil
    self.attackObjectType = nil

    if not self:CanAttackTimeout() then
        return
    end

    self:StartAttackAnimation()
end

---@param deltaMs integer
function ChaosNPC:OnAttackTick(deltaMs)
    if not self.zombie then return end
    local zombie = self.zombie

    local bumpType = zombie:getVariableString("BumpType")
    if bumpType ~= self.attackAnimName then
        self.isAttacking = false
        self.attackAnimTimeMs = 0
        self.attackAnimWindowMs = 0
        self.attackAnimName = nil
        self.attackHitPassed = false
        self.attackObjectTarget = nil
        self.attackObjectType = nil
        self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        return
    end

    self.attackAnimTimeMs = self.attackAnimTimeMs + deltaMs

    if self.attackAnimTimeMs >= self.attackAnimWindowMs and not self.attackHitPassed then
        self.attackHitPassed = true
        self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS

        if self.attackObjectTarget then
            self:OnAttackObjectHit()
        else
            self:OnTryAttackEnemyHit()
        end
    end
end

function ChaosNPC:OnAttackObjectHit()
    if not self.zombie then return end
    if not self.attackObjectTarget then return end
    if not self.attackObjectType then return end

    if self.attackObjectType == "window" then
        ---@type IsoWindow
        local window = self.attackObjectTarget
        if not window or not window:isWindow() or window:isBarricaded() then return end

        if not window:IsOpen() and not window:isSmashed() then
            window:smashWindow()
        end
    elseif self.attackObjectType == "door" then
        ---@type IsoDoor | IsoThumpable
        local door = self.attackObjectTarget
        if not self.weaponItemCached then return end

        local health = math.max(0, door:getHealth() - 10)
        local square = door:getSquare()
        if not square then return end

        if health == 0 then
            local soundFile = ""
            if door.getBreakSound then
                soundFile = door:getBreakSound()
            end
            if soundFile then
                square:playSound(soundFile)
            end
            door:destroy()
        else
            door:setHealth(health)
            local soundFile = self.weaponItemCached:getDoorHitSound()
            if door.getThumpSound then
                soundFile = door:getThumpSound()
            end
            if soundFile then
                square:playSound(soundFile)
            end
        end
    end
end

function ChaosNPC:OnTryAttackEnemyHit()
    if not self.zombie then return end
    if not self.enemy then return end

    local zombie = self.zombie
    if self.enemy:isDead() then return end
    if not zombie:isFacingObject(self.enemy, 0.5) then return end
    if zombie:getZ() ~= self.enemy:getZ() then return end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), self.enemy:getX(), self.enemy:getY())
    if dist > self:GetMaxDistanceAttack() + 0.2 then
        return
    end

    if not self.enemy:isZombie() and ChaosPlayer.IsPlayerKnockedDown(self.enemy) then
        return
    end

    if not zombie:CanSee(self.enemy) then
        return
    end

    self:OnAttackEnemyHit()
end

function ChaosNPC:OnAttackEnemyHit()
    if not self.zombie then return end
    if not self.enemy then return end

    local zombie = self.zombie
    local enemy = self.enemy
    if zombie:isDead() or enemy:isDead() or not self.weaponItemCached then
        return
    end

    local fakeAttacker = getFakeAttacker()

    enemy:setAttackedBy(zombie)
    local minDamage = self.weaponItemCached:getMinDamage()
    local maxDamage = self.weaponItemCached:getMaxDamage()
    if minDamage <= 0 then minDamage = 2 end
    if maxDamage <= 0 then maxDamage = 4 end

    local damage = ZombRandFloat(minDamage, maxDamage)
    damage = damage * self.DamageMultiplier
    if damage <= 0.1 then
        damage = 0.1
    end

    local enemyVehicle = enemy:getVehicle()
    local canAttackInVehicle = false
    if enemyVehicle then
        canAttackInVehicle = true
        local square = enemy:getSquare()
        local seat = enemyVehicle:getSeat(enemy) + 1
        local windowPartName = CHAOS_NPC_WINDOW_VEHICLE_PART_BY_SEAT[seat]
        enemy:playSound("HitVehicleWindowWithWeapon")
        local vehiclePart = enemyVehicle:getPartById(windowPartName)
        if vehiclePart and vehiclePart:getInventoryItem() then
            local windowPart = vehiclePart:getWindow()
            if windowPart and not windowPart:isOpen() then
                vehiclePart:damage(20)
                if vehiclePart:getCondition() <= 0 then
                    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
                    vehiclePart:setInventoryItem(nil, 10)
                    square:playSound("SmashWindow")
                else
                    square:playSound("BreakGlassItem")
                    canAttackInVehicle = false
                end
                enemyVehicle:updatePartStats()
            end
        end
    end

    if enemyVehicle and not canAttackInVehicle then
        return
    end

    if enemy:isZombie() then
        ---@type table<integer, string>
        local hitReactions = { "HeadLeft", "HeadRight", "HeadTop" }
        fakeAttacker:setVariable("ZombieHitReaction", hitReactions[1 + math.floor(ZombRand(#hitReactions))])
        enemy:Hit(self.weaponItemCached, fakeAttacker, damage, false, 1.0)
        enemy:playSound(self.weaponItemCached:getZombieHitSound())

        if ChaosNPCUtils.IsNPC(enemy) then
            local otherNPC = ChaosNPCUtils.GetNPCFromZombie(enemy)
            if otherNPC then
                otherNPC:OnZombieDamagedNPC(zombie)
            end
        end
    else
        local splatCount = self.weaponItemCached:getSplatNumber()
        for _ = 0, splatCount do
            enemy:splatBlood(2, 0.25)
        end

        enemy:playBloodSplatterSound()

        local bodyDamage = enemy:getBodyDamage()
        enemy:setAttackedBy(zombie)

        if ZombRand(0, 21) == 0 and not enemy:isKnockedDown() then
            enemy:setKnockedDown(true)
        else
            local timeNowMs = ChaosMod.lastTimeTickMs
            local timeSinceLastHitMs = timeNowMs - (ChaosPlayer.hitStunLastTimeMs or 0)
            if timeSinceLastHitMs >= 0 then
                local isBehind = zombie:isBehind(enemy)
                enemy:setHitFromBehind(isBehind)
                enemy:setVariable("hitpvp", true)
                enemy:setHitReaction("")
                enemy:setHitReaction("HitReaction")
                enemy:reportEvent("washitpvp")
                ChaosPlayer.hitStunLastTimeMs = timeNowMs
            end
        end

        bodyDamage:ReduceGeneralHealth(damage)
        if self.CanAddWounds then
            ChaosPlayer.SetRandomBodyDamageByMeleeWeapon(enemy, damage, self.weaponItemCached)
        end
    end
end

---@return number
function ChaosNPC:GetMaxDistanceAttack()
    if not self.zombie or not self.weaponItemCached then
        return 0.0
    end

    return self.weaponItemCached:getMaxRange() - 0.1
end

---@return string
function ChaosNPC:LineTraceToEnemy()
    if not self.zombie then return "" end
    if not self.enemy then return "" end

    local square1 = self.zombie:getSquare()
    local square2 = self.enemy:getSquare()
    return tostring(LosUtil.lineClear(
        square1:getCell(),
        square1:getX(), square1:getY(), square1:getZ(),
        square2:getX(), square2:getY(), square2:getZ(),
        false
    ))
end

---@param object IsoObject
---@param type string
function ChaosNPC:StartAttackingObject(object, type)
    if not object then return end
    if not self.zombie then return end
    if not self:CanAttackTimeout() then return end

    self.attackObjectTarget = object
    self.attackObjectType = type
    self:StartAttackAnimation()
end

---@return integer
function ChaosNPC:GetNextAttackWindowMs()
    return 500 + math.floor(ZombRand(0, 350))
end

---@return number
function ChaosNPC:GetAttackEnduranceCost()
    if not self.weaponItemCached then
        return CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS
    end
    if self.weaponItemCached:getFullType() == "Base.BareHands" then
        return CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS
    end

    local weaponType = WeaponType.getWeaponType(self.weaponItemCached)
    if weaponType == WeaponType.TWO_HANDED or weaponType == WeaponType.HEAVY then
        return CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_TWO_HAND
    elseif weaponType == WeaponType.ONE_HANDED then
        return CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_ONE_HAND
    end
    return CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS
end

function ChaosNPC:StartAttackAnimation()
    if not self.zombie then return end
    if self.endurance < self:GetAttackEnduranceCost() then
        return
    end

    local zombie = self.zombie

    self.isAttacking = true
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = self:GetNextAttackWindowMs()

    if not self.weaponItemCached then
        return
    end

    ---@type table<integer, string>
    local animsTable = {}
    animsTable = CHAOS_NPC_ATTACK_ANIMS.HANDS
    local groundAttackName = CHAOS_NPC_ATTACK_GROUND.HANDS
    local attackEnduranceDrain = CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS

    local weaponType = WeaponType.getWeaponType(self.weaponItemCached)
    if self.weaponItemCached:getFullType() == "Base.BareHands" then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.HANDS
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.HANDS
        attackEnduranceDrain = CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS
    elseif weaponType == WeaponType.ONE_HANDED then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.ONE_HAND
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.ONE_HAND
        attackEnduranceDrain = CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_ONE_HAND
    elseif weaponType == WeaponType.TWO_HANDED or weaponType == WeaponType.HEAVY then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.TWO_HAND
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.TWO_HAND
        attackEnduranceDrain = CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_TWO_HAND
    end

    self.endurance = math.max(0, self.endurance - attackEnduranceDrain)
    self.attackAnimName = animsTable[1 + ZombRand(#animsTable)]

    local isAttackingEnemy = self.enemy ~= nil and self.attackObjectTarget == nil
    self.attackLastTimeMs = ChaosMod.lastTimeTickMs
    if isAttackingEnemy and self.enemy ~= nil and self.enemy:isZombie() then
        self.attackLastTimeMs = 0
    end

    local useGroundAnimation = false
    if isAttackingEnemy and self.enemy ~= nil then
        local enemyStateName = self.enemy:getActionStateName()
        if enemyStateName == "onground" or self.enemy:isKnockedDown() then
            useGroundAnimation = true
        end
    end

    if useGroundAnimation then
        self.attackAnimName = groundAttackName
    end

    if self.attackAnimName then
        zombie:setBumpType(self.attackAnimName)
    end

    if self.weaponItemCached.getSwingSound then
        local weaponSound = self.weaponItemCached:getSwingSound()
        if weaponSound then
            zombie:playSound(weaponSound)
        end
    end

    self.pathfindUpdateMs = math.floor(CHAOS_NPC_MAX_PATHFIND_UPDATE_MS * 0.75)
    self.attackHitPassed = false
end

---@return boolean
function ChaosNPC:CanAttackTimeout()
    if not self.zombie then return false end
    if not self.attackLastTimeMs then return false end

    local timeSinceLastAttackMs = ChaosMod.lastTimeTickMs - self.attackLastTimeMs
    return timeSinceLastAttackMs > CHAOS_NPC_ATTACK_TIMEOUT_MS
end

---@param otherZombie IsoZombie
---@return boolean
function ChaosNPC:IsEnemyToNPC(otherZombie)
    if not otherZombie then return false end
    if not self.zombie then return false end

    local zombie = self.zombie
    if otherZombie == zombie then return false end
    if zombie:isDead() or otherZombie:isDead() then return false end

    local rel = ChaosNPCRelations.GetRelationForNPC(self, otherZombie)
    return rel == ChaosNPCRelationType.ATTACK
end

---@param otherZombie IsoZombie
function ChaosNPC:OnZombieDamagedNPC(otherZombie)
    if not otherZombie then return end
    if not self.zombie then return end

    local zombie = self.zombie
    if zombie:isDead() or otherZombie:isDead() then return end
    if otherZombie == zombie or otherZombie == self.enemy or self.isAttacking then return end

    local rel = ChaosNPCRelations.GetRelationForNPC(self, otherZombie)
    if rel == ChaosNPCRelationType.ATTACK then
        self:SetAsTargetEnemy(otherZombie)
    end
end
