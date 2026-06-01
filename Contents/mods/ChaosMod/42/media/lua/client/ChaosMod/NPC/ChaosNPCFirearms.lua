---@diagnostic disable: undefined-field
require "ChaosMod/NPC/ChaosNPCConstants"

local function debugLog(...)
    if CHAOS_NPC_DEBUG_LOGS ~= true then return end
    print(...)
end

ChaosNPCFirearms = ChaosNPCFirearms or {}

ChaosNPCFirearms.FIREARM_MAX_RANGE = { handgun = 8, shotgun = 8, rifle = 20 }
ChaosNPCFirearms.FIREARM_ENGAGE_RANGE = { handgun = 4, shotgun = 4, rifle = 10 }
ChaosNPCFirearms.FIREARM_AIM_MS = { handgun = 500, shotgun = 700, rifle = 1000 }
ChaosNPCFirearms.FIREARM_SHOT_COOLDOWN = { handgun = 600, shotgun = 1200, rifle = 225 }
ChaosNPCFirearms.FIREARM_ACC_CLOSE = { handgun = 0.8, shotgun = 0.8, rifle = 0.8 }
ChaosNPCFirearms.FIREARM_ACC_FAR = { handgun = 0.15, shotgun = 0.15, rifle = 0.05 }
ChaosNPCFirearms.FIREARM_RELOAD_MS = 2500
ChaosNPCFirearms.FIREARM_VEHICLE_WIN_DMG = 15
ChaosNPCFirearms.FIREARM_VEHICLE_PART_DMG = 5
ChaosNPCFirearms.FIREARM_VEHICLE_HIT_MUL = 0.3
ChaosNPCFirearms.FIREARM_TIRE_POP_CHANCE = 0.5
ChaosNPCFirearms.DAMAGE_MUL_ZOMBIE = 2.0
ChaosNPCFirearms.DAMAGE_MUL_PLAYER = 0.5
ChaosNPCFirearms.DEFAULT_MAX_AMMO = 8
ChaosNPCFirearms.POST_ENGAGE_MS = 600
ChaosNPCFirearms.DEFAULT_ACCURACY_ZOMBIES = 1.0
ChaosNPCFirearms.DEFAULT_ACCURACY_PLAYERS = 0.25
ChaosNPCFirearms.PLAYER_GENERAL_HEALTH_DMG = 8.0

ChaosNPCFirearms.FIREARM_LUT = {
    ["Base.JS3T_Shotgun"] = "shotgun",
    ["Base.DoubleBarrelShotgun"] = "shotgun",
    ["Base.Shotgun"] = "shotgun",
    ["Base.DoubleBarrelShotgunSawnoff"] = "shotgun",
    ["Base.ShotgunSawnoff"] = "shotgun",
}

---@param weapon InventoryItem?
---@return string "handgun" | "rifle" | "shotgun" | "none"
function ChaosNPCFirearms.Classify(weapon)
    if not weapon then return "none" end

    local fullType = weapon.getFullType and weapon:getFullType() or nil
    if fullType and ChaosNPCFirearms.FIREARM_LUT[fullType] then
        return ChaosNPCFirearms.FIREARM_LUT[fullType]
    end

    if not weapon.isRanged or not weapon:isRanged() then return "none" end
    if weapon.isAimedFirearm and not weapon:isAimedFirearm() then return "none" end

    local ammoKey = ""
    if weapon.getAmmoType then
        local ammo = weapon:getAmmoType()
        if ammo then
            if ammo.getItemKey then
                local key = ammo:getItemKey()
                if key ~= nil then
                    ammoKey = tostring(key)
                end
            end
            if ammoKey == "" then
                ammoKey = tostring(ammo)
            end
        end
    end

    local projCount = (weapon.getProjectileCount and weapon:getProjectileCount()) or 1
    if ammoKey == "base:shotgun_shells" or projCount > 1 then
        return "shotgun"
    end

    if weapon.isTwoHandWeapon and not weapon:isTwoHandWeapon() then
        return "handgun"
    end

    return "rifle"
end

---@param worldObj IsoWorldInventoryObject?
---@return boolean
function ChaosNPCFirearms.IsGroundFirearmWorldObject(worldObj)
    if not worldObj then return false end
    local item = worldObj:getItem()
    if not item or not item:IsWeapon() then return false end
    return ChaosNPCFirearms.Classify(item) ~= "none"
