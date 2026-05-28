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
        "Base.Sledgehammer",
        "Base.Crowbar",
        "Base.Machete",
        "Base.HuntingKnife",
        "Base.Bag_ALICEpack",
        "Base.Pills",
        "Base.Antibiotics",
        "Base.Pistol2",
        "Base.Pistol3",
    },
    legendary = {
        "Base.Katana",
        "Base.PetrolCan",
        "Base.Generator",
        "Base.CarBattery1",
        "Base.AssaultRifle",
        "Base.Revolver_Long",
        "Base.Vest_BulletPolice",
        "Base.Pistol",
        "Base.Shotgun",
    },
}

-- Roll rarity: 60% common, 25% uncommon, 12% rare, 3% legendary
-- With rollCount > 1, generate that many rolls and keep the highest (better rarity)
---@param rollCount integer? Number of rolls (nil = 1)
---@return string
local function rollRarity(rollCount)
    rollCount = rollCount or 1
    local roll = ChaosUtils.RandInteger(100)
    for _ = 2, rollCount do
        local nextRoll = ChaosUtils.RandInteger(100)
        if nextRoll > roll then
            roll = nextRoll
        end
    end
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

---@param rollCount integer? Number of rarity rolls (nil = 1); highest roll wins
---@return string
function GetRandomLootboxItem(rollCount)
    local rarity = rollRarity(rollCount)
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


    local itemsToAdd = 5

    for i = 1, itemsToAdd do
        local item = container:AddItem(GetRandomLootboxItem())
        if item then
            ChaosItems.SetFullAmmoIfWeapon(item)
        end
    end
end
