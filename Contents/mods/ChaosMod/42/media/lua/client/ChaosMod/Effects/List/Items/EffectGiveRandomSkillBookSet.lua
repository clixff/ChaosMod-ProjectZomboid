EffectGiveRandomSkillBookSet = ChaosEffectBase:derive("EffectGiveRandomSkillBookSet", "give_random_skill_book_set")

local SKILL_BOOK_IDS = {
    "Base.BookCarpentrySet",
    "Base.BookCarvingSet",
    "Base.BookCookingSet",
    "Base.BookElectricianSet",
    "Base.BookFarmingSet",
    "Base.BookFirstAidSet",
    "Base.BookFishingSet",
    "Base.BookFlintKnappingSet",
    "Base.BookForagingSet",
    "Base.BookGlassmakingSet",
    "Base.BookMasonrySet",
    "Base.BookMechanicsSet",
    "Base.BookMetalWeldingSet",
    "Base.BookBlacksmithSet",
    "Base.BookPotterySet",
    "Base.BookTailoringSet",
    "Base.BookTrappingSet",
    "Base.BookAimingSet",
    "Base.BookReloadingSet",
    "Base.BookHusbandrySet",
    "Base.BookButcheringSet",
    "Base.BookTrackingSet",
    "Base.BookLongBladeSet",
    "Base.BookMaintenanceSet",
}

function EffectGiveRandomSkillBookSet:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomSkillBookSet] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = math.floor(ZombRand(1, #SKILL_BOOK_IDS + 1))
    local randomSkillBookId = SKILL_BOOK_IDS[randomIndex]
    if not randomSkillBookId then return end

    local newItem = inventory:AddItem(randomSkillBookId)
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(player, newItem)
end
