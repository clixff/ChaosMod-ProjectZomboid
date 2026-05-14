---@class EffectSpawnExplosiveSpiffos : ChaosEffectBase
EffectSpawnExplosiveSpiffos = ChaosEffectBase:derive("EffectSpawnExplosiveSpiffos", "spawn_explosive_spiffos")

local ITEM_ID = "Base.SpiffoBig"
local EXPLOSION_RADIUS = 2
local MIN_DISTANCE = 1
local MAX_DISTANCE = 15
local MIN_SPAWN_COUNT = 80
local MAX_TRIES = 50
local MAX_DURATION = 8000


---@param data { spawnedSquares: IsoGridSquare[], spawnedItems: InventoryItem[] }
local function ExplodeSpiffos(data)
    local spawnedSquares = data.spawnedSquares or {}
    local spawnedItems = data.spawnedItems or {}

    for i = 1, #spawnedItems do
        local sq = spawnedSquares[i]
        local item = spawnedItems[i]
        if sq and item then
            ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(obj)
                if obj and obj:getItem() == item then
                    InventoryItem.RemoveFromContainer(item)
                    pcall(function() item:Remove() end)
                end
            end)
        end
    end

    for i = 1, #spawnedSquares do
        ChaosUtils.TriggerExplosionAt(spawnedSquares[i], EXPLOSION_RADIUS)
    end
    print("[EffectSpawnExplosiveSpiffos] " .. tostring(#spawnedSquares) .. " spiffos exploded")
end

---@param deltaMs integer
---@param data { elapsedMs: integer }
local function SpawnExplosiveSpiffosTick(deltaMs, data)
    local bar = UIManager.getProgressBar(0)
    data.elapsedMs = data.elapsedMs + deltaMs
    local progress = data.elapsedMs / MAX_DURATION
    bar:setValue(progress)
end

function EffectSpawnExplosiveSpiffos:OnStart()
    ChaosEffectBase:OnStart()

    local spawnedSquares = {}
    local spawnedItems = {}

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local pz = square:getZ()

    local tries = 0
    local spawnedCount = 0

    while spawnedCount < MIN_SPAWN_COUNT and tries < MAX_TRIES do
        local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, pz, MIN_DISTANCE, MAX_DISTANCE, 50, true, true, false)
        if sq then
            local item = instanceItem(ITEM_ID)
            if item then
                sq:AddWorldInventoryItem(item, 0.5, 0.5, 0)
                spawnedSquares[#spawnedSquares + 1] = sq
                spawnedItems[#spawnedItems + 1] = item
                spawnedCount = spawnedCount + 1
                tries = 0
            end
        end
        tries = tries + 1
    end

    print("[EffectSpawnExplosiveSpiffos] Spawned " .. tostring(#spawnedSquares) .. " spiffos")

    ChaosSpecialAction.AddNewAction(
        { spawnedSquares = spawnedSquares, spawnedItems = spawnedItems, elapsedMs = 0 },
        MAX_DURATION, SpawnExplosiveSpiffosTick, ExplodeSpiffos, nil)
end

function EffectSpawnExplosiveSpiffos:OnEnd()
    ChaosEffectBase:OnEnd()
end
