---@class EffectSpawnTrees : ChaosEffectBase
---@field spawnedTrees IsoTree[]
---@field playerWasInVehicle boolean
EffectSpawnTrees = ChaosEffectBase:derive("EffectSpawnTrees", "spawn_trees")

local MIN_RADIUS = 3
local MAX_RADIUS = 30
local TREE_SPRITE = "e_americanlinden_1_3"
local TREE_SPAWN_CHANCE = 40

function EffectSpawnTrees:OnStart()
    ChaosEffectBase:OnStart()

    self.spawnedTrees = {}
    self.playerWasInVehicle = false

    local player = getPlayer()
    if not player then return end

    if player:getVehicle() then
        self.playerWasInVehicle = true
        ChaosUtils.EFFECT_FLYING_CARS_ENABLED = true
    end

    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    if not cell then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local spawned = 0

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            if ZombRand(100) < TREE_SPAWN_CHANCE then
                local tree = IsoTree.new(sq, TREE_SPRITE)
                tree:addAttachedAnimSpriteByName("e_americanlinden_1_11")
                if tree then
                    tree:setSquare(sq)
                    tree:addToWorld()
                    sq:AddTileObject(tree)
                    table.insert(self.spawnedTrees, tree)
                    spawned = spawned + 1
                end
            end
        end
    end, MIN_RADIUS, MAX_RADIUS, true, false, true, pz, pz)

    print("[EffectSpawnTrees] Spawned " .. tostring(spawned) .. " trees")
end

---@param deltaMs integer
function EffectSpawnTrees:OnTick(deltaMs)
    if self.playerWasInVehicle then
        local player = getPlayer()
        if player and player:getVehicle() == nil then
            self.playerWasInVehicle = false
            ChaosUtils.EFFECT_FLYING_CARS_ENABLED = false
        end
    end
end

function EffectSpawnTrees:OnEnd()
    ChaosEffectBase:OnEnd()

    ChaosUtils.EFFECT_FLYING_CARS_ENABLED = false
    self.playerWasInVehicle = false

    if self.spawnedTrees then
        for _, tree in ipairs(self.spawnedTrees) do
            if tree then
                local sq = tree:getSquare()
                if sq then
                    sq:RemoveTileObject(tree)
                end
                pcall(function() tree:removeFromWorld() end)
                pcall(function() tree:removeFromSquare() end)
            end
        end
        self.spawnedTrees = {}
    end
end
