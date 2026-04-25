---@alias ChaosNPCRelationTypeValue string

ChaosNPCRelationType           = ChaosNPCRelationType or {}
ChaosNPCRelationType.ATTACK    = "ATTACK"
ChaosNPCRelationType.FOLLOW    = "FOLLOW"
ChaosNPCRelationType.IGNORE    = "IGNORE"
ChaosNPCRelationType.FRIEND    = "FRIEND"

ChaosNPCGroupID                = ChaosNPCGroupID or {}
ChaosNPCGroupID.RAIDERS        = 1
ChaosNPCGroupID.COMPANIONS     = 2
ChaosNPCGroupID.FOLLOWERS      = 3
-- Pseudo-groups: used as relation targets only, no NPC has these as npcGroup
ChaosNPCGroupID.PLAYER         = 100
ChaosNPCGroupID.ZOMBIES        = 101

CHAOS_NPC_FOLLOW_PRIORITY_DIST = 8.0

---@class ChaosNPCGroupDef
---@field id integer
---@field name string
---@field defaultRelation ChaosNPCRelationTypeValue
---@field canDestroyObjects boolean

---@class ChaosNPCRelations
ChaosNPCRelations              = ChaosNPCRelations or {}

---@type table<integer, ChaosNPCGroupDef>
local groups                   = {}
---@type table<integer, table<integer, ChaosNPCRelationTypeValue>>
local relations                = {}
local nextGroupId              = 10

---@param name string
---@param defaultRelation ChaosNPCRelationTypeValue
---@param canDestroyObjects boolean
---@param reservedId? integer
---@return integer
function ChaosNPCRelations.CreateGroup(name, defaultRelation, canDestroyObjects, reservedId)
    local id = reservedId or nextGroupId
    if not reservedId then
        nextGroupId = nextGroupId + 1
    end
    groups[id] = {
        id = id,
        name = name,
        defaultRelation = defaultRelation,
        canDestroyObjects = canDestroyObjects,
    }
    relations[id] = relations[id] or {}
    return id
end

---@param fromId integer
---@param toId integer
---@param relationType ChaosNPCRelationTypeValue
function ChaosNPCRelations.SetRelation(fromId, toId, relationType)
    relations[fromId] = relations[fromId] or {}
    relations[fromId][toId] = relationType
end

---@param fromId integer
---@param toId integer
---@return ChaosNPCRelationTypeValue
function ChaosNPCRelations.GetRelation(fromId, toId)
    local groupRelations = relations[fromId]
    if groupRelations then
        local explicit = groupRelations[toId]
        if explicit then
            return explicit
        end
    end
    local group = groups[fromId]
    if group then
        return group.defaultRelation
    end
    return ChaosNPCRelationType.IGNORE
end

---@param character IsoGameCharacter
---@return integer
function ChaosNPCRelations.GetNPCGroupByCharacter(character)
    if not character then return ChaosNPCGroupID.ZOMBIES end
    if instanceof(character, "IsoPlayer") then
        return ChaosNPCGroupID.PLAYER
    end
    if instanceof(character, "IsoZombie") then
        ---@cast character IsoZombie
        if ChaosNPCUtils.IsNPC(character) then
            local npc = ChaosNPCUtils.GetNPCFromZombie(character)
            if npc then return npc.npcGroup end
        end
    end
    return ChaosNPCGroupID.ZOMBIES
end

---@param npc ChaosNPC
---@return boolean
function ChaosNPCRelations.CanNPCDestroyObjects(npc)
    if not npc then return false end
    local group = groups[npc.npcGroup]
    return group and group.canDestroyObjects or false
end

-- Initialize pre-created groups
ChaosNPCRelations.CreateGroup("RAIDERS", ChaosNPCRelationType.ATTACK, true, ChaosNPCGroupID.RAIDERS)
ChaosNPCRelations.CreateGroup("COMPANIONS", ChaosNPCRelationType.IGNORE, false, ChaosNPCGroupID.COMPANIONS)
ChaosNPCRelations.CreateGroup("FOLLOWERS", ChaosNPCRelationType.IGNORE, false, ChaosNPCGroupID.FOLLOWERS)

-- Relations for RAIDERS group
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.RAIDERS, ChaosNPCGroupID.RAIDERS, ChaosNPCRelationType.FRIEND)

-- Relations for COMPANIONS group
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.COMPANIONS, ChaosNPCGroupID.COMPANIONS, ChaosNPCRelationType.FRIEND)
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.COMPANIONS, ChaosNPCGroupID.PLAYER, ChaosNPCRelationType.FOLLOW)
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.COMPANIONS, ChaosNPCGroupID.ZOMBIES, ChaosNPCRelationType.ATTACK)
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.COMPANIONS, ChaosNPCGroupID.RAIDERS, ChaosNPCRelationType.ATTACK)

-- Relations for FOLLOWERS group
ChaosNPCRelations.SetRelation(ChaosNPCGroupID.FOLLOWERS, ChaosNPCGroupID.PLAYER, ChaosNPCRelationType.FOLLOW)

-- ROBBER group: ignores everyone, just wanders
ChaosNPCGroupID.ROBBER = 4
ChaosNPCRelations.CreateGroup("ROBBER", ChaosNPCRelationType.IGNORE, false, ChaosNPCGroupID.ROBBER)

-- STALKER group: ignores everyone, only faces and teleports around the player
ChaosNPCGroupID.STALKER = 5
ChaosNPCRelations.CreateGroup("STALKER", ChaosNPCRelationType.IGNORE, false, ChaosNPCGroupID.STALKER)
