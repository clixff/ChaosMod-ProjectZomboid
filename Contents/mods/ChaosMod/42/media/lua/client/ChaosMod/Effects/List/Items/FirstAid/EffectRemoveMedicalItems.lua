EffectRemoveMedicalItems = ChaosEffectBase:derive("EffectRemoveMedicalItems", "remove_medical_items")

---@type table<string, true>
local MEDICAL_ITEM_IDS = {
    ["Base.Antibiotics"] = true,
    ["Base.PillsAntiDep"] = true,
    ["Base.PillsVitamins"] = true,
    ["Base.PillsBeta"] = true,
    ["Base.Pills"] = true,
    ["Base.PillsSleepingTablets"] = true,
    ["Base.Bandage"] = true,
    ["Base.BandageDirty"] = true,
    ["Base.AlcoholBandage"] = true,
    ["Base.Bandaid"] = true,
    ["Base.RippedSheets"] = true,
    ["Base.RippedSheetsDirty"] = true,
    ["Base.AlcoholRippedSheets"] = true,
    ["Base.DenimStrips"] = true,
    ["Base.DenimStripsDirty"] = true,
    ["Base.LeatherStrips"] = true,
    ["Base.LeatherStripsDirty"] = true,
    ["Base.AlcoholWipes"] = true,
    ["Base.Disinfectant"] = true,
    ["Base.AlcoholedCottonBalls"] = true,
    ["Base.WhiskeyFull"] = true,
    ["Base.Splint"] = true,
    ["Base.SutureNeedle"] = true,
    ["Base.SutureNeedleHolder"] = true,
    ["Base.Tweezers"] = true,
    ["Base.CottonBalls"] = true,
    ["Base.BlackSage"] = true,
    ["Base.Comfrey"] = true,
    ["Base.CommonMallow"] = true,
    ["Base.Ginseng"] = true,
    ["Base.LemonGrass"] = true,
    ["Base.Plantain"] = true,
    ["Base.WildGarlic"] = true,
    ["Base.ComfreyCataplasm"] = true,
    ["Base.PlantainCataplasm"] = true,
    ["Base.WildGarlicCataplasm"] = true,
    ["Base.Tissue"] = true,
    ["Base.BathTowel"] = true,
    ["Base.DishCloth"] = true,
}

function EffectRemoveMedicalItems:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveMedicalItems] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local itemsToRemove = {}

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if not item then return end

        local fullType = item:getFullType()
        if fullType and MEDICAL_ITEM_IDS[fullType] then
            itemsToRemove[#itemsToRemove + 1] = item
        end
    end)

    if #itemsToRemove == 0 then
        return
    end

    local wornItems = player:getWornItems()
    local removedWearable = false

    ---@type table<string, { count: integer, item: InventoryItem }>
    local removedByType = {}
    ---@type string[]
    local removedOrder = {}

    for _, item in ipairs(itemsToRemove) do
        local fullType = item:getFullType()
        if fullType then
            local removedData = removedByType[fullType]
            if not removedData then
                removedData = { count = 0, item = item }
                removedByType[fullType] = removedData
                removedOrder[#removedOrder + 1] = fullType
            end
            removedData.count = removedData.count + 1
        end

        if wornItems and wornItems:contains(item) then
            player:removeWornItem(item)
            removedWearable = true
        end

        if player:getPrimaryHandItem() == item then
            ---@diagnostic disable-next-line: param-type-mismatch
            player:setPrimaryHandItem(nil)
        end

        if player:getSecondaryHandItem() == item then
            ---@diagnostic disable-next-line: param-type-mismatch
            player:setSecondaryHandItem(nil)
        end

        item:Remove()
    end

    if removedWearable then
        player:onWornItemsChanged()
        player:resetModelNextFrame()
        triggerEvent("OnClothingUpdated", player)
    end

    for _, fullType in ipairs(removedOrder) do
        local removedData = removedByType[fullType]
        if removedData and removedData.item then
            ChaosPlayer.SayLineRemovedItem(player, removedData.item, removedData.count)
        end
    end
end
