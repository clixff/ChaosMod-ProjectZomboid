---@class EffectMilitarySupplyDrop : ChaosEffectBase
---@fied zLevel integer
EffectMilitarySupplyDrop = ChaosEffectBase:derive("EffectMilitarySupplyDrop", "military_supply_drop")

local FALL_DURATION_MS = 5000
local HELI_SOUND_DURATION_MS = FALL_DURATION_MS + 4000
local MARKER_DURATION_MS = 15000
local FALL_START_Z = 6.0
local FALL_END_Z = 0.0
local ZOMBIES_AGGRO_RADIUS = 35
local ZOMBIES_AGGRO_VOLUME = 80

local MILITARY_AMMO_IDS = {
    "Base.3030Box",
    "Base.Bullets357Box",
    "Base.Bullets38Box",
    "Base.Bullets44Box",
    "Base.Bullets45Box",
    "Base.ShotgunShellsBox",
    "Base.556Box",
    "Base.308Box",
    "Base.Bullets9mmBox",
}

local MILITARY_ITEMS = {
    { type = "Base.CannedPotato2",              count = 5 },
    { type = "Base.Vest_BulletArmy",            count = 1 },
    { type = "Base.Hat_ArmyWWII",               count = 1 },
    { type = "Base.Bag_ALICE_BeltSus",          count = 1 },
    { type = "Base.Shoes_ArmyBoots",            count = 1 },
    { type = "Base.Trousers_CamoGreen",         count = 1 },
    { type = "Base.Bag_HydrationBackpack_Camo", count = 1 },
    { type = "Base.Pills",                      count = 3 },
    { type = "Base.AssaultRifle",               count = 1 },
    { type = "Base.Bag_ALICEpack",              count = 1 },
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
        print("[EffectMilitarySupplyDrop] No IsoWorldInventoryObject for item")
        return nil
    end

    local square = worldItem:getSquare()
    if not square then
        print("[EffectMilitarySupplyDrop] No square for world item")
        return worldItem
    end

    local zoff = visualZ - square:getZ()

    if sync then
        worldItem:setOffset(worldItem:getOffX(), worldItem:getOffY(), zoff)
    else
        -- Visual-only update. setOffset() syncs every call, which is bad during falling animation.
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

    for _ = 1, 5 do
        local item = container:AddItem(GetRandomLootboxItem())

        if item then
            ChaosItems.SetFullAmmoIfWeapon(item)
        end
    end

    for _, ammoItemId in ipairs(MILITARY_AMMO_IDS) do
        if ChaosUtils.RandInteger(100) < 50 then
            container:AddItem(ammoItemId)
        end
    end

    for _, entry in ipairs(MILITARY_ITEMS) do
        for _ = 1, entry.count do
            if ChaosUtils.RandFloat(0, 100) < 50.0 then
                local item = container:AddItem(entry.type)
                if item then
                    ChaosItems.SetFullAmmoIfWeapon(item)
                end
            end
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

    local square = data.square
    if square then
        ---@diagnostic disable-next-line: param-type-mismatch
        addSound(nil, square:getX(), square:getY(), square:getZ(), ZOMBIES_AGGRO_RADIUS, ZOMBIES_AGGRO_VOLUME)
    end
end

---@param data { heliEmitter: FMODSoundEmitter, heliSound: integer }
local function HeliSoundEnd(data)
    if data.heliEmitter and data.heliSound then
        data.heliEmitter:stopSound(data.heliSound)
    end
    data.heliEmitter = nil
    data.heliSound = nil
end

---@param data { marker: WorldMarkers.GridSquareMarker }
local function MarkerEnd(data)
    if data.marker then
        data.marker:remove()
        data.marker = nil
    end
end

local function noop() end

function EffectMilitarySupplyDrop:OnStart()
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
    local caseItem = instanceItem("Base.Bag_ProtectiveCaseBulkyMilitary")
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
        local marker = markers:addGridSquareMarker(square, 1.0, 0.2, 0.2, true, 4)
        if marker then
            marker:setScaleCircleTexture(true)
            ChaosSpecialAction.AddNewAction(
                { marker = marker },
                MARKER_DURATION_MS,
                noop,
                MarkerEnd,
                MarkerEnd
            )
        end
    end

    local world = getWorld()
    if world then
        local heliEmitter = world:getFreeEmitter(square:getX(), square:getY(), square:getZ())
        if heliEmitter then
            local heliSound = heliEmitter:playSound("Helicopter")
            ChaosSpecialAction.AddNewAction(
                { heliEmitter = heliEmitter, heliSound = heliSound },
                HELI_SOUND_DURATION_MS,
                noop,
                HeliSoundEnd,
                HeliSoundEnd
            )
        end
    end
end

function EffectMilitarySupplyDrop:OnEnd()
    ChaosEffectBase:OnEnd()
end
