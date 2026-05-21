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
    npc:initializeHuman(false)
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
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
    local companionsCount = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq or companionsCount >= MAX_COMPANIONS then
            return companionsCount >= MAX_COMPANIONS
        end

        local objects = sq:getStaticMovingObjects()
        if not objects then
            return false
        end

        for i = 0, objects:size() - 1 do
            if companionsCount >= MAX_COMPANIONS then
                return true
            end

            local obj = objects:get(i)
            if instanceof(obj, "IsoDeadBody") then
                ---@cast obj IsoDeadBody
                local deadBody = obj
                if deadBody.reanimate then
                    local zombie = deadBody:reanimate()
                    if MakeZombieCompanion(zombie) then
                        companionsCount = companionsCount + 1
                    end
                end
            end
        end

        return companionsCount >= MAX_COMPANIONS
    end, 0, SEARCH_RADIUS, false, false, true, minZ, maxZ)

    while companionsCount < MAX_COMPANIONS do
        local spawnSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
        if not spawnSquare then break end

        local spawnedZombies = ChaosZombie.SpawnZombieAt(spawnSquare:getX(), spawnSquare:getY(), spawnSquare:getZ(),
            1, "Tourist", 50)
        if not spawnedZombies or spawnedZombies:isEmpty() then break end

        local zombie = spawnedZombies:getFirst()
        zombie:dressInRandomOutfit()
        if not MakeZombieCompanion(zombie) then break end
        companionsCount = companionsCount + 1
    end

    ChaosPlayer.SayLineByColor(player, string.format("Raised %d zombies as companions", companionsCount),
        ChaosPlayerChatColors.green)
end