end

---@param npc ChaosNPC
---@param weapon InventoryItem?
function ChaosNPCFirearms.OnSetFirearm(npc, weapon)
    if not npc or not npc.zombie or not weapon then
        ChaosNPCFirearms.ClearFirearm(npc)
        return
    end

    local fType = ChaosNPCFirearms.Classify(weapon)
    if fType == "none" then
        ChaosNPCFirearms.ClearFirearm(npc)
        return
    end

    local maxAmmo = 0
    if weapon.getMaxAmmo then
        maxAmmo = weapon:getMaxAmmo() or 0
    end
    if maxAmmo <= 0 then
        maxAmmo = ChaosNPCFirearms.DEFAULT_MAX_AMMO
    end

    npc.firearmType = fType
    npc.maxAmmo = maxAmmo
    npc.currentAmmo = maxAmmo
    npc.firearmAccuracyZombies = npc.firearmAccuracyZombies or ChaosNPCFirearms.DEFAULT_ACCURACY_ZOMBIES
    npc.firearmAccuracyPlayers = npc.firearmAccuracyPlayers or ChaosNPCFirearms.DEFAULT_ACCURACY_PLAYERS
    npc.firearmStateType = nil
    npc.firearmStateEndMs = 0

    npc.zombie:setVariable("ChaosFirearmType", fType)

    debugLog(string.format(
        "[ChaosNPCFirearms][npc=%s] equipped firearm=%s type=%s ammo=%d",
        tostring(npc.zombie:getID()),
        tostring(weapon:getFullType()),
        fType,
        maxAmmo
    ))
end

---@param npc ChaosNPC?
function ChaosNPCFirearms.ClearFirearm(npc)
    if not npc then return end
    npc.firearmType = nil
    npc.maxAmmo = 0
    npc.currentAmmo = 0
    npc.firearmStateType = nil
    npc.firearmStateEndMs = 0
    if npc.zombie then
        npc.zombie:setVariable("ChaosFirearmType", "none")
    end
end

---@param fType string
---@param dist number
---@return number
function ChaosNPCFirearms.AccuracyForDist(fType, dist)
    local maxRange = ChaosNPCFirearms.FIREARM_MAX_RANGE[fType] or 8
    local closeAcc = ChaosNPCFirearms.FIREARM_ACC_CLOSE[fType] or 0.8
    local farAcc = ChaosNPCFirearms.FIREARM_ACC_FAR[fType] or 0.15
    if dist <= 0 then return closeAcc end
    local t = dist / maxRange
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    return closeAcc + (farAcc - closeAcc) * t
end

---@param zombie IsoZombie
---@param target IsoGameCharacter?
local function faceTarget(zombie, target)
    if not zombie or not target then return end
    local dx = target:getX() - zombie:getX()
    local dy = target:getY() - zombie:getY()
    if dx == 0 and dy == 0 then return end
    pcall(function() zombie:setForwardDirection(dx, dy) end)
    pcall(function() zombie:faceThisObject(target) end)
end

---@param square IsoGridSquare?
local function addShotFlash(square)
    if not square then return end
    local cell = getCell()
    if not cell then return end
    local light = IsoLightSource.new(
        square:getX(), square:getY(), square:getZ(),
        0.8, 0.8, 0.6,
        18, 6
    )
    cell:addLamppost(light)
end

---@param npc ChaosNPC
---@param weapon HandWeapon
local function playShotSound(npc, weapon)
    if not npc or not npc.zombie or not weapon then return end
    local zombie = npc.zombie
    local sound = (weapon.getSwingSound and weapon:getSwingSound()) or "M16Shoot"
    if sound and sound ~= "" then
        zombie:playSound(sound)
    end

    local square = zombie:getSquare()
    if not square then return end

    local soundRadius = math.floor((weapon.getSoundRadius and weapon:getSoundRadius()) or 70)
    local soundVolume = math.floor((weapon.getSoundVolume and weapon:getSoundVolume()) or 100)
    getWorldSoundManager():addSound(
        nil,
        square:getX(), square:getY(), square:getZ(),
        soundRadius, soundVolume, false
    )
