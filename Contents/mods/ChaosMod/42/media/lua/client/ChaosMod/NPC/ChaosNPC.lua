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

require "ChaosMod/NPC/ChaosNPCConstants"
require "ChaosMod/NPC/ChaosNPCFirearms"

---@class ChaosNPC
---@field pathfindUpdateMs integer
---@field zombie? IsoZombie
---@field moveTargetCharacter? IsoGameCharacter
---@field moveTargetLocation? IsoGridSquare
---@field lastCachedTargetMoveLocation? IsoGridSquare
---@field enemy? IsoGameCharacter
---@field npcGroup integer
---@field moving boolean
---@field isAttacking boolean
---@field attackAnimTimeMs integer
---@field attackAnimWindowMs integer
---@field attackHitPassed boolean
---@field attackAnimName? string
---@field walkType string
---@field weaponItemCached? HandWeapon
---@field attackObjectTarget? IsoObject
---@field attackObjectType? string
---@field hasBlockingCollisionToTargetThisFrame boolean
---@field unstuckPassed boolean
---@field lastTimeUpdateMs integer
---@field findEnemyTimeoutMs integer
---@field lastZombieThatAttackedNPC? IsoZombie
---@field lastZombieBiteTimeMs? integer
---@field lastNpcDebugLogMs integer
---@field spawnTimeMs integer
---@field debugLastTimePathfindMs integer
---@field attackLastTimeMs integer
---@field findGroundWeaponTimeoutMs integer
---@field actionType? string
---@field actionWorldObjectTarget? IsoWorldInventoryObject
---@field actionWorldObjectClaimToken? string
---@field tags table<string, boolean>
---@field relationOverridesByGroup table<integer, ChaosNPCRelationTypeValue>
---@field relationOverridesByCharacterId table<integer, ChaosNPCRelationTypeValue>
---@field DamageMultiplier number
---@field CanAddWounds boolean
---@field endurance number
---@field canRun boolean
---@field stalkerTeleportCooldownMs? integer
---@field stalkerInteractionCount integer
---@field effectMoveTargetLocation? IsoGridSquare
---@field healthGroup? integer
---@field maxHealth number
---@field chanceToDropWeaponOnDeath number
---@field lastNeedHealLineMs integer
---@field lastGiftItemTimeMs integer
---@field canGiftItems boolean
---@field panicCheckTimeoutMs integer
---@field panicStartTimeMs integer
---@field panicTargetSquare? IsoGridSquare
---@field panicCooldownEndMs integer
---@field firearmType? string
---@field maxAmmo integer
---@field currentAmmo integer
---@field firearmAccuracyZombies number
---@field firearmAccuracyPlayers number
---@field firearmStateType? string
---@field firearmStateEndMs integer
---@field _lastFirearmDiagMs integer
ChaosNPC = ChaosNPC or {}
ChaosNPC.__index = ChaosNPC
ChaosNPC._nextGroundWeaponClaimId = ChaosNPC._nextGroundWeaponClaimId or 0

require "ChaosMod/NPC/ChaosNPCLifecycle"
require "ChaosMod/NPC/ChaosNPCMovementSystem"
require "ChaosMod/NPC/ChaosNPCCombatSystem"
require "ChaosMod/NPC/ChaosNPCCollisionSystem"
require "ChaosMod/NPC/ChaosNPCBehaviorSystem"
require "ChaosMod/NPC/ChaosNPCAISystem"

