--[[
    ChaosNPC — NPC system for Chaos Mod
    =====================================
    This NPC system was heavily inspired by the "Bandits NPC" mod:
    https://steamcommunity.com/workshop/filedetails/?id=3268487204

    Many of the core ideas and implementation approaches used here — including
    zombie state management, custom animation chains (attack, idle, walk, run),
    IsoZombie-based human NPC construction, pathfinding heuristics, and
    per-tick AI update loops — were influenced by that mod.
]]

---@class ChaosNPC
---@field pathfindUpdateMs integer
---@field zombie? IsoZombie -- Inner IsoZombie object of this NPC
---@field moveTargetCharacter? IsoGameCharacter
---@field moveTargetLocation? IsoGridSquare
---@field lastCachedTargetMoveLocation? IsoGridSquare
---@field enemy? IsoGameCharacter -- Current character target to attack
---@field npcGroup integer -- ID of NPC group (see ChaosNPCGroupID)
---@field moving boolean -- If NPC is moving in this frame
---@field isAttacking boolean -- If NPC is currently attacking enemy or object
---@field attackAnimTimeMs integer -- Current ms time since start of attack
---@field attackAnimWindowMs integer -- Time in ms to apply hit event
---@field attackHitPassed boolean -- If hit event has been applied
---@field attackAnimName string -- Current attack animation name
---@field walkType string -- Current walk type (Walk or Run)
---@field weaponItemCached? HandWeapon -- Current weapon item being used
---@field attackObjectTarget? IsoObject -- If NPC is attacking any IsoObject
---@field attackObjectType? string -- Type of the object being attacked
---@field hasBlockingCollisionToTargetThisFrame boolean -- If NPC has a blocking collision to target this frame
---@field unstuckPassed boolean -- If NPC has passed unstuck logic once
---@field lastTimeUpdateMs integer -- Last time NPC was updated
---@field findEnemyTimeoutMs integer -- Timeout in ms to find new enemy
---@field lastZombieThatAttackedNPC? IsoZombie -- Last zombie that attacked this NPC
---@field spawnTimeMs integer -- Time in ms when NPC was spawned
---@field debugLastTimePathfindMs integer -- DEBUG: Last time pathfind was updated
---@field attackLastTimeMs integer -- Last time NPC attacked
---@field tags table<string, boolean> -- Set of tags on this NPC
---@field endurance number -- Current endurance level (0-100)
---@field canRun boolean -- Whether NPC is currently allowed to start running
ChaosNPC = ChaosNPC or {}
ChaosNPC.__index = ChaosNPC


CHAOS_NPC_MAX_PATHFIND_UPDATE_MS = 1000
CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS = 2500
CHAOS_NPC_MOD_DATA_KEY = "is_npc"
CHAOS_NPC_MOD_DATA_KEY_2 = "ChaosNPC"
local TIME_TO_ENABLE_AI_AFTER_SPAWN_MS = 3500
local ATTACK_TIMEOUT_MS = 2500

local ENDURANCE_MAX = 100.0
local ENDURANCE_RUN_DRAIN_PER_SEC = 20.0
local ENDURANCE_ATTACK_DRAIN_HANDS = 7.0
local ENDURANCE_ATTACK_DRAIN_ONE_HAND = 10.0
local ENDURANCE_ATTACK_DRAIN_TWO_HAND = 20.0
local ENDURANCE_IDLE_REGEN_PER_SEC = 15.0
local ENDURANCE_WALK_REGEN_PER_SEC = 5.0
local ENDURANCE_ATTACK_REGEN_PER_SEC = 10.0
local ENDURANCE_RUN_THRESHOLD = 20.0

CHAOS_NPC_ATTACK_ANIMS = {
    HANDS = {
        "ZombieAttackPunch01",
        "ZombieAttackPunch02",
        "ZombieAttackPunch03",
        "ZombieAttackPunch04",
        "ZombieAttackPunch05",
        "ZombieAttackPunch06",
    },
    ONE_HAND = {
        -- "ZombieAttackMelee1_01",
        "ZombieAttackMelee1_02",
        "ZombieAttackMelee1_03",
        -- "ZombieAttackMelee1_04",
        -- "ZombieAttackMelee1_05",
        "ZombieAttackMelee1_06",
        -- "ZombieAttackMelee1_07",
        "ZombieAttackMelee1_08",
    },
    TWO_HAND = {
        "ZombieAttackMelee2_01",
        "ZombieAttackMelee2_02",
        "ZombieAttackMelee2_03",
        "ZombieAttackMelee2_04",
    },
}

local CHAOS_NPC_ATTACK_GROUND = {
    HANDS = "ZombieAttack_Ground_Hands",
    ONE_HAND = "ZombieAttack_Ground_Melee1",
    TWO_HAND = "ZombieAttack_Ground_Melee2",
}

---@type table<integer, string>
local WindowVehiclePartBySeat = {
    "WindowFrontLeft",
    "WindowFrontRight",
    "WindowMiddleLeft",
    "WindowMiddleRight",
    "WindowRearLeft",
    "WindowRearRight",
}