end

---@param npc ChaosNPC
---@param enemy IsoGameCharacter
---@return boolean true if the enemy is in a vehicle and we damaged it
local function damageVehicleOnHit(npc, enemy)
    local enemyVehicle = enemy:getVehicle()
    if not enemyVehicle then return false end

    local seat = enemyVehicle:getSeat(enemy)
    if seat == nil or seat < 0 then return true end
    local windowPartName = CHAOS_NPC_WINDOW_VEHICLE_PART_BY_SEAT[seat + 1]
    local windowPart = nil
    if windowPartName then
        windowPart = enemyVehicle:getPartById(windowPartName)
    end

    if windowPart and windowPart:getInventoryItem() then
        windowPart:damage(ChaosNPCFirearms.FIREARM_VEHICLE_WIN_DMG)
        if enemyVehicle.transmitPartCondition then
            enemyVehicle:transmitPartCondition(windowPart)
        end
        local sq = enemy:getSquare()
        if sq then sq:playSound("HitVehicleWindowWithWeapon") end
        if windowPart:getCondition() <= 0 then
            local win = windowPart.getWindow and windowPart:getWindow() or nil
            if win and not win:isOpen() then
                ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
                windowPart:setInventoryItem(nil, 10)
                if sq then sq:playSound("SmashWindow") end
            end
        end
    end

    local partCount = enemyVehicle:getPartCount()
    local choices = {}
    for i = 0, partCount - 1 do
        local p = enemyVehicle:getPartByIndex(i)
        if p and p ~= windowPart then
            local id = (p.getId and p:getId()) or ""
            if not string.find(tostring(id), "Window") then
                choices[#choices + 1] = p
            end
        end
    end
    if #choices > 0 then
        local picked = choices[ChaosUtils.RandArrayIndex(choices)]
        if picked then
            picked:damage(ChaosNPCFirearms.FIREARM_VEHICLE_PART_DMG)
            if enemyVehicle.transmitPartCondition then
                enemyVehicle:transmitPartCondition(picked)
            end
        end
    end

    if enemyVehicle.updatePartStats then
        enemyVehicle:updatePartStats()
    end
    return true
end

---@param vehicle BaseVehicle?
---@return boolean true if a tire was popped
local function popRandomInflatedTire(vehicle)
    if not vehicle then return false end

    ---@type VehiclePart[]
    local parts = {}
    ---@type integer[]
    local wheels = {}
    for _, tireId in ipairs(VEHICLE_TIRES) do
        local part = vehicle:getPartById(tireId)
        if part then
            local wheelId = part:getWheelIndex()
            if wheelId >= 0 then
                parts[#parts + 1] = part
                wheels[#wheels + 1] = wheelId
            end
        end
    end
    if #parts == 0 then return false end

    local idx = ChaosUtils.RandArrayIndex(parts)
    local part = parts[idx]
    local wheelId = wheels[idx]
    if not part or not wheelId then return false end
    part:setContainerContentAmount(0, true, true)
    vehicle:setTireInflation(wheelId, 0)
    vehicle:transmitPartModData(part)
    vehicle:updatePartStats()

    local sq = vehicle:getSquare()
    if sq then sq:playSound("VehicleTireExplode") end
    return true
end

---@param shooterNpc ChaosNPC
---@param soundRadius number
function ChaosNPCFirearms.AlertNearbyHostileNPCs(shooterNpc, soundRadius)
    if not shooterNpc or not shooterNpc.zombie or not soundRadius or soundRadius <= 0 then return end
    local shooterZombie = shooterNpc.zombie
    local sx, sy, sz = shooterZombie:getX(), shooterZombie:getY(), shooterZombie:getZ()

    ChaosZombie.ForEachZombieInRange(sx, sy, soundRadius, function(otherZombie)
        if not otherZombie or otherZombie == shooterZombie then return end
        if not otherZombie:isAlive() then return end
        if not ChaosNPCUtils.IsNPC(otherZombie) then return end

        local otherNpc = ChaosNPCUtils.GetNPCFromZombie(otherZombie)
        if not otherNpc then return end
        if otherNpc.enemy then return end

        local rel = ChaosNPCRelations.GetRelationForNPC(otherNpc, shooterZombie)
        if rel ~= ChaosNPCRelationType.ATTACK then return end

        debugLog(string.format(
            "[ChaosNPCFirearms][npc=%s] gunshot alerted hostile npc=%s -> new enemy",
            tostring(shooterZombie:getID()),
            tostring(otherZombie:getID())))
        otherNpc:SetAsTargetEnemy(shooterZombie)
    end, false, sz)
end

---@param npc ChaosNPC
---@return boolean
function ChaosNPCFirearms.IsNPCInPlayerShieldRadius(npc)
    if not npc or not npc.zombie then return false end
    local player = getPlayer()
    if not player then return false end

    local modData = player:getModData()
    if not modData or not modData.CHAOS_SHIELD_ENABLED then return false end

    local radius = modData.CHAOS_SHIELD_RADIUS or 0
    if radius <= 0 then return false end

    local zombie = npc.zombie
    if zombie:getZ() ~= player:getZ() then return false end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    return dist <= radius
end

---@param npc ChaosNPC
---@param weapon HandWeapon
---@param enemy IsoGameCharacter
function ChaosNPCFirearms.ApplyShotHit(npc, weapon, enemy)
    if not npc.zombie or not enemy or enemy:isDead() then return end
    if not weapon then return end
    local zombie = npc.zombie

    if not enemy:isZombie() then
        if instanceof(enemy, "IsoPlayer") and ChaosNPCUtils.IsNPCIgnorePlayerActive() then
            return
        end
        local player = getPlayer()
        if player and enemy == player then
            local modData = player:getModData()
            if modData and modData.CHAOS_SHIELD_ENABLED then
                if not ChaosNPCFirearms.IsNPCInPlayerShieldRadius(npc) then
                    debugLog(string.format(
                        "[ChaosNPCFirearms][npc=%s] shot blocked by player energy shield",
                        tostring(zombie:getID())))
                    return
                end
            end
        end
    end

    local minDamage = (weapon.getMinDamage and weapon:getMinDamage()) or 0.8
    local maxDamage = (weapon.getMaxDamage and weapon:getMaxDamage()) or 1.2
    if minDamage <= 0 then minDamage = 0.8 end
    if maxDamage <= 0 then maxDamage = 1.2 end

    local damage = ChaosUtils.RandFloat(minDamage, maxDamage)

    if enemy:isZombie() then
        damage = damage * ChaosNPCFirearms.DAMAGE_MUL_ZOMBIE
    else
        damage = damage * ChaosNPCFirearms.DAMAGE_MUL_PLAYER
    end
    damage = damage * (npc.DamageMultiplier or 1.0)
    if damage < 0.1 then damage = 0.1 end

    enemy:setAttackedBy(zombie)

    if enemy:isZombie() then
        ---@type IsoZombie
        local zEnemy = enemy
        local oldHealth = zEnemy:getHealth()
        local appliedDamage = enemy:Hit(weapon, zombie, damage, false, 1.0)
        if zEnemy:isAlive() and zEnemy:getHealth() >= oldHealth then
            zEnemy:applyDamage(damage)
            if zEnemy:getHealth() >= oldHealth then
                zEnemy:setHealth(math.max(0.0, oldHealth - damage))
            end
        end

        local zombieHitSound = weapon.getZombieHitSound and weapon:getZombieHitSound()
        if zombieHitSound then
            enemy:playSound(zombieHitSound)
        end

        if zEnemy:isDead() then
            pcall(function() zEnemy:Kill(weapon, zombie) end)
        end

        zEnemy:clearVariable("AttackDidDamage")
        zEnemy:clearVariable("ZombieBiteDone")
        zEnemy:setAttackOutcome("interrupted")

        debugLog(string.format(
            "[ChaosNPCFirearms][npc=%s zEnemy=%s] hit dmg=%.2f applied=%.2f old=%.2f new=%.2f alive=%s",
            tostring(zombie:getID()), tostring(zEnemy:getID()),
            damage, appliedDamage or -1, oldHealth, zEnemy:getHealth(),
            tostring(zEnemy:isAlive())
        ))
    else
        -- Player target: do not use :Hit. Mirror the melee-vs-player handling
        -- (blood, knockdown / hit reaction) but apply a fixed general-health
        -- hit instead, and without adding wounds.
        local splatCount = (weapon.getSplatNumber and weapon:getSplatNumber()) or 0
        for _ = 0, splatCount do
            enemy:splatBlood(2, 0.25)
        end

        if enemy.playBloodSplatterSound then
            enemy:playBloodSplatterSound()
        end

        local bodyDamage = enemy:getBodyDamage()

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

        bodyDamage:ReduceGeneralHealth(ChaosNPCFirearms.PLAYER_GENERAL_HEALTH_DMG)

        debugLog(string.format(
            "[ChaosNPCFirearms][npc=%s pEnemy=%s] reduceGeneralHealth=%.2f",
            tostring(zombie:getID()), tostring(enemy:getID()),
            ChaosNPCFirearms.PLAYER_GENERAL_HEALTH_DMG
        ))
    end
end

---@param npc ChaosNPC
function ChaosNPCFirearms.FireShot(npc)
    if not npc.zombie or not npc.enemy then return end
    if not npc.firearmType then return end
    local zombie = npc.zombie
    local enemy = npc.enemy
    local weapon = npc.weaponItemCached
    if not weapon then return end
    local fType = npc.firearmType

    npc.attackHitPassed = true
    npc.attackAnimName = "ZombieAttackFirearm"
    faceTarget(zombie, enemy)
    zombie:setBumpType("ZombieAttackFirearm")

    npc.currentAmmo = math.max(0, (npc.currentAmmo or 0) - 1)
    npc.attackLastTimeMs = ChaosMod.lastTimeTickMs

    playShotSound(npc, weapon)
    addShotFlash(zombie:getSquare())

    local alertRadius = (weapon.getSoundRadius and weapon:getSoundRadius()) or 70
    ChaosNPCFirearms.AlertNearbyHostileNPCs(npc, alertRadius)

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), enemy:getX(), enemy:getY())
    local baseAcc = ChaosNPCFirearms.AccuracyForDist(fType, dist)
    local accMul
    if enemy:isZombie() then
        accMul = npc.firearmAccuracyZombies or ChaosNPCFirearms.DEFAULT_ACCURACY_ZOMBIES
    else
        accMul = npc.firearmAccuracyPlayers or ChaosNPCFirearms.DEFAULT_ACCURACY_PLAYERS
    end
    local hitChance = baseAcc * accMul

    local hadVehicle = enemy:getVehicle() ~= nil
    if hadVehicle then
        damageVehicleOnHit(npc, enemy)
        hitChance = hitChance * ChaosNPCFirearms.FIREARM_VEHICLE_HIT_MUL
    end

    if hitChance < 0 then hitChance = 0 end
    if hitChance > 1 then hitChance = 1 end

    local roll = ChaosUtils.RandFloat(0, 1)
    debugLog(string.format(
        "[ChaosNPCFirearms][npc=%s enemy=%s] fired type=%s dist=%.2f baseAcc=%.2f accMul=%.2f hitChance=%.2f roll=%.2f vehicle=%s ammo=%d/%d",
        tostring(zombie:getID()), tostring(enemy:getID()),
        tostring(fType), dist, baseAcc, accMul, hitChance, roll,
        tostring(hadVehicle), npc.currentAmmo, npc.maxAmmo or 0
    ))

    if roll > hitChance then
        debugLog(string.format("[ChaosNPCFirearms][npc=%s enemy=%s] missed",
            tostring(zombie:getID()), tostring(enemy:getID())))
        return
    end

    ChaosNPCFirearms.ApplyShotHit(npc, weapon, enemy)

    if hadVehicle and ChaosUtils.RandFloat(0, 1) < ChaosNPCFirearms.FIREARM_TIRE_POP_CHANCE then
        local enemyVehicle = enemy:getVehicle()
        if enemyVehicle and popRandomInflatedTire(enemyVehicle) then
            debugLog(string.format("[ChaosNPCFirearms][npc=%s enemy=%s] popped tire on vehicle hit",
                tostring(zombie:getID()), tostring(enemy:getID())))
        end
    end
end

---@param npc ChaosNPC
function ChaosNPCFirearms.EnterAim(npc)
    if not npc.zombie or not npc.enemy or not npc.firearmType then
        ChaosNPCFirearms.CancelFirearmState(npc, "enter_aim_invalid")
        return
    end
    npc.firearmStateType = "aim"
    npc.firearmStateEndMs = ChaosMod.lastTimeTickMs +
        (ChaosNPCFirearms.FIREARM_AIM_MS[npc.firearmType] or 700)
    npc.attackHitPassed = false
    npc.attackAnimName = "ZombieAimFirearm"
    faceTarget(npc.zombie, npc.enemy)
    npc.zombie:setBumpType("ZombieAimFirearm")
    debugLog(string.format("[ChaosNPCFirearms][npc=%s] enter_aim type=%s aim_ms=%d",
        tostring(npc.zombie:getID()),
        tostring(npc.firearmType),
        ChaosNPCFirearms.FIREARM_AIM_MS[npc.firearmType] or 700))
end

---@param npc ChaosNPC
function ChaosNPCFirearms.EnterCooldown(npc)
    if not npc.zombie then return end
    npc.firearmStateType = "cooldown"
    npc.firearmStateEndMs = ChaosMod.lastTimeTickMs +
        (ChaosNPCFirearms.FIREARM_SHOT_COOLDOWN[npc.firearmType] or 800)
    npc.attackAnimName = nil
    -- Do not clear BumpType here: the attack bump we just set in FireShot
    -- still needs to play out. The engine clears the bump variable itself
    -- when the bump animation finishes; the cooldown tick re-arms the aim
    -- bump as soon as it goes empty so the NPC visually stays in aim pose.
    debugLog(string.format("[ChaosNPCFirearms][npc=%s] enter_cooldown type=%s ms=%d",
        tostring(npc.zombie:getID()),
        tostring(npc.firearmType),
        ChaosNPCFirearms.FIREARM_SHOT_COOLDOWN[npc.firearmType] or 800))
end

---@param zombie IsoZombie?
local function clearBumpHard(zombie)
    if not zombie then return end
    zombie:setBumpType("")
    -- BumpedState in the engine waits for BumpAnimFinished=true to transition
    -- back to idle. We aggressively set it to false in reArmAimBumpIfMissing,
    -- so when we stop re-arming we MUST signal the engine that the bump is
    -- done — otherwise the zombie sits in BumpedState with an empty BumpType
    -- forever and the rest of the NPC AI (movement, attack restart) treats it
    -- as "still bumped" and refuses to do anything.
    zombie:setVariable("BumpAnimFinished", true)
end

---@param npc ChaosNPC?
function ChaosNPCFirearms.ForceExitBumpedState(npc)
    if not npc or not npc.zombie then return end
    clearBumpHard(npc.zombie)
end

---@param zombie IsoZombie?
---@return boolean
local function isIncapacitated(zombie)
    if not zombie then return true end
    if zombie:isKnockedDown() then return true end
    local as = zombie:getActionStateName() or ""
    if as == "onground" or as == "falldown" or as == "staggerback"
        or as == "hitreaction" or as == "falling"
        or as == "grappled" or as == "vehicleCollision" then
        return true
    end
    if string.sub(as, 1, 9) == "onground-"
        or string.sub(as, 1, 12) == "hitreaction-"
        or string.sub(as, 1, 10) == "falldown-"
        or string.sub(as, 1, 13) == "staggerback-"
        or string.sub(as, 1, 12) == "knockeddown-" then
        return true
    end
    return false
end

---@param zombie IsoZombie?
---@param tag string
local function reArmAimBumpIfMissing(zombie, tag)
    if not zombie then return end
    local bt = zombie:getVariableString("BumpType")
    local as = zombie:getActionStateName()
    -- Re-arm when the engine has cleared the bump string, or when the NPC is
    -- back in idle action state with anything other than the aim bump set.
    -- (Engine apparently doesn't honor m_Looped=true on bump animations, so
    -- the aim bump always ends after one play and we have to keep re-arming.)
    if bt == nil or bt == "" or (as == "idle" and bt ~= "ZombieAimFirearm") then
        zombie:setBumpType("ZombieAimFirearm")
        zombie:setVariable("BumpAnimFinished", false)
        debugLog(string.format(
            "[ChaosNPCFirearms][npc=%s] rearm_aim_bump tag=%s prevBump=%s actionState=%s",
            tostring(zombie:getID()),
            tostring(tag),
            tostring(bt),
            tostring(as)))
    end
end

---@param npc ChaosNPC
---@param zombie IsoZombie
---@param state string
local function diagFirearmTick(npc, zombie, state)
    local now = ChaosMod.lastTimeTickMs
    if not npc._lastFirearmDiagMs then npc._lastFirearmDiagMs = 0 end
    if now - npc._lastFirearmDiagMs < 250 then return end
    npc._lastFirearmDiagMs = now
    debugLog(string.format(
        "[ChaosNPCFirearms][npc=%s] diag state=%s bt=%s af=%s as=%s endIn=%d",
        tostring(zombie:getID()),
        tostring(state),
        tostring(zombie:getVariableString("BumpType")),
        tostring(zombie:getVariableBoolean("BumpAnimFinished")),
        tostring(zombie:getActionStateName()),
        (npc.firearmStateEndMs or 0) - now))
end

---@param npc ChaosNPC
---@param reason string
function ChaosNPCFirearms.EnterPostEngage(npc, reason)
    if not npc or not npc.zombie then return end
    if npc.firearmStateType == "post" then return end
    npc.firearmStateType = "post"
    npc.firearmStateEndMs = ChaosMod.lastTimeTickMs + ChaosNPCFirearms.POST_ENGAGE_MS
    npc.attackHitPassed = true
    npc.attackAnimName = "ZombieAimFirearm"
    reArmAimBumpIfMissing(npc.zombie, "post_enter")
    debugLog(string.format("[ChaosNPCFirearms][npc=%s] post_engage reason=%s",
        tostring(npc.zombie:getID()), tostring(reason)))
end

---@param npc ChaosNPC
function ChaosNPCFirearms.EnterReload(npc)
    if not npc.zombie then return end
    npc.firearmStateType = "reload"
    npc.firearmStateEndMs = ChaosMod.lastTimeTickMs + ChaosNPCFirearms.FIREARM_RELOAD_MS
    npc.attackAnimName = "ZombieReloadFirearm"
    npc.zombie:setBumpType("ZombieReloadFirearm")
    npc.zombie:setVariable("BumpAnimFinished", false)
    debugLog(string.format("[ChaosNPCFirearms][npc=%s] reload_start ms=%d",
        tostring(npc.zombie:getID()), ChaosNPCFirearms.FIREARM_RELOAD_MS))
end

---@param npc ChaosNPC
---@param reason string
function ChaosNPCFirearms.CancelFirearmState(npc, reason)
    if not npc then return end
    if npc.firearmStateType then
        debugLog(string.format("[ChaosNPCFirearms][npc=%s] cancel_state state=%s reason=%s",
            tostring(npc.zombie and npc.zombie:getID() or "?"),
            tostring(npc.firearmStateType),
            tostring(reason)))
    end
    npc.firearmStateType = nil
    npc.firearmStateEndMs = 0
    npc.isAttacking = false
    npc.attackHitPassed = false
    npc.attackAnimName = nil
    clearBumpHard(npc.zombie)
end

---@param npc ChaosNPC
function ChaosNPCFirearms.StartFirearmEngage(npc)
    if not npc.zombie or not npc.enemy or not npc.firearmType then return end
    local zombie = npc.zombie
    if zombie:getVehicle() then return end
    if isIncapacitated(zombie) then return end
    if zombie:getZ() ~= npc.enemy:getZ() then return end

    local maxRange = ChaosNPCFirearms.FIREARM_MAX_RANGE[npc.firearmType] or 8
    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), npc.enemy:getX(), npc.enemy:getY())
    if dist > maxRange then return end

    if npc:LineTraceToEnemy() ~= "Clear" then
        npc.hasBlockingCollisionToTargetThisFrame = true
        return
    end
    if not zombie:CanSee(npc.enemy) then return end
    if not npc.enemy:isZombie() and ChaosPlayer.IsPlayerKnockedDown(npc.enemy) then return end

    npc.isAttacking = true
    npc.attackHitPassed = false
    npc.attackObjectTarget = nil
    npc.attackObjectType = nil
    npc.pathfindUpdateMs = math.floor(CHAOS_NPC_MAX_PATHFIND_UPDATE_MS * 0.75)

    if (npc.currentAmmo or 0) <= 0 then
        ChaosNPCFirearms.EnterReload(npc)
    else
        ChaosNPCFirearms.EnterAim(npc)
    end
