ChaosItems = ChaosItems or {}

---@type table<integer, string>
ChaosItems.CHAOS_FOOD_ITEMS_IDS = {
    "Base.CatFoodBag", "Base.DogFoodBag", "Base.OatsRaw", "Base.SugarBeetPulpPot", "Base.Chocolate_HeartBox",
    "Base.Cereal", "Base.SugarBeetSyrupPot", "Base.SugarBeetSugarPot", "Base.CocoaPowder", "Base.Coffee2",
    "Base.PieApple", "Base.PieBlueberry", "Base.PieKeyLime", "Base.PieLemonMeringue", "Base.PiePumpkin",
    "Base.SeedPasteBowl", "Base.JamFruit", "Base.Icecream", "Base.IcecreamMelted", "Base.JamMarmalade", "Base.SeedPaste",
    "Base.PeanutButter", "Base.TVDinner", "Base.Cupcake", "Base.ScoutCookies", "Base.Springroll", "Base.Dough",
    "Base.Cheese", "Base.Crisps2", "Base.Crisps", "Base.Crisps3", "Base.Crisps4", "Base.Creamocle",
    "Base.Creamocle_Melted", "Base.FudgeePop", "Base.FudgeePop_Melted", "Base.GranolaBar", "Base.ConeIcecreamMelted",
    "Base.IcecreamSandwich", "Base.IcecreamSandwich_Melted", "Base.Popsicle", "Base.Popsicle_Melted",
    "Base.TortillaChips", "Base.ChickenFried", "Base.MeatSteamBun", "Base.PotatoPancakes", "Base.ChickenFoot",
    "Base.CinnamonRoll", "Base.Corndog", "Base.NoodleSoup", "Base.RamenBowl", "Base.Fries", "Base.Popcorn",
    "Base.Yoghurt", "Base.CakeBlackForest", "Base.ChocoCakes", "Base.CakeChocolate", "Base.CrispyRiceSquare",
    "Base.HiHis", "Base.Plonkies", "Base.QuaggaCakes", "Base.SnoGlobes", "Base.Cornbread", "Base.DehydratedMeatStick",
    "Base.Icing", "Base.Modjeska", "Base.Smore", "Base.CakeCheeseCake", "Base.CakeRedVelvet",
    "Base.CakeStrawberryShortcake", "Base.Croissant", "Base.SushiEgg", "Base.CakeCarrot", "Base.DoughnutChocolate",
    "Base.Danish", "Base.DoughnutPlain", "Base.DoughnutFrosted", "Base.MuffinFruit", "Base.DoughnutJelly",
    "Base.JellyRoll", "Base.LemonBar", "Base.Perogies", "Base.ChocolateChips", "Base.CatTreats",
    "Base.ChocolateCoveredCoffeeBeans", "Base.Cone", "Base.Crackers", "Base.Gingerbreadman", "Base.GrahamCrackers",
    "Base.Marshmallows", "Base.PorkRinds", "Base.Pretzel", "Base.Processedcheese", "Base.CookieJelly", "Base.Teabag2",
    "Base.BarleySeed", "Base.RyeSeed", "Base.WheatSeed", "Base.RicePaper", "Base.Painauchocolat", "Base.Peppermint",
    "Base.Tadpole"
}