function ChaosNPC:new(zombie)
    ---@type ChaosNPC
    local o = setmetatable({}, self)
    o.pathfindUpdateMs = 0
    o.zombie = zombie
    o.moveTargetCharacter = nil
    o.moveTargetLocation = nil
    o.lastCachedTargetMoveLocation = nil
    o.enemy = nil
    o.npcGroup = ChaosNPCGroupID.RAIDERS
    o.moving = false
    o.isAttacking = false
    o.attackAnimTimeMs = 0
    o.attackAnimWindowMs = 0
    o.attackHitPassed = false
    o.walkType = "Walk"
    o.weaponItemCached = nil
    o.hasBlockingCollisionToTargetThisFrame = false
    o.unstuckPassed = false
    o.lastTimeUpdateMs = 0
    o.findEnemyTimeoutMs = 0
    o.lastZombieThatAttackedNPC = nil
    o.spawnTimeMs = getTimestampMs()
    o.debugLastTimePathfindMs = 0
    o.attackLastTimeMs = 0
    o.tags = {}
    o.endurance = ENDURANCE_MAX
    o.canRun = true
    return o
end

function ChaosNPC:initializeHuman()
    if not self.zombie then
        return
    end

    local zombie = self.zombie

    ChaosZombie.HumanizeZombie(zombie)

    zombie:setWalkType(self.walkType)
    zombie:setNoTeeth(true)

    -- Set variable for animation system
    zombie:setVariable("ChaosNPC", true)
    self.weaponItemCached = instanceItem("Base.BareHands")

    local md = zombie:getModData()
    if md then
        md[CHAOS_NPC_MOD_DATA_KEY] = true
        md[CHAOS_NPC_MOD_DATA_KEY_2] = self
    end

    self.spawnTimeMs = ChaosMod.lastTimeTickMs
    self.zombie:setVariable("Chaos2HandsWeapon", false)
    self.zombie:setVariable("ChaosSneak", false)

    self:DisableZombieVoice()

    ChaosNPCUtils.npcList:add(self)
end

---@param deltaMs integer
function ChaosNPC:UpdateEndurance(deltaMs)
    local deltaSeconds = deltaMs / 1000.0
    local isRunning = self.moving and self.walkType == "Run"

    if isRunning then
        self.endurance = math.max(0, self.endurance - ENDURANCE_RUN_DRAIN_PER_SEC * deltaSeconds)
    elseif self.isAttacking then
        local pastHalfway = self.attackAnimWindowMs > 0 and
            self.attackAnimTimeMs >= self.attackAnimWindowMs * 0.5
        if pastHalfway then
            self.endurance = math.min(ENDURANCE_MAX, self.endurance + ENDURANCE_ATTACK_REGEN_PER_SEC * deltaSeconds)
        end
    elseif not self.moving then
        self.endurance = math.min(ENDURANCE_MAX, self.endurance + ENDURANCE_IDLE_REGEN_PER_SEC * deltaSeconds)
    elseif self.walkType == "Walk" then
        self.endurance = math.min(ENDURANCE_MAX, self.endurance + ENDURANCE_WALK_REGEN_PER_SEC * deltaSeconds)
    end

    if isRunning then
        -- allow continuing to run until endurance hits 0
        if self.endurance <= 0 then
            self.canRun = false
        end
    else
        -- not running: only re-enable run when endurance recovers past threshold
        self.canRun = self.endurance >= ENDURANCE_RUN_THRESHOLD
    end

    if not self.canRun and isRunning then
        self.walkType = "Walk"
    end
