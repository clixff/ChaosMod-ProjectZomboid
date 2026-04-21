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

---@param obj IsoObject
---@return string | nil
function ChaosProps.GetFurnitureType(obj)
    if not obj then return nil end
    local props = obj:getProperties()
    local container = obj:getContainer()
    local ctype = container and container:getType() or nil
    if props then
        if props:has("SinkType") and obj:hasWater() then
            return "sink"
        end
        if props:has("bed") then
            return "bed"
        end
        if props:has("chairN") or props:has("chairS") or props:has("chairE") or props:has("chairW") then
            return "chair"
        end
        if props:has("CustomName") then
            local custom = props:get("CustomName")
            if custom and string.find(custom, "Toilet") then
                return "toilet"
            end
        end
    end
    if ctype then
        if ctype == "fridge" or ctype == "freezer" then return "fridge" end
        if ctype == "stove" or ctype == "toaster" or ctype == "coffeemaker" then return "stove" end
        if ctype == "shelves" or ctype == "metal_shelves" then return "shelving" end
        if ctype == "counter" then return "counter" end
        if ctype == "sidetable" or ctype == "dresser" or ctype == "wardrobe" then return "container" end
    end
    if obj:isTableSurface() or (props and props:isTable()) then
        return "table"
    end
    if props and (props:has(IsoFlagType.shelfS) or props:has(IsoFlagType.shelfE)) then
        return "shelving"
    end
    local name = obj:getName()
    if name then
        local lower = string.lower(name)
        if string.find(lower, "sofa", 1, true) or string.find(lower, "couch", 1, true) then
            return "sofa"
        end
    end
    local sprite = obj:getSprite()
    if sprite and sprite:getName() then
        local lower = string.lower(sprite:getName())
        if string.find(lower, "sofa", 1, true) or string.find(lower, "couch", 1, true) then
            return "sofa"
        end
        if string.find(lower, "sink", 1, true) then
            return "sink"
        end
    end
    return nil
end

---@param square IsoGridSquare
---@return SCampfireGlobalObject?
function ChaosProps.SpawnCampfire(square)
    if not SCampfireSystem or not SCampfireSystem.instance then
        return nil
    end
    local campfire = SCampfireSystem.instance:addCampfire(square)
    if not campfire then
        return nil
    end
    campfire:setSpriteName("camping_01_6")
    campfire:syncSprite()
    campfire:syncIsoObject()
    return campfire
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
