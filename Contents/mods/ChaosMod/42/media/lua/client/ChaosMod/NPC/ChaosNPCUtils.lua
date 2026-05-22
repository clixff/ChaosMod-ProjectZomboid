---@class ChaosNPCUtils
---@field npcList ArrayList<ChaosNPC>
---@field cleanupAccumMs integer
ChaosNPCUtils = ChaosNPCUtils or {
    npcList = ArrayList:new(),
    cleanupAccumMs = 0,
}

local CLEANUP_INTERVAL_MS = 5000
local ZOMBIE_NPC_BITE_DAMAGE_DELAY_MS = 600
local ZOMBIE_NPC_BITE_CANCEL_WINDOW_FRACTION = 0.5
local ZOMBIE_NPC_BITE_CANCEL_WINDOW_MS = ZOMBIE_NPC_BITE_DAMAGE_DELAY_MS * ZOMBIE_NPC_BITE_CANCEL_WINDOW_FRACTION
local ZOMBIE_NPC_HITREACTION_RECOVERY_MS = 1500

local DEBUG_ZOMBIES_NPC_UTILS_LOGS = false

---@param deltaMs integer
function ChaosNPCUtils.OnTick(deltaMs)
    ChaosNPCUtils.cleanupAccumMs = ChaosNPCUtils.cleanupAccumMs + deltaMs
    if ChaosNPCUtils.cleanupAccumMs < CLEANUP_INTERVAL_MS then return end
    ChaosNPCUtils.cleanupAccumMs = 0

    local list = ChaosNPCUtils.npcList
    for i = list:size() - 1, 0, -1 do
        local npc = list:get(i)
        if not npc or not npc.zombie or npc.zombie:isDead() then
            list:remove(i)
        end
    end
end

---@param target? IsoGameCharacter
---@return boolean
function ChaosNPCUtils.IsTargetGrappled(target)
    if not target then return false end
    if target:isBeingGrappled() then return true end
    if target:isZombie() then
        ---@cast target IsoZombie
        if target:isReanimatedForGrappleOnly() then return true end
    end
    return false
end

---@param npc ChaosNPC
---@return IsoGameCharacter?
function ChaosNPCUtils.FindNewTargetForNPC(npc)
    if not npc then return end

    if not npc.zombie then return end
    local zombie = npc.zombie

    local cell = zombie:getCell()

    local x1, y1, z1 = zombie:getX(), zombie:getY(), zombie:getZ()

    local allZombies = cell:getZombieList()

    local maxDist = 5.0

    ---@type IsoGameCharacter?
    local nearestTarget = nil
    ---@type number
    local nearestDist = 0

    for i = 0, allZombies:size() - 1 do
        local otherZombie = allZombies:get(i)
        if otherZombie then
            if otherZombie:isAlive() and otherZombie ~= zombie and not ChaosNPCUtils.IsTargetGrappled(otherZombie) then
                local dist = ChaosUtils.distTo(x1, y1, otherZombie:getX(), otherZombie:getY())
                local z2 = otherZombie:getZ()

                if dist <= maxDist and z1 == z2 then
                    local rel = ChaosNPCRelations.GetRelationForNPC(npc, otherZombie)
                    if rel == ChaosNPCRelationType.ATTACK then
                        if not nearestTarget or dist < nearestDist then
                            nearestTarget = otherZombie
                            nearestDist = dist
                        end
                    end
                end
            end
        end
    end

    -- Check player as potential target
    local player = getPlayer()
    if player then
        local playerRel = ChaosNPCRelations.GetRelationForNPC(npc, player)
        if playerRel == ChaosNPCRelationType.ATTACK then
            local dist = ChaosUtils.distTo(x1, y1, player:getX(), player:getY())
            if dist <= maxDist and z1 == player:getZ() then
                if not nearestTarget or dist < nearestDist then
                    nearestTarget = player
                end
            end
        end
    end

    return nearestTarget
end

---@param zombie IsoZombie
---@return ChaosNPC?
function ChaosNPCUtils.GetNPCFromZombie(zombie)
    if not zombie then return end

    local modData = zombie:getModData()
    if not modData then return end

    local npc = modData[CHAOS_NPC_MOD_DATA_KEY_2]
    return npc
end

