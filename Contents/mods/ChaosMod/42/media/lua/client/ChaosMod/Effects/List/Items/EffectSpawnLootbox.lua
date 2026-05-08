EffectSpawnLootbox = ChaosEffectBase:derive("EffectSpawnLootbox", "spawn_lootbox")

---@type table<string, table<integer, string>>
LOOTBOX_ITEMS = {
    common = {
        "Base.Bandage",
        "Base.BandageDirty",
        "Base.RippedSheets",
        "Base.WaterBottle",
        "Base.CannedCarrots",
        "Base.Bread",
        "Base.Crisps",
        "Base.Torch",
        "Base.Battery",
        "Base.Lighter",
        "Base.Matches",
    },
    uncommon = {
        "Base.DuctTape",
        "Base.Glue",
        "Base.Screws",
        "Base.Nails",
        "Base.Twine",
        "Base.Hammer",
        "Base.Screwdriver",
        "Base.Wrench",
        "Base.KitchenKnife",
        "Base.BaseballBat",
        "Base.Bag_Schoolbag",
    },
    rare = {
        "Base.Axe",
        "Base.Crowbar",
        "Base.Machete",
        "Base.HuntingKnife",
        "Base.Pistol",
        "Base.Shotgun",
        "Base.Bag_ALICEpack",
        "Base.Pills",
        "Base.Antibiotics",
    },
    legendary = {
        "Base.Katana",
        "Base.Sledgehammer",
        "Base.PetrolCan",
        "Base.Generator",
        "Base.CarBattery1",
    },
}

-- Roll rarity: 60% common, 25% uncommon, 12% rare, 3% legendary
---@return string
local function rollRarity()
    local roll = ChaosUtils.RandInteger(100)
    if roll < 60 then
        return "common"
    elseif roll < 85 then
        return "uncommon"
    elseif roll < 97 then
        return "rare"
    else
        return "legendary"
    end
end

---@return string
function GetRandomLootboxItem()
    local rarity = rollRarity()
    local pool = LOOTBOX_ITEMS[rarity]
    return pool[ChaosUtils.RandArrayIndex(pool)]
end

function EffectSpawnLootbox:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnLootbox] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    ---@type InventoryContainer
    local worldItem = square:AddWorldInventoryItem("Base.Present_ExtraLarge", 0.5, 0.5, 0.0)
    if not worldItem then
        print("[EffectSpawnLootbox] Failed to spawn lootbox")
        return
    end


    local container = worldItem:getInventory()
    if not container then
        print("[EffectSpawnLootbox] Failed to get container from lootbox")
        return
    end

    ---@type string
    local rarity = rollRarity()
    local pool = LOOTBOX_ITEMS[rarity]
    if not pool then return end
    ---@type string
    local itemId = pool[ChaosUtils.RandArrayIndex(pool)]
    if not itemId then return end

    container:AddItem(itemId)
    print("[EffectSpawnLootbox] Spawned lootbox with " .. rarity .. " item: " .. itemId)
end