end

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

    -- If NPC can start finding new enemy this frame
    local canFindNewEnemyThisFrame = self.findEnemyTimeoutMs >= CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS and
        not self.isAttacking

    if self.moving == false then
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

    -- Set state to turnalerted for a few seconds after spawn for unstucking npc
    self:UnstuckNPC()

    -- Do not enable AI for a few seconds after spawn
    if timestampMs - self.spawnTimeMs < TIME_TO_ENABLE_AI_AFTER_SPAWN_MS then
        -- return
    end

    --- ================================================
    --- Handle Action State
    --- ================================================
    local actionState = zombie:getActionStateName()

    -- If near player and trying to use native attack, stop it
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

    -- Clear native game zombie target for attacking
    ChaosNPC.SetTargetInner(zombie, nil)

    if self.enemy then
        if self.enemy:isDead() then
            ---@diagnostic disable-next-line: invert-if
            if self.enemy == self.moveTargetCharacter then
                self.moveTargetCharacter = nil
                self:StopMoving(true, "enemy_dead")
            end
            self.enemy = nil
        end
    end

    local shouldFindNewEnemy = false
    -- Flag update for finding new enemy.
    if self.enemy == nil then
        -- print("[ChaosNPC] No enemy, finding new enemy")
        shouldFindNewEnemy = true
    end

    if self.isAttacking then
        shouldFindNewEnemy = false
    end

    -- If has no enemy target, try to find new enemy
    if shouldFindNewEnemy and canFindNewEnemyThisFrame then
        self:UpdateNextEnemyTarget()
    end

    -- Force move target character to enemy, unless follow priority overrides
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
        self.moveTargetCharacter = self.enemy
    end

    -- If has no target character to follow, find new move target
    if not self.moveTargetCharacter and not self.isAttacking then
        self:UpdateNextTargetMoveCharacter()
        shouldUpdatePathfind = true
    end

    -- Wander behavior for item_robber tagged NPCs
    if not self.moveTargetCharacter and not self.isAttacking and self:HasTag("item_robber") then
        if not self.moving then
            self:UpdateWanderTarget()
        end
    end

    local isNearby = false

    local dist = 0.0
    if self.moveTargetCharacter then
        dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), self.moveTargetCharacter:getX(),
            self.moveTargetCharacter:getY())
    end

    if self.moveTargetCharacter then
        -- Default max distance to followers (not attackers)
        local maxDist = 3.0
        if self.enemy ~= nil then
            maxDist = self:GetMaxDistanceAttack() + 0.1
        end

        if dist <= maxDist then
            local z1 = zombie:getZ()
            local z2 = self.moveTargetCharacter:getZ()

            if z1 ~= z2 then
                isNearby = false
            else
                isNearby = true
            end
        end

        if isNearby then
            self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        end

        if isNearby and not self.isAttacking and zombie:getVehicle() == nil then
            self:StopMoving(true, "nearby")
            self.moving = false

            -- If zombie is not on ground, face the target character
            if actionState ~= "onground" then
                pcall(function()
                    zombie:faceThisObject(self.moveTargetCharacter)
                end)
            end

            -- If zombie is not attacking and has enemy target, start attacking
            if not self.isAttacking and self.enemy then
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

    --- Update pathfinding every N ms
    if shouldUpdatePathfind and self.moveTargetCharacter and not isNearby then
        self:MoveToCharacter(self.moveTargetCharacter)
    end

    local moveResultCache = -1

    -- Check if we have finished moving
    if self.moving then
        local moveResult = zombie:getPathFindBehavior2():update()
        if moveResult == BehaviorResult.Working then
            moveResultCache = 0
        elseif moveResult == BehaviorResult.Succeeded then
            moveResultCache = 1
        elseif moveResult == BehaviorResult.Failed then
            moveResultCache = 2
        end

        if moveResult == BehaviorResult.Succeeded or moveResult == BehaviorResult.Failed then
            if isNearby then
                self:StopMoving(true, "nearby_finished")
            elseif not self.moveTargetCharacter and self:HasTag("item_robber") then
                self:StopMoving(true, "wander_reached")
            end
            self.pathfindUpdateMs = CHAOS_NPC_MAX_PATHFIND_UPDATE_MS
        elseif moveResult == BehaviorResult.Working then
            self.moving = true
        end
    end

    -- Handle collision such as doors, windows, etc.
    if (actionState == "walktoward" or actionState == "idle" or actionState == "pathfinding" or actionState == "run") then
        self:HandleCollisions()
    end

    self:UpdateSneakAnim()
    self:VehiclesTick()
    self:UpdateStalker(deltaMs)

    --- Debug
    local uselessString = zombie:isUseless() and "1" or "0"
    local movingString = self.moving and "1" or "0"
    local enemyString = self.enemy and "1" or "0"
    local moveTargetCharacterString = self.moveTargetCharacter and "1" or "0"
    local upddatePathfindingString = shouldUpdatePathfind and "1" or "0"
    local isNearbyString = isNearby and "1" or "0"
    local bumpTypeString = zombie:getVariableString("BumpType")
    local isAttackingString = self.isAttacking and "1" or "0"
    -- local shouldMovingString = zombie:getPathFindBehavior2():shouldBeMoving() and "1" or "0"
    -- local isMovingPahtfindingString = zombie:getPathFindBehavior2():isMovingUsingPathFind() and "1" or "0"
    -- local pathLength = zombie:getPathFindBehavior2():getPathLength()
    local movSpeed = zombie:getMovementSpeed()
    local attackDist = self:GetMaxDistanceAttack()
    local lastTimePathfindMs = (ChaosMod.lastTimeTickMs - self.debugLastTimePathfindMs) / 1000
    local twohandWeapon = zombie:getVariableBoolean("Chaos2HandsWeapon") and "1" or "0"

    -- local debugString = string.format(
    --     "[action] %s [useless] %s [moving] %s [enemy] %s [moveTargetCharacter] %s [updatePath] %s [moveResult] %s [nearby] %s [dist] %.2f [bump] %s [attacking] %s [attackTime] %d [walk] %s [path] %d [attDist] %.2f [pathTime] %.2f s [twohand] %s",
    --     actionState,
    --     uselessString,
    --     movingString,
    --     enemyString, moveTargetCharacterString, upddatePathfindingString, moveResultCache, isNearbyString, dist,
    --     bumpTypeString, isAttackingString, self.attackAnimTimeMs, self.walkType, self.pathfindUpdateMs,
    --     attackDist, lastTimePathfindMs, twohandWeapon)
    -- local debugString = string.format("%.2f", self.endurance)
    -- zombie:addLineChatElement(debugString, 1.0, 1.0, 1.0)
end