---@param zombie IsoZombie
---@return boolean
function ChaosNPCUtils.IsNPC(zombie)
    if not zombie then return false end

    local modData = zombie:getModData()
    if not modData then return false end

    local isNPC = modData[CHAOS_NPC_MOD_DATA_KEY] and true or false
    return isNPC
end

---@param square IsoGridSquare
---@return ChaosNPC?
function ChaosNPCUtils.GetNearestNPC(square)
    if not square then return end
    if ChaosNPCUtils.npcList:size() == 0 then return end

    local nearestNPC = nil
    local nearestDist = 0.0

    local x1, y1 = square:getX(), square:getY()

    for i = 0, ChaosNPCUtils.npcList:size() - 1 do
        local npc = ChaosNPCUtils.npcList:get(i)
        if npc and npc.zombie then
            local npcSquare = npc.zombie:getSquare()
            if npcSquare then
                local npcX, npcY = npcSquare:getX(), npcSquare:getY()
                local dist = ChaosUtils.distTo(x1, y1, npcX, npcY)
                if not nearestNPC or dist < nearestDist then
                    nearestNPC = npc
                    nearestDist = dist
                end
            end
        end
    end

    return nearestNPC
end

---@param tag string
---@return ChaosNPC[]
function ChaosNPCUtils.GetNPCsWithTag(tag)
    local result = {}
    for i = 0, ChaosNPCUtils.npcList:size() - 1 do
        local npc = ChaosNPCUtils.npcList:get(i)
        if npc and npc.zombie and npc:HasTag(tag) then
            table.insert(result, npc)
        end
    end
    return result
end

