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

---@return string
function ChaosItems.GetRandomItemId()
    local allItems = getAllItems()
    local randomIndex = math.floor(ZombRand(allItems:size()))
    local randomItemScript = allItems:get(randomIndex)
    if not randomItemScript then return "" end

    local module = randomItemScript:getModuleName() or "Base"


    local itemType = string.format("%s.%s", module, randomItemScript:getName())
    return itemType
end