end

---@param npc ChaosNPC
---@param deltaMs integer
function ChaosNPCFirearms.OnFirearmAttackTick(npc, deltaMs)
    if not npc.zombie then return end
    if not npc.firearmStateType then
        ChaosNPCFirearms.CancelFirearmState(npc, "no_state")
        return
    end

    local zombie = npc.zombie
    if isIncapacitated(zombie) then
        ChaosNPCFirearms.CancelFirearmState(npc, "incapacitated")
        return
    end
    local now = ChaosMod.lastTimeTickMs
    local state = npc.firearmStateType
    local maxRange = ChaosNPCFirearms.FIREARM_MAX_RANGE[npc.firearmType] or 8

    if state == "aim" then
        diagFirearmTick(npc, zombie, "aim")
        if not npc.enemy or npc.enemy:isDead() then
            ChaosNPCFirearms.EnterPostEngage(npc, "enemy_lost")
            return
        end
        if zombie:getZ() ~= npc.enemy:getZ() then
            ChaosNPCFirearms.EnterPostEngage(npc, "enemy_z")
            return
        end
        local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(),
            npc.enemy:getX(), npc.enemy:getY())
        if dist > maxRange then
            ChaosNPCFirearms.EnterPostEngage(npc, "out_of_range")
            return
        end
        if npc:LineTraceToEnemy() ~= "Clear" then
            ChaosNPCFirearms.EnterPostEngage(npc, "los_lost")
            return
        end

        faceTarget(zombie, npc.enemy)
        reArmAimBumpIfMissing(zombie, "aim")

        if now >= npc.firearmStateEndMs then
            if (npc.currentAmmo or 0) <= 0 then
                ChaosNPCFirearms.EnterReload(npc)
                return
            end
            ChaosNPCFirearms.FireShot(npc)
            ChaosNPCFirearms.EnterCooldown(npc)
        end
        return
    end

    if state == "cooldown" then
        diagFirearmTick(npc, zombie, "cooldown")
        reArmAimBumpIfMissing(zombie, "cooldown")

        if now < npc.firearmStateEndMs then return end

        if (npc.currentAmmo or 0) <= 0 then
            ChaosNPCFirearms.EnterReload(npc)
            return
        end

        if not npc.enemy or npc.enemy:isDead() then
            ChaosNPCFirearms.EnterPostEngage(npc, "cooldown_no_enemy")
            return
        end
        if zombie:getZ() ~= npc.enemy:getZ() then
            ChaosNPCFirearms.EnterPostEngage(npc, "cooldown_z")
            return
        end
        local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(),
            npc.enemy:getX(), npc.enemy:getY())
        if dist > maxRange then
            ChaosNPCFirearms.EnterPostEngage(npc, "cooldown_out_of_range")
            return
        end
        if npc:LineTraceToEnemy() ~= "Clear" or not zombie:CanSee(npc.enemy) then
            ChaosNPCFirearms.EnterPostEngage(npc, "cooldown_los_lost")
            return
        end

        ChaosNPCFirearms.EnterAim(npc)
        return
    end

    if state == "post" then
        diagFirearmTick(npc, zombie, "post")
        reArmAimBumpIfMissing(zombie, "post")
        if now >= npc.firearmStateEndMs then
            ChaosNPCFirearms.CancelFirearmState(npc, "post_done")
            npc.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        end
        return
    end

    if state == "reload" then
        diagFirearmTick(npc, zombie, "reload")
        if now >= npc.firearmStateEndMs then
            npc.currentAmmo = npc.maxAmmo or ChaosNPCFirearms.DEFAULT_MAX_AMMO
            debugLog(string.format("[ChaosNPCFirearms][npc=%s] reload_finished ammo=%d",
                tostring(zombie:getID()), npc.currentAmmo))
            ChaosNPCFirearms.CancelFirearmState(npc, "reload_done")
            npc.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        end
        return
    end

    ChaosNPCFirearms.CancelFirearmState(npc, "unknown_state")
end

return ChaosNPCFirearms
