---@class EffectNPCBattleRoyale : ChaosEffectBase
EffectNPCBattleRoyale = ChaosEffectBase:derive("EffectNPCBattleRoyale", "npc_battle_royale")

local NPC_COUNT = 15

---@type string[]
local WEAPONS = {
    "Base.BaseballBat",
    "Base.Crowbar",
    "Base.PipeWrench",
    "Base.GolfClub",
    "Base.Axe",
    "Base.HandAxe",
    "Base.HuntingKnife",
    "Base.Sledgehammer",
    "Base.Pan",
    "Base.Machete",
    "Base.Plank",
    "Base.Shovel",
    "Base.Nightstick",
    "Base.Wrench",
    "Base.RollingPin",
}

function EffectNPCBattleRoyale:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ---@type ChaosNPC[]
    local spawnedNpcs = {}

    for i = 1, NPC_COUNT do
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 8, 50, true, true, false)
        if square then
            local newZombies = ChaosZombie.SpawnZombieAt(
                square:getX(), square:getY(), square:getZ(), 1, "Tourist", 50)
            local zombie = newZombies:getFirst()
            if zombie then
                local npc = ChaosNPC:new(zombie)
                zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.PEDESTRIAN
                local weapon = WEAPONS[ChaosUtils.RandArrayIndex(WEAPONS)]
                if weapon then
                    npc:SetWeapon(weapon)
                end
                table.insert(spawnedNpcs, npc)
            end
        end
    end

    for i = 1, #spawnedNpcs do
        local npc = spawnedNpcs[i]
        if npc and npc.zombie then
            for j = 1, #spawnedNpcs do
                if i ~= j then
                    local other = spawnedNpcs[j]
                    if other and other.zombie then
                        ChaosNPCRelations.SetNPCRelationToCharacterId(
                            npc,
                            other.zombie:getID(),
                            ChaosNPCRelationType.ATTACK
                        )
                    end
                end
            end

            npc.enemy = nil
            npc.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
        end
    end
end
