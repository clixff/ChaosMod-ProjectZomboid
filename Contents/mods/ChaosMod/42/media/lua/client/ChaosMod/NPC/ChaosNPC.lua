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
ChaosNPC = ChaosNPC or {}
ChaosNPC.__index = ChaosNPC
ChaosNPC._nextGroundWeaponClaimId = ChaosNPC._nextGroundWeaponClaimId or 0

require "ChaosMod/NPC/ChaosNPCLifecycle"
require "ChaosMod/NPC/ChaosNPCMovementSystem"
require "ChaosMod/NPC/ChaosNPCCombatSystem"
require "ChaosMod/NPC/ChaosNPCCollisionSystem"
require "ChaosMod/NPC/ChaosNPCBehaviorSystem"
require "ChaosMod/NPC/ChaosNPCAISystem"

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
    ChaosNPC._nextGroundWeaponClaimId = ChaosNPC._nextGroundWeaponClaimId + 1
    o.actionWorldObjectClaimToken = "npc_ground_weapon_claim_" .. tostring(ChaosNPC._nextGroundWeaponClaimId)
    return o
end

---@param npc IsoZombie
---@param target? IsoGameCharacter
function ChaosNPC.SetTargetInner(npc, target)
    if not npc then return end
    if not target then return end

    npc:setTarget(target)
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

return ChaosNPC
