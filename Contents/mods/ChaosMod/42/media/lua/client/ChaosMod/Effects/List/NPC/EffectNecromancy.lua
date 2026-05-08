---@class EffectNecromancy : ChaosEffectBase
EffectNecromancy = ChaosEffectBase:derive("EffectNecromancy", "necromancy")

local MAX_COMPANIONS = 2
local SEARCH_RADIUS = 40

---@param zombie IsoGameCharacter?
---@return boolean
local function MakeZombieCompanion(zombie)
    if not zombie or not instanceof(zombie, "IsoZombie") then
        return false
    end

    ---@cast zombie IsoZombie
    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS
    return true
end

function EffectNecromancy:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local minZ = z - 1
    local maxZ = z + 2
    local reanimatedCount = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq or reanimatedCount >= MAX_COMPANIONS then
            return reanimatedCount >= MAX_COMPANIONS
        end

        local objects = sq:getStaticMovingObjects()
        if not objects then
            return false
        end

        for i = 0, objects:size() - 1 do
            if reanimatedCount >= MAX_COMPANIONS then
                return true
            end

            local obj = objects:get(i)
            if instanceof(obj, "IsoDeadBody") then
                ---@cast obj IsoDeadBody
                local deadBody = obj
                if deadBody.reanimate then
                    local zombie = deadBody:reanimate()
                    if MakeZombieCompanion(zombie) then
                        reanimatedCount = reanimatedCount + 1
                    end
                end
            end
        end

        return reanimatedCount >= MAX_COMPANIONS
    end, 0, SEARCH_RADIUS, false, false, true, minZ, maxZ)

    ChaosPlayer.SayLineByColor(player, string.format("Reanimated %d zombies as companions", reanimatedCount),
        ChaosPlayerChatColors.green)
end