---@param character IsoGameCharacter
function ChaosNPC:MoveToCharacter(character)
    if not self.zombie then return end
    local zombie = self.zombie
    if not character then
        return
    end

    if zombie:getVehicle() then
        return
    end

    local actionState = zombie:getActionStateName()

    local allowActionState = actionState == "walktoward" or actionState == "idle" or actionState == "pathfinding" or
        actionState == "run"

    if not allowActionState then
        self:StopMoving(true, "not_allowed_action_state")
        return
    end

    local oldCharacter = self.moveTargetCharacter

    local sameCharacter = oldCharacter == character

    self.moveTargetCharacter = character
    self.moveTargetLocation = character:getSquare()

    if not self.zombie then
        return
    end

    local zombie = self.zombie

    local x = self.moveTargetLocation:getX()
    local y = self.moveTargetLocation:getY()
    local z = self.moveTargetLocation:getZ()

    if sameCharacter == false then
        zombie:getPathFindBehavior2():reset()
        zombie:getPathFindBehavior2():cancel()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
    end

    local characterVehicle = self.moveTargetCharacter:getVehicle()
    if characterVehicle then
        zombie:getPathFindBehavior2():pathToLocation(x, y, z)
    else
        zombie:getPathFindBehavior2():pathToCharacter(self.moveTargetCharacter)
    end

    -- zombie:getPathFindBehavior2():pathToLocation(x, y, z)
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

---@param npc IsoZombie
---@param target? IsoGameCharacter
function ChaosNPC.SetTargetInner(npc, target)
    if not npc then return end
    if not target then return end

    npc:setTarget(target)
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

local STALKER_TELEPORT_COOLDOWN_MS = 2000
local STALKER_MIN_DIST = 10.0
local STALKER_MAX_DIST = 30.0
local STALKER_TELEPORT_MIN_RADIUS = 15
local STALKER_TELEPORT_MAX_RADIUS = 20

function ChaosNPC:UpdateStalker(deltaMs)
    if not self:HasTag("stalker") then return end
    local zombie = self.zombie
    if not zombie then return end
    local player = getPlayer()
    if not player then return end

    local actionState = zombie:getActionStateName()
    if actionState ~= "onground" then
        pcall(function()
            zombie:faceThisObject(player)
        end)
    end

    self.stalkerTeleportCooldownMs = (self.stalkerTeleportCooldownMs or 0) + deltaMs
    if self.stalkerTeleportCooldownMs < STALKER_TELEPORT_COOLDOWN_MS then return end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    if dist < STALKER_MIN_DIST or dist > STALKER_MAX_DIST then
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(
            player, 0, STALKER_TELEPORT_MIN_RADIUS, STALKER_TELEPORT_MAX_RADIUS, 20, true, false, false)
        if square then
            zombie:teleportTo(square:getX(), square:getY(), square:getZ())
            self:StopMoving(true, "stalker_teleport")
            self.stalkerTeleportCooldownMs = 0
        end
    end
end

---@param tag string
function ChaosNPC:AddTag(tag)
    self.tags[tag] = true
end

---@param tag string
---@return boolean
function ChaosNPC:HasTag(tag)
    return self.tags[tag] == true
end

---@return IsoGameCharacter?
function ChaosNPC:GetFollowTarget()
    local rel = ChaosNPCRelations.GetRelation(self.npcGroup, ChaosNPCGroupID.PLAYER)
    if rel == ChaosNPCRelationType.FOLLOW then
        return getPlayer()
    end
    return nil
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

function ChaosNPC:Destroy()
    if not self.zombie then return end
    local md = self.zombie:getModData()
    if md then
        md[CHAOS_NPC_MOD_DATA_KEY] = nil
        md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
    end
    self.zombie:removeFromWorld()
    self.zombie:removeFromSquare()
    self.zombie = nil
    self.enemy = nil
    self.moveTargetCharacter = nil
    self.moveTargetLocation = nil
    self.moving = false
    self.isAttacking = false
    local index = ChaosNPCUtils.npcList:indexOf(self)
    if index ~= -1 then
        ChaosNPCUtils.npcList:remove(index)
    end
end

-- Find new enemy target to attack
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

    -- Fallback: if this group attacks players, always target the player regardless of distance
    local playerRel = ChaosNPCRelations.GetRelation(self.npcGroup, ChaosNPCGroupID.PLAYER)
    if playerRel == ChaosNPCRelationType.ATTACK then
        local player = getPlayer()
        if player then
            self:SetAsTargetEnemy(player)
        end
    end
end

--- Make new IsoGameCharacter as enemy target
---@param newEnemy IsoGameCharacter
function ChaosNPC:SetAsTargetEnemy(newEnemy)
    if not newEnemy then return end
    if not self.zombie then return end

    self.enemy = newEnemy
    self:MoveToCharacter(newEnemy)
end

-- Find new target character to follow
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

