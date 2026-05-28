---@class EffectSpawnTreasureInWorld : ChaosEffectBase
EffectSpawnTreasureInWorld = ChaosEffectBase:derive("EffectSpawnTreasureInWorld", "spawn_treasure_in_world")


local MIN_RADIUS = 60
local MAX_RADIUS = 90
local ITEM_COUNT = 15
local GIFTBOX_ITEM_ID = "Base.Present_ExtraLarge"
local MAP_SYMBOL_ID = "X"


---@param x integer
---@param y integer
---@return IsoGridSquare?
local function findRandomTargetSquare(x, y)
    ---@type table<integer, IsoGridSquare>
    local candidates = {}

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        candidates[#candidates + 1] = sq
    end, MIN_RADIUS, MAX_RADIUS, true, true, true, 0, 0)

    if #candidates == 0 then return nil end
    return candidates[ChaosUtils.RandArrayIndex(candidates)]
end

---@param worldX integer
---@param worldY integer
local function addClosedMapMark(worldX, worldY)
    local mapItem = MapItem.getSingleton()
    if not mapItem then return end

    ---@diagnostic disable-next-line:param-type-mismatch
    local ui = UIWorldMap.new(nil)
    if not ui then return end

    local mapAPI = ui:getAPIv3()
    if not mapAPI then return end

    mapAPI:setMapItem(mapItem)

    local symbolsAPI = mapAPI:getSymbolsAPIv2()
    if not symbolsAPI then return end

    local symbol = symbolsAPI:addTexture(MAP_SYMBOL_ID, worldX, worldY)
    if not symbol then return end

    symbol:setRGBA(1.0, 0.0, 0.0, 1.0)
    symbol:setAnchor(0.5, 0.5)
    symbol:setScale(0.666)
    symbol:setUserDefined(true)

    MapItem.SaveWorldMap()
end

function EffectSpawnTreasureInWorld:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local targetSquare = findRandomTargetSquare(playerSquare:getX(), playerSquare:getY())
    if not targetSquare then return end

    ---@diagnostic disable-next-line:assign-type-mismatch
    ---@type IsoWorldInventoryObject
    local worldItem = targetSquare:AddWorldInventoryItem(GIFTBOX_ITEM_ID, 0.5, 0.5, 0.0)
    if not worldItem then return end

    ---@diagnostic disable-next-line:undefined-field
    local container = worldItem:getInventory()
    if not container then
        ChaosUtils.RemoveWorldObject(worldItem)
        return
    end

    for _ = 1, ITEM_COUNT do
        local itemId = GetRandomLootboxItem(3)
        if itemId then
            local item = container:AddItem(itemId)
            if item then
                ChaosItems.SetFullAmmoIfWeapon(item)
            end
        end
    end

    addClosedMapMark(targetSquare:getX(), targetSquare:getY())

    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "treasure_marked_on_map"),
        ChaosPlayerChatColors.blue)
end

function EffectSpawnTreasureInWorld:OnEnd()
    ChaosEffectBase:OnEnd()
end
