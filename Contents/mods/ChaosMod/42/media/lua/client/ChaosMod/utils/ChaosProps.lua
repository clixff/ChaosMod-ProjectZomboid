ChaosProps = ChaosProps or {}

CHAOS_PRPOPS_LIST = {
    "furniture_seating_indoor_01_50",
    "furniture_seating_indoor_01_54",
    "furniture_seating_indoor_01_60",
    "furniture_seating_indoor_01_56",
    "furniture_seating_indoor_02_20",
    "furniture_seating_indoor_03_48",
    "furniture_storage_01_48",
    "furniture_storage_02_27",
    "furniture_tables_high_01_14",
    "furniture_tables_high_01_15",
    "location_shop_mall_01_47",
    "vegetation_indoor_01_11",
    "vegetation_indoor_01_3",
    "vegetation_ornamental_01_40",
    "street_decoration_01_20",
    "fixtures_bathroom_01_5",
    "fixtures_bathroom_01_1",
    "street_decoration_01_38",
    "furniture_seating_outdoor_01_16",
    "industry_01_22",
    "lighting_outdoor_01_48"
}

---@return string
function ChaosProps.GetRandomPropName()
    local randomIndex = math.floor(ZombRandBetween(1, #CHAOS_PRPOPS_LIST + 1))
    local propName = CHAOS_PRPOPS_LIST[randomIndex]
    if not propName then return "" end
    return propName
end

---@param square IsoGridSquare
---@param spriteName string
---@return IsoMannequin?
function ChaosProps.SpawnMannequin(square, spriteName)
    local sprite = getSprite(spriteName)
    if not sprite then return nil end
    local man = IsoMannequin.new(getCell(), square, sprite)
    square:AddSpecialObject(man)
    return man
end

---@param man IsoMannequin
---@param fullType string
---@return InventoryItem?
function ChaosProps.AddClothingToMannequin(man, fullType)
    local container = man:getContainer()
    if not container then return nil end
    local item = container:AddItem(fullType)
    if not item then return nil end
    ---@diagnostic disable-next-line: param-type-mismatch
    man:wearItem(item, nil)
    return item
end

---@param square IsoGridSquare
---@param spriteName string
---@return IsoObject?
function ChaosProps.SpawnProp(square, spriteName)
    local obj = IsoThumpable.new(getCell(), square, spriteName, true, {})
    if not obj then return nil end

    obj:setMaxHealth(100)
    obj:setHealth(100)
    obj:setThumpDmg(1)
    obj:setIsThumpable(true)
    obj:setBreakSound(IsoThumpable.GetBreakFurnitureSound(spriteName))

    square:AddSpecialObject(obj)

    return obj
end