-- Clear params when zombie NPC is dead
function ChaosNPC:OnZombieDead()
    if self.zombie then
        local md = self.zombie:getModData()
        if md then
            md[CHAOS_NPC_MOD_DATA_KEY] = nil
            md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
        end
    end

    local isFollowGroup = self.npcGroup == ChaosNPCGroupID.COMPANIONS or
        self.npcGroup == ChaosNPCGroupID.FOLLOWERS
    if isFollowGroup and self.zombie then
        self.zombie:playSound("deathcrash")
        local player = getPlayer()
        if player then
            local name = ChaosNicknames.ensureZombieNicknameAndColor(self.zombie)
            if name then
                player:Say(string.format(ChaosLocalization.GetString("misc", "npc_died"), name))
            end
        end
    end

    self.zombie = nil
    self.enemy = nil
    self.moveTargetCharacter = nil
    self.moveTargetLocation = nil
    self.lastCachedTargetMoveLocation = nil
    self.moving = false
    self.isAttacking = false
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = 0
    self.endurance = ENDURANCE_MAX
    self.canRun = true

    local index = ChaosNPCUtils.npcList:indexOf(self)
    if index ~= -1 then
        ChaosNPCUtils.npcList:remove(index)
    end
end

function ChaosNPC:StartAttackEnemy()
    if not self.zombie then return end
    if not self.enemy then return end
    local zombie = self.zombie

    if zombie:getVehicle() then
        return
    end

    local actionName = zombie:getActionStateName()
    if actionName ~= "idle" then
        return
    end

    ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
    local isFacing = zombie:isFacingObject(self.enemy, 0.8)
    if not isFacing then
        return
    end

    local lineTrace = self:LineTraceToEnemy()
    local resultString = tostring(lineTrace)

    -- Something is in the way, don't attack
    if lineTrace ~= "Clear" then
        self.hasBlockingCollisionToTargetThisFrame = true
        self.isAttacking = false
        return
    end

    -- Can't see enemy, don't attack
    if zombie:CanSee(self.enemy) == false then
        self.isAttacking = false
        return
    end

    -- Don't attack player if they are knocked down
    if not self.enemy:isZombie() then
        ---@diagnostic disable-next-line: invert-if
        if ChaosPlayer.IsPlayerKnockedDown(self.enemy) then
            return
        end
    end

    self.attackObjectTarget = nil
    self.attackObjectType = nil

    if self:CanAttackTimeout() == false then
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
    local zombie = self.zombie
    if not self.attackObjectTarget then return end
    if not self.attackObjectType then return end

    if self.attackObjectType == "window" then
        ---@type IsoWindow
        local window = self.attackObjectTarget
        if not window then return end
        if not window:isWindow() then return end
        if window:isBarricaded() then return end

        if not window:IsOpen() and not window:isSmashed() then
            -- Break this window
            window:smashWindow()
        end
    elseif self.attackObjectType == "door" then
        ---@type IsoDoor | IsoThumpable
        local door = self.attackObjectTarget

        if not self.weaponItemCached then return end

        local health = door:getHealth()
        local damage = 10
        local oldHealth = health
        health = health - damage
        if health <= 0 then
            health = 0
        end

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
    local zombie = self.zombie
    if not self.enemy then return end

    if self.enemy:isDead() then
        return
    end

    if not zombie:isFacingObject(self.enemy, 0.5) then
        return
    end

    local z1 = zombie:getZ()
    local z2 = self.enemy:getZ()

    if z1 ~= z2 then
        return
    end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), self.enemy:getX(), self.enemy:getY())

    if dist > self:GetMaxDistanceAttack() + 0.2 then
        return
    end

    -- Don't attack player if they are knocked down
    if not self.enemy:isZombie() then
        ---@diagnostic disable-next-line: invert-if
        if ChaosPlayer.IsPlayerKnockedDown(self.enemy) then
            return
        end
    end


    if zombie:CanSee(self.enemy) == false then
        return
    end
    self:OnAttackEnemyHit()
end

