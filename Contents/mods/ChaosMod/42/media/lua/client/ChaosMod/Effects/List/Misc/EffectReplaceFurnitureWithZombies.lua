---@class EffectReplaceFurnitureWithZombies : ChaosEffectBase
EffectReplaceFurnitureWithZombies = ChaosEffectBase:derive("EffectReplaceFurnitureWithZombies",
    "replace_furniture_with_zombies")

local REPLACE_CHANCE = 30

function EffectReplaceFurnitureWithZombies:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceFurnitureWithZombies] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ---@type table<integer, {obj: IsoObject, sq: IsoGridSquare}>
    local furniture = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if obj and ChaosProps.GetFurnitureType(obj) ~= nil then
                    table.insert(furniture, { obj = obj, sq = sq })
                end
            end)
        end
    end, 3, 15, false, false, true, pz - 1, pz + 1)

    local count = 0
    for _, entry in ipairs(furniture) do
        if ChaosUtils.RandInteger(100) < REPLACE_CHANCE then
            local sq = entry.sq
            entry.obj:removeFromWorld()
            entry.obj:removeFromSquare()
            local zombies = ChaosZombie.SpawnZombieAt(sq:getX(), sq:getY(), sq:getZ(), 1, "Tourist")
            if zombies and zombies:size() > 0 then
                local zombie = zombies:getFirst()
                if zombie then
                    zombie:dressInRandomOutfit()
                    zombie:setTurnAlertedValues(px, py)
                end
            end
            count = count + 1
        end
    end

    print("[EffectReplaceFurnitureWithZombies] Replaced " .. tostring(count) .. " furniture objects with zombies")
end
