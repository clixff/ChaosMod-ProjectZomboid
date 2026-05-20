---@class EffectSpawnHomerSimpson : ChaosEffectBase
EffectSpawnHomerSimpson = ChaosEffectBase:derive("EffectSpawnHomerSimpson", "spawn_homer_simpson")

local DONUT_ITEM_ID = "Base.DoughnutFrosted"
local DONUT_GIVE_DISTANCE = 4.0
local DONUT_COOLDOWN_MS = 8000
local DONUT_MAX_COUNT = 3
local DONUT_CHECK_INTERVAL_MS = 1000

---@param data { zombie: IsoZombie, donutsGiven: integer, sinceLastDonutMs: integer }
local function HomerDonutTick(deltaMs, data)
    data.sinceLastDonutMs = data.sinceLastDonutMs + deltaMs
end

---@param data { zombie: IsoZombie, donutsGiven: integer, sinceLastDonutMs: integer }
---@return boolean?
local function HomerDonutEnd(data)
    local zombie = data.zombie
    if not zombie or not zombie:isAlive() then return true end

    local player = getPlayer()
    if not player then return true end

    if data.sinceLastDonutMs < DONUT_COOLDOWN_MS then return false end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    if dist > DONUT_GIVE_DISTANCE then return false end

    local inventory = player:getInventory()
    if not inventory then return false end

    local item = inventory:AddItem(DONUT_ITEM_ID)
    if not item then return false end

    ChaosPlayer.SayLineNewItem(player, item)

    data.donutsGiven = data.donutsGiven + 1
    data.sinceLastDonutMs = 0

    if data.donutsGiven >= DONUT_MAX_COUNT then
        return true
    end
    return false
end

function EffectSpawnHomerSimpson:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnHomerSimpson] OnStart" .. tostring(self.effectId))
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

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS




    --- Hair / beard
    local humanVisual = zombie:getHumanVisual()
    humanVisual:setHairModel("")
    ---@diagnostic disable-next-line: param-type-mismatch
    humanVisual:setBeardModel("")
    -- local beardColor = ImmutableColor.new(60 / 255, 45 / 255, 30 / 255)
    -- humanVisual:setBeardColor(beardColor)
    -- humanVisual:setNaturalBeardColor(beardColor)
    --- Skin texture
    zombie:getHumanVisual():setSkinTextureName("ChaosHomerMaleBody01")

    --- Remove default clothes
    zombie:getItemVisuals():clear()
    zombie:clearWornItems()

    ChaosZombie.AddZombieClothes(zombie, "Base.Tshirt_WhiteTINT", { r = 1, g = 1, b = 1 }, nil, false, true)
    ChaosZombie.AddZombieClothes(zombie, "Base.Trousers_Scrubs", nil, 0, true)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoes_Black", nil, nil, true)

    zombie:resetModelNextFrame()

    local donutsToSpawn = 5

    for i = 1, donutsToSpawn do
        local newItem = instanceItem(DONUT_ITEM_ID)
        zombie:addItemToSpawnAtDeath(newItem)
    end


    ChaosSpecialAction.AddNewAction(
        { zombie = zombie, donutsGiven = 0, sinceLastDonutMs = DONUT_COOLDOWN_MS },
        DONUT_CHECK_INTERVAL_MS,
        HomerDonutTick,
        HomerDonutEnd,
        nil,
        true
    )
end

function EffectSpawnHomerSimpson:OnEnd()
    ChaosEffectBase:OnEnd()
end