function ChaosNPC:OnAttackEnemyHit()
    if not self.zombie then return end
    local zombie = self.zombie
    if not self.enemy then return end
    if zombie:isDead() then return end
    if self.enemy:isDead() then return end

    local enemy = self.enemy

    if not self.weaponItemCached then
        return
    end

    local fakeAttacker = getFakeAttacker()

    enemy:setAttackedBy(zombie)
    local minDamage = self.weaponItemCached:getMinDamage()
    local maxDamage = self.weaponItemCached:getMaxDamage()
    if minDamage <= 0 then
        minDamage = 2
    end
    if maxDamage <= 0 then
        maxDamage = 4
    end


    local damage = ZombRandFloat(minDamage, maxDamage)
    if damage <= 0.1 then
        damage = 0.1
    end

    local enemyVehicle = enemy:getVehicle()
    local canAttackInVehicle = false

    if enemyVehicle then
        canAttackInVehicle = true
        local square = enemy:getSquare()
        local seat = enemyVehicle:getSeat(enemy) + 1
        ---@type string
        local windowPartName = WindowVehiclePartBySeat[seat]
        enemy:playSound("HitVehicleWindowWithWeapon")
        local vehiclePart = enemyVehicle:getPartById(windowPartName)
        if vehiclePart and vehiclePart:getInventoryItem() then
            canAttackInVehicle = true
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

    if enemyVehicle and canAttackInVehicle == false then
        return
    end

    if enemy:isZombie() then
        ---@type table<integer, string>
        local hitReactions = {
            "HeadLeft",
            "HeadRight",
            "HeadTop"
        }
        local randomIndex = math.floor(ZombRand(#hitReactions))
        local newHitReaction = hitReactions[1 + randomIndex]
        fakeAttacker:setVariable("ZombieHitReaction", newHitReaction)
        enemy:Hit(self.weaponItemCached, fakeAttacker, damage, false, 1.0)
        enemy:playSound(self.weaponItemCached:getZombieHitSound())

        if ChaosNPCUtils.IsNPC(enemy) then
            local otherNPC = ChaosNPCUtils.GetNPCFromZombie(enemy)
            if otherNPC then
                otherNPC:OnZombieDamagedNPC(zombie)
            end
        end
    else
        -- If attacked player
        local splatCount = self.weaponItemCached:getSplatNumber()
        for i = 0, splatCount do
            enemy:splatBlood(2, 0.25)
        end

        enemy:playBloodSplatterSound()

        local bodyDamage = enemy:getBodyDamage()
        local health = bodyDamage:getOverallBodyHealth()

        enemy:setAttackedBy(zombie)

        if ZombRand(0, 20 + 1) == 0 and not enemy:isKnockedDown() then
            enemy:setKnockedDown(true)
        else
            local hitStunLastTimeMs = ChaosPlayer.hitStunLastTimeMs or 0
            local minTimeoutMs = 1500

            local timeNowMs = ChaosMod.lastTimeTickMs
            local timeSinceLastHitMs = timeNowMs - hitStunLastTimeMs

            -- if timeSinceLastHitMs > minTimeoutMs then
            local isBehind = zombie:isBehind(enemy)
            enemy:setHitFromBehind(isBehind)
            enemy:setVariable("hitpvp", true)
            enemy:setHitReaction("")
            enemy:setHitReaction("HitReaction")
            enemy:reportEvent("washitpvp")
            ChaosPlayer.hitStunLastTimeMs = timeNowMs
            -- end
        end

        bodyDamage:ReduceGeneralHealth(damage)
        ChaosPlayer.SetRandomBodyDamageByMeleeWeapon(enemy, damage, self.weaponItemCached)
    end
end

---@return number
function ChaosNPC:GetMaxDistanceAttack()
    if not self.zombie then return 0 end
    local zombie = self.zombie

    if not self.weaponItemCached then
        return 0.0
    end

    return self.weaponItemCached:getMaxRange() - 0.1
end

---@return string
function ChaosNPC:LineTraceToEnemy()
    if not self.zombie then return "" end
    local zombie = self.zombie
    if not self.enemy then return "" end

    local square1 = zombie:getSquare()
    local square2 = self.enemy:getSquare()
    local x1 = square1:getX()
    local y1 = square1:getY()
    local z1 = square1:getZ()
    local x2 = square2:getX()
    local y2 = square2:getY()
    local z2 = square2:getZ()
    local lineTrace = LosUtil.lineClear(square1:getCell(), x1, y1, z1, x2, y2, z2, false)
    local resultString = tostring(lineTrace)
    return resultString
end

function ChaosNPC:HandleCollisions()
    if not self.zombie then return end
    local zombie = self.zombie

    if self.isAttacking then return end

    local hasCollisionThisFrame = zombie:isCollidedThisFrame()
    -- print("[ChaosNPC] Has collision this frame: " .. tostring(hasCollisionThisFrame))

    local finalCollisionResult = true

    if hasCollisionThisFrame == false then
        if self.hasBlockingCollisionToTargetThisFrame == false then
            finalCollisionResult = false
        end
    end

    if finalCollisionResult == false then
        -- print("[ChaosNPC] No collision detected: hasBlockingCollisionToTargetThisFrame: " ..
        -- tostring(self.hasBlockingCollisionToTargetThisFrame))
        return
    end

    local x1 = zombie:getX()
    local y1 = zombie:getY()
    local z1 = zombie:getZ()

    local forwardX = zombie:getForwardDirectionX()
    local forwardY = zombie:getForwardDirectionY()

    ---@type table<integer, {x: integer, y: integer, z: integer}>
    local squaresToCheck = {}
    table.insert(squaresToCheck, {
        x = math.floor(x1),
        y = math.floor(y1),
        z = z1,
    })
    table.insert(squaresToCheck, {
        x = math.floor(x1 + forwardX),
        y = math.floor(y1 + forwardY),
        z = z1,
    })

    local cell = getCell()
    for _, coord in ipairs(squaresToCheck) do
        local square = cell:getGridSquare(coord.x, coord.y, coord.z)
        if square then
            local objectsList = square:getObjects()

            for i = 0, objectsList:size() - 1 do
                local object = objectsList:get(i)
                if object then
                    local result = self:HandleCollisionWithObject(zombie, object)
                    if result then
                        return
                    end
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
    local objectProperties = object:getProperties()
    local objectType = object:getType()

    if not objectProperties then return false end

    local isHostileToPlayer = ChaosNPCRelations.CanNPCDestroyObjects(self)

    --- == Handle Window Collision ==
    if instanceof(object, "IsoWindow") then
        ---@type IsoWindow
        local window = object

        if zombie:isFacingObject(window, 0.8) == false then
            zombie:faceThisObject(window)
            return true
        end

        if window:isBarricaded() then
            return false
        end

        if not window:IsOpen() and not window:isSmashed() then
            if isHostileToPlayer then
                -- Destroy this window
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

        if door.isDoor and door:isDoor() == false then
            return false
        end

        if door:IsOpen() then
            return false
        end

        if door:isBarricaded() then
            return false
        end

        local canOpenDoor = true
        local zombieSquare = zombie:getSquare()
        local isLocked = door:isLocked() or door:isLockedByKey()

        -- Hostile enemies can only open when they are not outside
        -- Firendly enemies can open inside. Outside for friendly only if not locked
        if zombieSquare:isOutside() then
            ---@diagnostic disable-next-line: invert-if
            if isHostileToPlayer then
                canOpenDoor = false
            elseif isLocked then
                canOpenDoor = false
            end
        end

        if canOpenDoor then
            -- Open this door
            door:ToggleDoor(zombie)
            return true
        elseif isHostileToPlayer then
            local isGarageDoor = IsoDoor.getGarageDoorIndex(door) ~= -1
            if isGarageDoor then
                return false
            end

            -- Break this door
            self:StartAttackingObject(door, "door")
            return true
        end
    elseif object:isHoppable() then
        if zombie:isFacingObject(object, 0.8) == false then
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

---@param object IsoObject
---@param type string
function ChaosNPC:StartAttackingObject(object, type)
    if not object then return end
    if not self.zombie then return end

    if self:CanAttackTimeout() == false then
        return
    end

    self.attackObjectTarget = object
    self.attackObjectType = type

    if type == "window" then
        self:StartAttackAnimation()
    elseif type == "door" then
        self:StartAttackAnimation()
    end
end

---@return integer
function ChaosNPC:GetNextAttackWindowMs()
    return 500
end

---@return number
function ChaosNPC:GetAttackEnduranceCost()
    if not self.weaponItemCached then
        return ENDURANCE_ATTACK_DRAIN_HANDS
    end
    if self.weaponItemCached:getFullType() == "Base.BareHands" then
        return ENDURANCE_ATTACK_DRAIN_HANDS
    end
    local weaponType = WeaponType.getWeaponType(self.weaponItemCached)
    if weaponType == WeaponType.TWO_HANDED or weaponType == WeaponType.HEAVY then
        return ENDURANCE_ATTACK_DRAIN_TWO_HAND
    elseif weaponType == WeaponType.ONE_HANDED then
        return ENDURANCE_ATTACK_DRAIN_ONE_HAND
    end
    return ENDURANCE_ATTACK_DRAIN_HANDS
end

function ChaosNPC:StartAttackAnimation()
    if not self.zombie then return end
    local zombie = self.zombie

    if self.endurance < self:GetAttackEnduranceCost() then
        return
    end

    self.isAttacking = true
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = self:GetNextAttackWindowMs()

    if not self.weaponItemCached then
        return
    end

    ---@type table<integer, string>
    local animsTable = CHAOS_NPC_ATTACK_ANIMS.HANDS
    local groundAttackName = CHAOS_NPC_ATTACK_GROUND.HANDS
    local attackEnduranceDrain = ENDURANCE_ATTACK_DRAIN_HANDS

    local weaponType = WeaponType.getWeaponType(self.weaponItemCached)

    if self.weaponItemCached:getFullType() == "Base.BareHands" then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.HANDS
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.HANDS
        attackEnduranceDrain = ENDURANCE_ATTACK_DRAIN_HANDS
    elseif weaponType == WeaponType.ONE_HANDED then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.ONE_HAND
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.ONE_HAND
        attackEnduranceDrain = ENDURANCE_ATTACK_DRAIN_ONE_HAND
    elseif weaponType == WeaponType.TWO_HANDED or weaponType == WeaponType.HEAVY then
        animsTable = CHAOS_NPC_ATTACK_ANIMS.TWO_HAND
        groundAttackName = CHAOS_NPC_ATTACK_GROUND.TWO_HAND
        attackEnduranceDrain = ENDURANCE_ATTACK_DRAIN_TWO_HAND
    end

    self.endurance = math.max(0, self.endurance - attackEnduranceDrain)


    local randomIndex = ZombRand(#animsTable)
    ---@diagnostic disable-next-line: undefined-field
    self.attackAnimName = animsTable[1 + randomIndex]
    local isAttackingEnemy = self.enemy ~= nil and self.attackObjectTarget == nil


    self.attackLastTimeMs = ChaosMod.lastTimeTickMs
    if isAttackingEnemy and self.enemy ~= nil then
        if ChaosNPCUtils.IsNPC(self.enemy) == false then
            self.attackLastTimeMs = 0
        end
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

    ---@type string?
    local weaponSound = nil

    if self.weaponItemCached then
        if self.weaponItemCached and self.weaponItemCached.getSwingSound then
            weaponSound = self.weaponItemCached:getSwingSound()
        end
    end

    if weaponSound then
        zombie:playSound(weaponSound)
    end

    self.pathfindUpdateMs = math.floor(CHAOS_NPC_MAX_PATHFIND_UPDATE_MS * 0.75)
    self.attackHitPassed = false
end

function ChaosNPC:UnstuckNPC()
    if not self.zombie then return end
    local zombie = self.zombie
    if self.unstuckPassed then return end
    if self.isAttacking then return end

    if not self.moving then return end

    local actionState = zombie:getActionStateName()
    if actionState ~= "idle" then return end

    if zombie:isBumped() then
        -- zombie:setBumpDone(true)
        -- self.unstuckPassed = true
    end

    -- zombie:setBumpType("left")

    local player = getPlayer()
    if player then
        local playerSquare = player:getSquare()
        if playerSquare then
            self:StopMoving(true, "unstuck")
            local playerX = playerSquare:getX()
            local playerY = playerSquare:getY()
            zombie:setTurnAlertedValues(playerX, playerY)
        end
    end

    self.unstuckPassed = true
end

function ChaosNPC:DisableZombieVoice()
    if not self.zombie then return end
    local zombie = self.zombie

    local isFemale = zombie:isFemale()
    local prefix = isFemale and "VoiceFemale" or "VoiceMale"

    local descriptor = zombie:getDescriptor()
    if not descriptor then return end

    descriptor:setVoicePrefix(prefix)
    zombie:setHurtSound(prefix .. "Hurt")
end

---@param weaponFullType string
function ChaosNPC:SetWeapon(weaponFullType)
    if not weaponFullType then return end
    if not self.zombie then return end

    local inventory = self.zombie:getInventory()
    if not inventory then return end

    local oldWeapon = self.weaponItemCached
    if oldWeapon and oldWeapon:getFullType() ~= "Base.BareHands" then
        inventory:Remove(oldWeapon)
        oldWeapon:removeFromWorld()
    end

    local newWeapon = instanceItem(weaponFullType)
    if newWeapon then
        self.weaponItemCached = newWeapon
        self.zombie:setPrimaryHandItem(newWeapon)
        local isTwoHands = newWeapon:isTwoHandWeapon()
        self.zombie:setVariable("Chaos2HandsWeapon", isTwoHands)
    end
end

---@param otherZombie IsoZombie
---@return boolean
function ChaosNPC:IsEnemyToNPC(otherZombie)
    if not otherZombie then return false end
    if not self.zombie then return false end

    local zombie = self.zombie

    if otherZombie == zombie then
        return false
    end

    if zombie:isDead() then return false end
    if otherZombie:isDead() then return false end

    local otherGroup = ChaosNPCRelations.GetNPCGroupByCharacter(otherZombie)
    local rel = ChaosNPCRelations.GetRelation(self.npcGroup, otherGroup)
    return rel == ChaosNPCRelationType.ATTACK
end

---@param otherZombie IsoZombie
function ChaosNPC:OnZombieDamagedNPC(otherZombie)
    if not otherZombie then return end
    if not self.zombie then return end

    local zombie = self.zombie
    if zombie:isDead() then return end
    if otherZombie:isDead() then return end

    if otherZombie == zombie then return end
    if otherZombie == self.enemy then return end
    if self.isAttacking then return end

    local attackerGroup = ChaosNPCRelations.GetNPCGroupByCharacter(otherZombie)
    local rel = ChaosNPCRelations.GetRelation(self.npcGroup, attackerGroup)
    if rel == ChaosNPCRelationType.IGNORE then return end

    if rel == ChaosNPCRelationType.ATTACK then
        self:SetAsTargetEnemy(otherZombie)
    end
end

---@param message string
function ChaosNPC:SayDebug(message)
    if not self.zombie then return end
    local zombie = self.zombie
    if not zombie:isAlive() then return end

    -- zombie:setHaloNote(message, 300)
    zombie:SayDebug(2, message)
end

---@return boolean
function ChaosNPC:CanAttackTimeout()
    if not self.zombie then return false end
    if not self.attackLastTimeMs then return false end
    local timeNowMs = ChaosMod.lastTimeTickMs
    local timeSinceLastAttackMs = timeNowMs - self.attackLastTimeMs
    if timeSinceLastAttackMs > ATTACK_TIMEOUT_MS then
        return true
    end
    return false
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
        -- Exit current vehicle
        zombieVehicle:exit(self.zombie)
        self.zombie:setGodMod(false, true)
        return
    end

    if zombieVehicle == nil and moveTargetVehicle ~= nil and self.enemy == nil then
        -- Enter new vehicle
        local seat = ChaosVehicle.FindFreeSeat(moveTargetVehicle, true)
        if seat < 1 then
            return
        end

        local x1, y1 = moveTargetVehicle:getSquare():getX(), moveTargetVehicle:getSquare():getY()
        local x2, y2 = self.zombie:getX(), self.zombie:getY()

        if ChaosUtils.isInRange(x1, y1, x2, y2, 4.0) == false then
            return
        end


        moveTargetVehicle:enter(seat, self.zombie)
        self.zombie:setGodMod(true, true)
        return
    end

    if zombieVehicle ~= nil and self.enemy ~= nil then
        -- Exit vehicle
        zombieVehicle:exit(self.zombie)
        self.zombie:setGodMod(false, true)
        return
    end
end
