---@class EffectSpawnChefCompanion : ChaosEffectBase
EffectSpawnChefCompanion = ChaosEffectBase:derive("EffectSpawnChefCompanion", "spawn_chef_companion")

local FOOD_GIVE_DISTANCE = 4.0
local FOOD_COOLDOWN_MS = 180000
local FOOD_CHECK_INTERVAL_MS = 1000

---@param data { zombie: IsoZombie, sinceLastFoodMs: integer }
local function ChefFoodTick(deltaMs, data)
    data.sinceLastFoodMs = data.sinceLastFoodMs + deltaMs
end

---@param data { zombie: IsoZombie, sinceLastFoodMs: integer }
---@return boolean?
local function ChefFoodEnd(data)
    local zombie = data.zombie
    if not zombie or not zombie:isAlive() then return true end

    local player = getPlayer()
    if not player then return true end

    if data.sinceLastFoodMs < FOOD_COOLDOWN_MS then return false end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    if dist > FOOD_GIVE_DISTANCE then return false end

    local inventory = player:getInventory()
    if not inventory then return false end

    local foodId = ChaosItems.GetRandomFoodItemId()
    if not foodId then return false end

    local item = inventory:AddItem(foodId)
    if not item then return false end

    ChaosPlayer.SayLineNewItem(player, item)

    data.sinceLastFoodMs = 0
    return false
end

function EffectSpawnChefCompanion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnChefCompanion] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        0
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.WEAK)
    npc.canGiftItems = false

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Hat_ChefHat" },
        { type = "Base.Jacket_Chef" },
        { type = "Base.Trousers_Chef" },
        { type = "Base.Shoes_Black" },
    })

    ChaosSpecialAction.AddNewAction(
        { zombie = zombie, sinceLastFoodMs = FOOD_COOLDOWN_MS },
        FOOD_CHECK_INTERVAL_MS,
        ChefFoodTick,
        ChefFoodEnd,
        nil,
        true
    )
end

function EffectSpawnChefCompanion:OnEnd()
    ChaosEffectBase:OnEnd()
end