local function startsWith(str, prefix)
    return str and string.sub(str, 1, #prefix) == prefix
end


---@param zombie IsoZombie
---@param message string
---@param intervalMs? integer
local function LogZombieNPCDebug(zombie, message, intervalMs)
    if DEBUG_ZOMBIES_NPC_UTILS_LOGS ~= true then return end
    if not zombie then return end
    intervalMs = intervalMs or 1000

    local modData = zombie:getModData()
    if not modData then return end

    local now = ChaosMod.lastTimeTickMs or getTimestampMs()
    local lastLogMs = modData["ChaosNPCZombieDebugLastLogMs"] or 0
    if now - lastLogMs < intervalMs then return end
    modData["ChaosNPCZombieDebugLastLogMs"] = now

    local target = zombie:getTarget()
    local targetId = "nil"
    if target then
        targetId = tostring(target:getID())
    end

    local biteData = modData["ZombieAttackBiteData"]
    local biteInfo = "none"
    if biteData then
        biteInfo = string.format("elapsed=%d cancelled=%s target=%s",
            now - (biteData.startTime or now),
            tostring(biteData.cancelled),
            tostring(biteData.target and biteData.target.zombie and biteData.target.zombie:getID() or nil)
        )
    end

    print(string.format(
        "[ChaosNPCUtils][zombie=%s] %s | state=%s current=%s bump=%s target=%s useless=%s bite=%s hp=%.2f",
        tostring(zombie:getID()),
        tostring(message),
        tostring(zombie:getActionStateName()),
        tostring(zombie:getCurrentStateName()),
        tostring(zombie:getBumpType()),
        targetId,
        tostring(zombie:isUseless()),
        biteInfo,
        zombie:getHealth()
    ))
end

---@param zombie IsoZombie
---@return boolean
local function RecoverZombieHitReactionAfterNPCDamage(zombie)
    if not zombie then return false end

    local modData = zombie:getModData()
    if not modData then return false end

    local lastDamageTimeMs = modData["ChaosLastNPCDamageTimeMs"]
    if not lastDamageTimeMs then return false end

    local elapsedMs = ChaosMod.lastTimeTickMs - lastDamageTimeMs
    if elapsedMs < ZOMBIE_NPC_HITREACTION_RECOVERY_MS then return false end

    local actionState = zombie:getActionStateName()
    local isStuckHitReaction = actionState == "hitreaction" or actionState == "staggerback" or
        startsWith(tostring(actionState), "hitreaction-") or startsWith(tostring(actionState), "staggerback-")

    if not isStuckHitReaction then
        if elapsedMs > 5000 then
            modData["ChaosLastNPCDamageTimeMs"] = nil
            modData["ChaosLastNPCDamageById"] = nil
        end
        return false
    end

    LogZombieNPCDebug(zombie, string.format("recover_stuck_after_npc_hit elapsed=%d byNpc=%s", elapsedMs,
        tostring(modData["ChaosLastNPCDamageById"])), 0)

    zombie:setHitReaction("")
    zombie:setStaggerBack(false)
    zombie:setBumpType("")
    zombie:clearVariable("hitreaction")
    zombie:clearVariable("BumpType")
    zombie:clearVariable("bStaggerBack")
    zombie:clearVariable("ZombieHitReaction")
    zombie:clearVariable("AttackDidDamage")
    zombie:clearVariable("ZombieBiteDone")
    zombie:setAttackOutcome("interrupted")

    pcall(function()
        zombie:changeState(ZombieIdleState.instance())
    end)

    modData["ChaosLastNPCDamageTimeMs"] = nil
    modData["ChaosLastNPCDamageById"] = nil
    return true
end

---@param data table
local function FinishZombieBiteNPCAttack(data)
    local attacker = data.attacker
    ---@type ChaosNPC
    local target = data.target
    local targetZombie = target and target.zombie

    if attacker and attacker.getModData then
        local attackerModData = attacker:getModData()
        if attackerModData and attackerModData["ZombieAttackBiteData"] == data then
            attackerModData["ZombieAttackBiteData"] = nil
        end
    end

    if data.cancelled then
        print(string.format("[ChaosNPCUtils] Bite attack cancelled attacker=%s target=%s elapsed=%d",
            tostring(attacker and attacker:getID() or nil),
            tostring(targetZombie and targetZombie:getID() or nil),
            ChaosMod.lastTimeTickMs - (data.startTime or ChaosMod.lastTimeTickMs)
        ))
        return true
    end

    if not attacker or not targetZombie or not targetZombie:isAlive() then
        print(string.format("[ChaosNPCUtils] Bite attack expired attacker=%s target=%s reason=invalid_or_dead",
            tostring(attacker and attacker:getID() or nil),
            tostring(targetZombie and targetZombie:getID() or nil)
        ))
        return true
    end

    local dist = ChaosUtils.distTo(attacker:getX(), attacker:getY(), targetZombie:getX(), targetZombie:getY())
    if dist >= 1.15 or math.abs(attacker:getZ() - targetZombie:getZ()) >= 0.3 then
        print(string.format("[ChaosNPCUtils] Bite attack missed attacker=%s target=%s dist=%.2f elapsed=%d",
            tostring(attacker:getID()),
            tostring(targetZombie:getID()),
            dist,
            ChaosMod.lastTimeTickMs - (data.startTime or ChaosMod.lastTimeTickMs)
        ))
        return true
    end

    attacker:playSound("ZombieBite")

    -- Do NOT call targetZombie:Hit() here. NPCs are IsoZombie, and the vanilla
    -- zombie hit/stagger animation state can leave custom NPC AI stuck in idle/staggerback.
    -- Apply bite damage directly and let ChaosNPC AI decide how to react.
    local biteDamage = ChaosUtils.RandFloat(0.25, 0.45)
    local oldHealth = targetZombie:getHealth()
    targetZombie:setAttackedBy(attacker)
    targetZombie:applyDamage(biteDamage)
    if targetZombie:getHealth() >= oldHealth then
        targetZombie:setHealth(math.max(0.0, oldHealth - biteDamage))
    end

    print(string.format(
        "[ChaosNPCUtils] Bite attack hit npc=%s attacker=%s damage=%.2f health=%.2f oldHealth=%.2f state=%s current=%s bump=%s hit=%s stagger=%s elapsed=%d",
        tostring(targetZombie:getID()),
        tostring(attacker:getID()),
        biteDamage,
        targetZombie:getHealth(),
        oldHealth,
        tostring(targetZombie:getActionStateName()),
        tostring(targetZombie:getCurrentStateName()),
        tostring(targetZombie:getBumpType()),
        tostring(targetZombie:getHitReaction()),
        tostring(targetZombie:isStaggerBack()),
        ChaosMod.lastTimeTickMs - (data.startTime or ChaosMod.lastTimeTickMs)
    ))

    targetZombie:addBlood(BloodBodyPartType.Torso_Upper,
        true, true, false)

    if targetZombie:isDead() then
        pcall(function()
            targetZombie:Kill(attacker)
        end)
    end

    target.lastZombieBiteTimeMs = ChaosMod.lastTimeTickMs
    target.lastZombieThatAttackedNPC = attacker
    target:OnZombieDamagedNPC(attacker)
    return true
end

---@param attacker IsoZombie
---@param target ChaosNPC
local function StartZombieBiteNPCSpecialAction(attacker, target)
    local attackerModData = attacker:getModData()
    if not attackerModData then return end

    local oldBiteData = attackerModData["ZombieAttackBiteData"]
    if oldBiteData then
        oldBiteData.cancelled = true
    end

    local data = {
        attacker = attacker,
        target = target,
        startTime = ChaosMod.lastTimeTickMs,
        damageDelayMs = ZOMBIE_NPC_BITE_DAMAGE_DELAY_MS,
        cancelWindowMs = ZOMBIE_NPC_BITE_CANCEL_WINDOW_MS,
        cancelled = false,
    }

    attackerModData["ZombieAttackBiteData"] = data

    ChaosSpecialAction.AddNewAction(data, ZOMBIE_NPC_BITE_DAMAGE_DELAY_MS,
        function(_deltaMs, _data)
        end,
        FinishZombieBiteNPCAttack,
        function(cancelData)
            cancelData.cancelled = true
        end)
end

---@param zombie IsoZombie
function ChaosNPCUtils.OnZombieUpdateForNPC(zombie)
    -- print("OnZombieUpdateFor Non NPC: " .. tostring(zombie))
    if not zombie then return end
    if not ChaosMod.enabled then return end
    if ChaosNPCUtils.IsNPC(zombie) then return end

    local actionState = zombie:getActionStateName()

    if RecoverZombieHitReactionAfterNPCDamage(zombie) then
        actionState = zombie:getActionStateName()
    end

    local blockActionStates = {
        onground = true,
        falldown = true,
        staggerback = true,
        hitreaction = true,

        ["getup"] = true,
        ["getup-fromOnBack"] = true,
        ["getup-fromOnFront"] = true,
        ["getup-fromSitting"] = true,

        falling = true,
        bumped = true,
        getdown = true,
        grappled = true,

        climbfence = true,
        climbwindow = true,

        vehicleCollision = true,
    }

    local blockActionStatePrefixes = {
        "hitreaction-",
        "falldown-",
        "staggerback-",
        "knockeddown-",
        "onground-",
        "vehicleCollision-",
        "corpseThrown",
        "corpseThrownoverFence",
    }

    if actionState then
        if blockActionStates[actionState] then
            LogZombieNPCDebug(zombie, "skip_blocked_action_state " .. tostring(actionState), 1500)
            return
        end

        for i = 1, #blockActionStatePrefixes do
            if startsWith(actionState, blockActionStatePrefixes[i]) then
                LogZombieNPCDebug(zombie, "skip_blocked_action_prefix " .. tostring(actionState), 1500)
                return
            end
        end
    end

    local modData = zombie:getModData()

    local square = zombie:getSquare()
    if not square then return end

    local player = getPlayer()
    if not player then return end

    if ChaosNPCUtils.npcList:size() == 0 then return end

    local bumpType = zombie:getBumpType()
    if bumpType == "ZombieBite" or actionState == "attack" then
        LogZombieNPCDebug(zombie, "skip_already_attacking_or_biting", 1000)
        return
    end

    local nearestNPC = ChaosNPCUtils.GetNearestNPC(square)


    -- print("[ChaosNPCUtils] Nearest NPC: " .. tostring(nearestNPC))

    local x1, y1 = zombie:getX(), zombie:getY()

    local playerX, playerY = player:getX(), player:getY()
    local distToPlayer = ChaosUtils.distTo(x1, y1, playerX, playerY)
    if distToPlayer < 2.0 then
        LogZombieNPCDebug(zombie, string.format("skip_player_too_close distPlayer=%.2f", distToPlayer), 1500)
        return
    end

    if not nearestNPC then
        LogZombieNPCDebug(zombie, "skip_no_nearest_npc", 2000)
        return
    end
    local zombieNPC = nearestNPC.zombie
    if not zombieNPC then
        LogZombieNPCDebug(zombie, "skip_nearest_npc_no_zombie", 2000)
        return
    end
    if not zombieNPC:isAlive() then
        LogZombieNPCDebug(zombie, "skip_nearest_npc_dead target=" .. tostring(zombieNPC:getID()), 2000)
        return
    end
    if zombieNPC:getVehicle() ~= nil then
        LogZombieNPCDebug(zombie, "skip_nearest_npc_in_vehicle target=" .. tostring(zombieNPC:getID()), 2000)
        return
    end
    local x2, y2 = zombieNPC:getX(), zombieNPC:getY()

    local distToNPC = ChaosUtils.distTo(x1, y1, x2, y2)
    if distToNPC > 15.0 then
        LogZombieNPCDebug(zombie,
            string.format("skip_npc_too_far target=%s dist=%.2f", tostring(zombieNPC:getID()), distToNPC), 2000)
        return
    end

    if distToNPC > 3.0 then
        if zombie:CanSee(zombieNPC) then
            LogZombieNPCDebug(zombie,
                string.format("path_to_npc target=%s dist=%.2f", tostring(zombieNPC:getID()), distToNPC), 1200)
            zombie:pathToCharacter(zombieNPC)
            -- if actionState ~= "lunge" then
            -- zombie:changeState(LungeState.instance())
            -- end
        else
            LogZombieNPCDebug(zombie,
                string.format("face_npc_cannot_see target=%s dist=%.2f", tostring(zombieNPC:getID()), distToNPC), 1200)
            zombie:faceThisObject(zombieNPC)
        end
        return
    end

    zombie:spottedNew(player, true)
    zombie:addAggro(zombieNPC, 1)
    zombie:setTarget(zombieNPC)
    zombie:setAttackedBy(zombieNPC)
    LogZombieNPCDebug(zombie,
        string.format("engage_close_npc target=%s dist=%.2f canSee=%s facing=%s", tostring(zombieNPC:getID()), distToNPC,
            tostring(zombie:CanSee(zombieNPC)), tostring(zombie:isFacingObject(zombieNPC, 0.3))), 800)
    -- print("[ChaosNPCUtils] Spotted new NPC")

    local z1 = zombie:getZ()
    local z2 = zombieNPC:getZ()

    -- print("[ChaosNPCUtils] Distance to NPC: " ..
    -- tostring(distToNPC) .. " math abs z1 z2: " .. tostring(math.abs(z1 - z2)))

    if distToNPC < 1.0 and math.abs(z1 - z2) < 0.3 then
        local isWallToNPC = zombie:getSquare():isSomethingTo(zombieNPC:getSquare())
        if isWallToNPC then
            LogZombieNPCDebug(zombie,
                string.format("close_but_wall_to_npc target=%s dist=%.2f", tostring(zombieNPC:getID()), distToNPC), 1000)
            return
        end

        local isFacingNPC = zombie:isFacingObject(zombieNPC, 0.3)
        if isFacingNPC then
            local newBumpType = zombie:getBumpType()
            local pendingBite = modData["ZombieAttackBiteData"] ~= nil
            if newBumpType ~= "ZombieBite" and not pendingBite then
                zombie:setBumpType("ZombieBite")
                zombie:setTarget(zombieNPC)
                -- zombie:changeState(AttackState.instance())
                -- zombie:setVariable("AttackType", "bite")
                StartZombieBiteNPCSpecialAction(zombie, nearestNPC)
                print(string.format(
                    "[ChaosNPCUtils] Starting bite attack attacker=%s target=%s damageDelay=%d cancelWindow=%d",
                    tostring(zombie:getID()),
                    tostring(zombieNPC:getID()),
                    ZOMBIE_NPC_BITE_DAMAGE_DELAY_MS,
                    ZOMBIE_NPC_BITE_CANCEL_WINDOW_MS
                ))
            else
                LogZombieNPCDebug(zombie,
                    string.format("close_ready_but_no_bite target=%s dist=%.2f newBump=%s pendingBite=%s",
                        tostring(zombieNPC:getID()), distToNPC, tostring(newBumpType), tostring(pendingBite)), 800)
            end
        else
            LogZombieNPCDebug(zombie,
                string.format("close_not_facing_npc target=%s dist=%.2f", tostring(zombieNPC:getID()), distToNPC), 800)
            zombie:faceThisObject(zombieNPC)
        end
    else
        LogZombieNPCDebug(zombie,
            string.format("near_not_in_bite_range target=%s dist=%.2f zDiff=%.2f", tostring(zombieNPC:getID()), distToNPC,
                math.abs(z1 - z2)), 1000)
    end
end
