---@class EffectSpawnExplosiveSpiffos : ChaosEffectBase
---@field spawnedSquares IsoGridSquare[]
---@field spawnedItems InventoryItem[]
EffectSpawnExplosiveSpiffos = ChaosEffectBase:derive("EffectSpawnExplosiveSpiffos", "spawn_explosive_spiffos")

local ITEM_ID = "Base.SpiffoBig"
local EXPLOSION_RADIUS = 2
local MIN_DISTANCE = 1
local MAX_DISTANCE = 15
local MIN_SPAWN_COUNT = 80
local MAX_TRIES = 50

function EffectSpawnExplosiveSpiffos:OnStart()
    ChaosEffectBase:OnStart()

    self.spawnedSquares = {}
    self.spawnedItems = {}

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    local tries = 0
    local spawnedCount = 0

    while spawnedCount < MIN_SPAWN_COUNT and tries < MAX_TRIES do
        local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, pz, MIN_DISTANCE, MAX_DISTANCE, 50, true, true, false)
        if sq then
            local item = instanceItem(ITEM_ID)
            if item then
                sq:AddWorldInventoryItem(item, 0.5, 0.5, 0)
                self.spawnedSquares[#self.spawnedSquares + 1] = sq
                self.spawnedItems[#self.spawnedItems + 1] = item
                spawnedCount = spawnedCount + 1
                tries = 0
            end
        end
        tries = tries + 1
    end


    print("[EffectSpawnExplosiveSpiffos] Spawned " .. tostring(#self.spawnedSquares) .. " spiffos")
end

function EffectSpawnExplosiveSpiffos:OnEnd()
    ChaosEffectBase:OnEnd()

    for i = 1, #self.spawnedItems do
        local sq = self.spawnedSquares[i]
        local item = self.spawnedItems[i]
        if sq and item then
            ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(obj)
                if obj and obj:getItem() == item then
                    InventoryItem.RemoveFromContainer(item)
                    pcall(function() item:Remove() end)
                end
            end)
        end
    end

    for i = 1, #self.spawnedSquares do
        ChaosUtils.TriggerExplosionAt(self.spawnedSquares[i], EXPLOSION_RADIUS)
    end
    print("[EffectSpawnExplosiveSpiffos] " .. tostring(#self.spawnedSquares) .. " spiffos exploded")
end
