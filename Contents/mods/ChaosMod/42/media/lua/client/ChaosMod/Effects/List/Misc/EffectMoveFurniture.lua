---@class EffectMoveFurniture : ChaosEffectBase
EffectMoveFurniture = ChaosEffectBase:derive("EffectMoveFurniture", "move_furniture")

local RANGE = 50
local Z_RANGE = 3
local MOVE_RADIUS = 10
local MAX_TRIES = 20

---@param obj IsoObject
---@param z integer
---@return IsoGridSquare | nil
local function findRandomSquare(obj, z)
    local sq = obj:getSquare()
    if not sq then return nil end
    local x = sq:getX()
    local y = sq:getY()
    local cell = getCell()
    for _ = 1, MAX_TRIES do
        local dx = ZombRand(-MOVE_RADIUS, MOVE_RADIUS + 1)
        local dy = ZombRand(-MOVE_RADIUS, MOVE_RADIUS + 1)
        local newSq = cell:getGridSquare(x + dx, y + dy, z)
        if newSq and newSq:isSolidFloor() and newSq:isFree(false) then
            return newSq
        end
    end
    return nil
end

function EffectMoveFurniture:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectMoveFurniture] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ---@type table<integer, {obj: IsoObject, z: integer}>
    local furniture = {}

    for dx = -RANGE, RANGE do
        for dy = -RANGE, RANGE do
            for dz = -Z_RANGE, Z_RANGE do
                local sq = cell:getGridSquare(px + dx, py + dy, pz + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and not obj:hasSpriteGrid() and ChaosProps.GetFurnitureType(obj) ~= nil then
                            table.insert(furniture, { obj = obj, z = sq:getZ() })
                        end
                    end
                end
            end
        end
    end

    local moved = 0
    for _, entry in ipairs(furniture) do
        local obj = entry.obj
        local newSq = findRandomSquare(obj, entry.z)
        if newSq then
            obj:removeFromWorld()
            obj:removeFromSquare()
            obj:setSquare(newSq)
            newSq:AddTileObject(obj)
            moved = moved + 1
        end
    end

    print("[EffectMoveFurniture] Moved " .. tostring(moved) .. " furniture objects")
end
