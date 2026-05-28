---@class EffectMedicalSuppliesDrop : ChaosEffectBase
---@field zLevel integer
EffectMedicalSuppliesDrop = ChaosEffectBase:derive("EffectMedicalSuppliesDrop", "medical_supplies_drop")

local FALL_DURATION_MS = 5000
local MARKER_DURATION_MS = 15000
local FALL_START_Z = 6.0
local FALL_END_Z = 0.0

local MEDICAL_ITEM_IDS = {
    "Base.Bandage",
    "Base.Bandaid",
    "Base.AlcoholWipes",
    "Base.Antibiotics",
    "Base.PillsAntiDep",
    "Base.PillsVitamins",
    "Base.PillsBeta",
    "Base.Pills",
    "Base.PillsSleepingTablets",
    "Base.Splint",
}

local BANDAGE_ITEM_IDS = {
    ["Base.Bandage"] = true,
    ["Base.Bandaid"] = true,
}

---@param itemOrWorldItem InventoryItem|IsoWorldInventoryObject
---@param visualZ number Absolute visual world Z, e.g. square Z + 3.0
---@param sync boolean? Use true when the final Z should be synced/saved
local function setWorldItemVisualZ(itemOrWorldItem, visualZ, sync)
    if not itemOrWorldItem then return nil end

    ---@diagnostic disable-next-line: assign-type-mismatch
    ---@type IsoWorldInventoryObject
    local worldItem = itemOrWorldItem
    if itemOrWorldItem.getWorldItem then
        worldItem = itemOrWorldItem:getWorldItem()
    end
    if not worldItem then
        print("[EffectMedicalSuppliesDrop] No IsoWorldInventoryObject for item")
        return nil
    end

    local square = worldItem:getSquare()
    if not square then
        print("[EffectMedicalSuppliesDrop] No square for world item")
        return worldItem
    end

    local zoff = visualZ - square:getZ()

    if sync then
        worldItem:setOffset(worldItem:getOffX(), worldItem:getOffY(), zoff)
    else
        worldItem:setOffZ(zoff)
        worldItem:invalidateRenderChunkLevel(256)
    end

    return worldItem
end

---@param caseItem InventoryContainer
local function spawnLoot(caseItem)
    if not caseItem then return end

    local container = caseItem:getInventory()
    if not container then return end

    for _, itemId in ipairs(MEDICAL_ITEM_IDS) do
        local count
        if BANDAGE_ITEM_IDS[itemId] then
            count = ChaosUtils.RandIntegerRange(3, 8 + 1)
        else
            count = ChaosUtils.RandIntegerRange(1, 5 + 1)
        end

        for _ = 1, count do
            container:AddItem(itemId)
        end
    end
end

---@param deltaMs integer
---@param data { caseItem: InventoryContainer, worldItem: IsoWorldInventoryObject, square: IsoGridSquare, elapsedMs: number }
local function FallTick(deltaMs, data)
    data.elapsedMs = data.elapsedMs + deltaMs
    local t = data.elapsedMs / FALL_DURATION_MS
    if t > 1 then t = 1 end

    if not data.square then return end

    local baseZ = 0

    local z = ChaosUtils.Lerp(baseZ + FALL_START_Z, baseZ + FALL_END_Z, t)
    setWorldItemVisualZ(data.worldItem, z, false)
end

---@param data { caseItem: InventoryContainer, worldItem: IsoWorldInventoryObject, square: IsoGridSquare }
local function FallEnd(data)
    if not data.square then return end
    local baseZ = 0
    setWorldItemVisualZ(data.worldItem, baseZ + FALL_END_Z, true)

    spawnLoot(data.caseItem)
end

---@param data { marker: WorldMarkers.GridSquareMarker }
local function MarkerEnd(data)
    if data.marker then
        data.marker:remove()
        data.marker = nil
    end
end

local function noop() end

function EffectMedicalSuppliesDrop:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 5, 20, 80, true, false, false)
    if not square then
        square = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 20, 40, 100, true, false, false)
    end

    if not square then
        ChaosPlayer.SayLineByColor(player, "Failed to find free square nearby", ChaosPlayerChatColors.red)
        square = player:getSquare()
    end

    ---@type InventoryContainer
    ---@diagnostic disable-next-line: assign-type-mismatch
    local caseItem = instanceItem("Base.FirstAidKit")
    if not caseItem then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    local addedItem = square:AddWorldInventoryItem(caseItem, 0.5, 0.5, 0.0)
    if not addedItem then return end

    local worldItem = caseItem:getWorldItem()
    if not worldItem then return end

    self.zLevel = 0

    setWorldItemVisualZ(worldItem, self.zLevel + FALL_START_Z, true)

    ChaosSpecialAction.AddNewAction(
        { caseItem = caseItem, worldItem = worldItem, square = square, elapsedMs = 0 },
        FALL_DURATION_MS,
        FallTick,
        FallEnd,
        FallEnd
    )

    local markers = getWorldMarkers()
    if markers then
        local marker = markers:addGridSquareMarker(square, 0.2, 1.0, 0.2, true, 4)
        if marker then
            marker:setScaleCircleTexture(false)
            ChaosSpecialAction.AddNewAction(
                { marker = marker },
                MARKER_DURATION_MS,
                noop,
                MarkerEnd,
                MarkerEnd
            )
        end
    end
end

function EffectMedicalSuppliesDrop:OnEnd()
    ChaosEffectBase:OnEnd()
end
