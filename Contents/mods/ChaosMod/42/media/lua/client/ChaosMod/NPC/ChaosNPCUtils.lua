---@class ChaosNPCUtils
---@field npcList ArrayList<ChaosNPC>
ChaosNPCUtils = ChaosNPCUtils or {
    npcList = ArrayList:new(),
}


---@param npc ChaosNPC
---@return IsoGameCharacter?
function ChaosNPCUtils.FindNewTargetForNPC(npc)
    if not npc then return end

    if not npc.zombie then return end
    local zombie = npc.zombie

    local cell = zombie:getCell()

    local x1, y1, z1 = zombie:getX(), zombie:getY(), zombie:getZ()

    local allZombies = cell:getZombieList()

    local maxDistZombie = 5.0
    local maxDistNPC = 5.0

    ---@type IsoZombie?
    local nearestZombie = nil
    ---@type number
    local nearestDist = 0

    for i = 0, allZombies:size() - 1 do
        local otherZombie = allZombies:get(i)
        if otherZombie then
            if otherZombie:isAlive() and otherZombie ~= zombie then
                local isNPC = ChaosNPCUtils.IsNPC(otherZombie)
                local dist = ChaosUtils.distTo(x1, y1, otherZombie:getX(), otherZombie:getY())
                local z2 = otherZombie:getZ()
                local maxDist = isNPC and maxDistNPC or maxDistZombie

                if dist <= maxDist and z1 == z2 then -- Only check if zombies are on the same level
                    if npc:IsEnemyToNPC(otherZombie) then
                        ---@diagnostic disable-next-line: invert-if
                        if not nearestZombie or dist < nearestDist then
                            nearestZombie = otherZombie
                            nearestDist = dist
                        end
                    end
                end
            end
        end
    end

    return nearestZombie
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

---@param zombie IsoZombie
function ChaosNPCUtils.OnZombieUpdateForNPC(zombie)
    -- print("OnZombieUpdateFor Non NPC: " .. tostring(zombie))
    if not zombie then return end
    if not ChaosMod.enabled then return end
    if ChaosNPCUtils.IsNPC(zombie) then return end

    local actionState = zombie:getActionStateName()

    if actionState == "onground" then
        return
    end

    local modData = zombie:getModData()

    local square = zombie:getSquare()
    if not square then return end

    local player = getPlayer()
    if not player then return end

    if ChaosNPCUtils.npcList:size() == 0 then return end

    local biteData = modData["ZombieAttackBiteData"]
    local bumpType = zombie:getBumpType()
    if biteData then
        if bumpType ~= "ZombieBite" and actionState ~= "attack" then
            modData["ZombieAttackBiteData"] = nil
        end

        local startTime = biteData["startTime"]
        ---@type ChaosNPC
        local target = biteData["target"]
        local targetZombie = target.zombie
        local canApplyAttack = ChaosMod.lastTimeTickMs - startTime > 600
        if bumpType == "ZombieBite" and targetZombie and canApplyAttack then
            local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), targetZombie:getX(), targetZombie:getY())

            if dist < 1.0 and targetZombie:isAlive() then
                zombie:playSound("ZombieBite")

                local fakeWeapon = instanceItem("Base.BareHands")

                targetZombie:Hit(fakeWeapon, zombie, 1, false, 1, false)
                print("[ChaosNPCUtils] Bite attack hit")
                targetZombie:setAttackedBy(zombie)
                targetZombie:addBlood(BloodBodyPartType.Torso_Upper,
                    true, true, false)

                -- targetZombie:changeState(ZombieHitReactionState.instance())
                local isBehind = zombie:isBehind(targetZombie)
                targetZombie:setHitFromBehind(isBehind)
                targetZombie:setHitReaction("Bite")
                targetZombie:setVariable("hitreaction", "Bite")
                targetZombie:setVariable("hashitreaction", true)
                targetZombie:reportEvent("wasHit")
                targetZombie:setHitForce(1.0)

                ---@diagnostic disable-next-line: param-type-mismatch
                targetZombie:setPlayerAttackPosition(isBehind and "BEHIND" or nil)
                -- local state = targetZombie:tryGetAIState("hitreaction-hit")
                -- if state then
                -- end

                target:OnZombieDamagedNPC(zombie)
            end

            modData["ZombieAttackBiteData"] = nil
        end
    end

    if bumpType == "ZombieBite" or actionState == "attack" then
        return
    end

    local nearestNPC = ChaosNPCUtils.GetNearestNPC(square)


    -- print("[ChaosNPCUtils] Nearest NPC: " .. tostring(nearestNPC))

    local x1, y1 = zombie:getX(), zombie:getY()

    local playerX, playerY = player:getX(), player:getY()
    if ChaosUtils.distTo(x1, y1, playerX, playerY) < 2.0 then
        return
    end

    if not nearestNPC then return end
    local zombieNPC = nearestNPC.zombie
    if not zombieNPC then return end
    if not zombieNPC:isAlive() then return end
    if zombieNPC:getVehicle() ~= nil then return end
    local x2, y2 = zombieNPC:getX(), zombieNPC:getY()

    local distToNPC = ChaosUtils.distTo(x1, y1, x2, y2)
    if distToNPC > 15.0 then
        return
    end

    if distToNPC > 3.0 then
        if zombie:CanSee(zombieNPC) then
            zombie:pathToCharacter(zombieNPC)
            -- if actionState ~= "lunge" then
            -- zombie:changeState(LungeState.instance())
            -- end
        else
            zombie:faceThisObject(zombieNPC)
        end
        return
    end

    zombie:spottedNew(player, true)
    zombie:addAggro(zombieNPC, 1)
    zombie:setTarget(zombieNPC)
    zombie:setAttackedBy(zombieNPC)
    -- print("[ChaosNPCUtils] Spotted new NPC")

    local z1 = zombie:getZ()
    local z2 = zombieNPC:getZ()

    -- print("[ChaosNPCUtils] Distance to NPC: " ..
    -- tostring(distToNPC) .. " math abs z1 z2: " .. tostring(math.abs(z1 - z2)))

    if distToNPC < 1.0 and math.abs(z1 - z2) < 0.3 then
        local isWallToNPC = zombie:getSquare():isSomethingTo(zombieNPC:getSquare())
        if isWallToNPC then
            -- print("[ChaosNPCUtils] Wall to NPC, skipping bite attack")
            return
        end

        if zombie:isFacingObject(zombieNPC, 0.3) then
            local bumpType = zombie:getBumpType()
            if bumpType ~= "ZombieBite" then
                zombie:setBumpType("ZombieBite")
                zombie:setTarget(zombieNPC)
                -- zombie:changeState(AttackState.instance())
                -- zombie:setVariable("AttackType", "bite")
                modData["ZombieAttackBiteData"] = {
                    startTime = ChaosMod.lastTimeTickMs,
                    target = nearestNPC
                }
                print("[ChaosNPCUtils] Starting bite attack")
            end
        else
            -- print("[ChaosNPCUtils] Not facing NPC, facing")
            zombie:faceThisObject(zombieNPC)
        end
    end
end