---@param zombie IsoZombie
---@param nickname string|nil
function ChaosNPC:new(zombie, nickname)
    ---@type ChaosNPC
    local o = setmetatable({}, self)
    o.pathfindUpdateMs = 0
    o.zombie = zombie
    if nickname and type(nickname) == "string" and nickname ~= "" then
        ChaosZombie.SetSpecificNickname(zombie, nickname)
    end
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
    o.attackAnimName = nil
    o.walkType = "Walk"
    o.weaponItemCached = nil
    o.attackObjectTarget = nil
    o.attackObjectType = nil
    o.hasBlockingCollisionToTargetThisFrame = false
    o.unstuckPassed = false
    o.lastTimeUpdateMs = 0
    o.findEnemyTimeoutMs = 0
    o.lastZombieThatAttackedNPC = nil
    o.lastZombieBiteTimeMs = nil
    o.lastNpcDebugLogMs = 0
    o.spawnTimeMs = getTimestampMs()
    o.debugLastTimePathfindMs = 0
    o.attackLastTimeMs = 0
    o.findGroundWeaponTimeoutMs = 0
    o.actionType = nil
    o.actionWorldObjectTarget = nil
    o.actionWorldObjectClaimToken = nil
    o.tags = {}
    o.relationOverridesByGroup = {}
    o.relationOverridesByCharacterId = {}
    o.DamageMultiplier = 1.0
    o.CanAddWounds = true
    o.endurance = CHAOS_NPC_ENDURANCE_MAX
    o.canRun = true
    o.stalkerTeleportCooldownMs = 0
    o.stalkerInteractionCount = 0
    o.effectMoveTargetLocation = nil
    o.healthGroup = CHAOS_NPC_HEALTH_GROUP.DEFAULT
    o.maxHealth = 1.0
    o.chanceToDropWeaponOnDeath = 0.4
    o.lastNeedHealLineMs = 0
    o.lastGiftItemTimeMs = getTimestampMs()
    o.canGiftItems = true
    o.panicCheckTimeoutMs = 0
    o.panicStartTimeMs = 0
    o.panicTargetSquare = nil
    o.panicCooldownEndMs = 0
    o.firearmType = nil
    o.maxAmmo = 0
    o.currentAmmo = 0
    o.firearmAccuracyZombies = 1.0
    o.firearmAccuracyPlayers = 0.25
    o.firearmStateType = nil
    o.firearmStateEndMs = 0
    ChaosNPC._nextGroundWeaponClaimId = ChaosNPC._nextGroundWeaponClaimId + 1
    o.actionWorldObjectClaimToken = "npc_ground_weapon_claim_" .. tostring(ChaosNPC._nextGroundWeaponClaimId)
    return o
end

---@param npc IsoZombie
---@param target? IsoGameCharacter
function ChaosNPC.SetTargetInner(npc, target)
    if not npc then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    npc:setTarget(target)
end

---@param tag string
function ChaosNPC:AddTag(tag)
    self.tags[tag] = true
end

---@param tag string
function ChaosNPC:RemoveTag(tag)
    self.tags[tag] = nil
end

---@param tag string
---@return boolean
function ChaosNPC:HasTag(tag)
    return self.tags[tag] == true
end

---@return IsoGameCharacter?
function ChaosNPC:GetFollowTarget()
    local player = getPlayer()
    if player then
        local rel = ChaosNPCRelations.GetRelationForNPC(self, player)
        if rel == ChaosNPCRelationType.FOLLOW then
            return player
        end
    end
    return nil
end

---@param message string
function ChaosNPC:SayDebug(message)
    if not self.zombie then return end
    local zombie = self.zombie
    if not zombie:isAlive() then return end

    zombie:SayDebug(2, message)
end

---@param message string
---@param say? boolean
function ChaosNPC:DebugLog(message, say)
    if not self.zombie then return end

    local zombie = self.zombie
    local enemyId = "nil"
    if self.enemy then
        enemyId = tostring(self.enemy:getID())
    end

    print(string.format(
        "[ChaosNPC][%s] %s | state=%s current=%s bump=%s hit=%s stagger=%s moving=%s attacking=%s enemy=%s health=%.2f",
        tostring(zombie:getID()),
        tostring(message),
        tostring(zombie:getActionStateName()),
        tostring(zombie:getCurrentStateName()),
        tostring(zombie:getBumpType()),
        tostring(zombie:getHitReaction()),
        tostring(zombie:isStaggerBack()),
        tostring(self.moving),
        tostring(self.isAttacking),
        enemyId,
        zombie:getHealth()
    ))

    if say then
        self:SayDebug(tostring(message))
    end
end

---@param message string
---@param intervalMs? integer
function ChaosNPC:DebugLogThrottled(message, intervalMs)
    intervalMs = intervalMs or 1000
    local now = ChaosMod and ChaosMod.lastTimeTickMs or getTimestampMs()
    if now - (self.lastNpcDebugLogMs or 0) < intervalMs then return end
    self.lastNpcDebugLogMs = now
    self:DebugLog(message, false)
end

---@param reason string
function ChaosNPC:CancelAttackState(reason)
    if self.isAttacking then
        self:DebugLog("cancel_attack: " .. tostring(reason), false)
    end

    self.isAttacking = false
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = 0
    self.attackAnimName = nil
    self.attackHitPassed = false
    self.attackObjectTarget = nil
    self.attackObjectType = nil

    if self.firearmStateType then
        self.firearmStateType = nil
        self.firearmStateEndMs = 0
        ChaosNPCFirearms.ForceExitBumpedState(self)
    end
end

return ChaosNPC