---@return string
function ChaosItems.GetRandomFoodItemId()
    local randomIndex = math.floor(ZombRand(1, #ChaosItems.CHAOS_FOOD_ITEMS_IDS + 1))
    local randomFoodItemId = ChaosItems.CHAOS_FOOD_ITEMS_IDS[randomIndex]
    if not randomFoodItemId then return "" end
    return randomFoodItemId
end

---@param item Item
---@return boolean
local function isBadRandomItem(item)
    if not item then return true end

    -- Moveable/world-object style items
    local itemType = item:getItemType()
    if itemType == ItemType.MOVEABLE or tostring(itemType) == "base:moveable" then
        return true
    end

    -- Hidden/internal items
    if item:isHidden() then
        return true
    end

    local displayCategory = item:getDisplayCategory()
    if displayCategory == "Hidden" then
        return true
    end

    local name = item:getName() or ""
    local fullType = item:getFullName() or ""

    -- Heuristics for dev/test/internal stuff
    if string.find(name, "DEV", 1, true)
        or string.find(name, "DEBUG", 1, true)
        or string.find(name, "Test", 1, true)
        or string.find(name, "Dummy", 1, true)
        or string.find(fullType, "DEV", 1, true)
        or string.find(fullType, "DEBUG", 1, true)
        or string.find(fullType, "Test", 1, true)
        or string.find(fullType, "Dummy", 1, true) then
        return true
    end

    -- Exact blacklist for odd leftovers
    local bad = {
        ["Base.FISH_DEV_ITEM"] = true,
        ["Base.BucketWaterDebug"] = true,
        ["Base.TestCanPopCommon"] = true,
        ["Base.WaterRationCan_Open"] = true,
        ["Base.Animal_Item_Dummy"] = true,
        ["Base.YardstickDEBUG"] = true,
        ["Base.DentedCan_Open"] = true,
        ["Base.Hat_SantaHatDebug"] = true,
        ["Base.TestHotDrink"] = true,
        ["Base.TestMug"] = true,
        ["Base.TestWaterMug"] = true,
        ["Base.DebugFluid"] = true,
        ["Base.TestDebugWater"] = true,
        ["Base.Stairs"] = true,
        ["Base.MysteryCan_Open"] = true,
        ["Base.WaterDrop"] = true,
    }

    if bad[fullType] then
        return true
    end

    if string.find(fullType, "Base.Bandage_", 1, true) == 1
        or string.find(fullType, "Base.Wound_", 1, true) == 1 then
        return true
    end

    return false
end

---@return string
function ChaosItems.GetRandomItemId()
    local allItems = getAllItems()
    if not allItems or allItems:isEmpty() then return "" end

    for _ = 1, 500 do
        local randomIndex = ChaosUtils.RandInteger(allItems:size())
        local item = allItems:get(randomIndex)
        if item and not isBadRandomItem(item) then
            return item:getFullName() or ""
        end
    end

    return ""
end

---@type { all: string[]?, melee: string[]?, firearm: string[]? }
local RandomWeaponIDs = {
    all = nil,
    melee = nil,
    firearm = nil,
}
---@param item Item
---@return boolean
local function isValidWeaponItem(item)
    if not item then return false end
    if item:isHidden() then return false end
    if item:getObsolete() then return false end
    if not item:canSpawnAsLoot() then return false end

    local cat = item:getDisplayCategory()
    if not cat then return false end

    return string.find(cat, "Weapon", 1, true) ~= nil
end

local function buildWeaponLists()
    if RandomWeaponIDs.all then return end

    RandomWeaponIDs.all = {}
    RandomWeaponIDs.melee = {}
    RandomWeaponIDs.firearm = {}

    local items = getAllItems()

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if isValidWeaponItem(item) then
            local id = item:getFullName()

            table.insert(RandomWeaponIDs.all, id)

            if item:isRanged() then
                table.insert(RandomWeaponIDs.firearm, id)
            else
                table.insert(RandomWeaponIDs.melee, id)
            end
        end
    end
end

---@param list string[]?
---@return string?
local function randomFrom(list)
    if not list or #list == 0 then return nil end
    return list[ChaosUtils.RandArrayIndex(list)]
end

---@return string?
function ChaosItems.GetRandomWeaponID()
    buildWeaponLists()
    return randomFrom(RandomWeaponIDs.all)
end

---@return string?
function ChaosItems.GetRandomMeleeWeaponID()
    buildWeaponLists()
    return randomFrom(RandomWeaponIDs.melee)
end

---@return string?
function ChaosItems.GetRandomFirearmWeaponID()
    buildWeaponLists()
    return randomFrom(RandomWeaponIDs.firearm)
end

---@param item InventoryItem?
function ChaosItems.SetFullAmmoIfWeapon(item)
    if not item then return end

    if not instanceof(item, "HandWeapon") then return end

    ---@cast item HandWeapon

    if item.isRanged and item:isRanged() then
        item:setCurrentAmmoCount(item:getMaxAmmo() - 1)
        item:setRoundChambered(true)
    end
end
