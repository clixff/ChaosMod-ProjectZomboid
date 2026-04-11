EffectGiveRandomSkillBook = ChaosEffectBase:derive("EffectGiveRandomSkillBook", "give_random_skill_book")

local SKILL_BOOK_IDS = {
    "Base.BookFarming",
    "Base.BookAiming",
    "Base.BookHusbandry",
    "Base.BookBlacksmith",
    "Base.BookButchering",
    "Base.BookCarpentry",
    "Base.BookCarving",
    "Base.BookCooking",
    "Base.BookElectrician",
    "Base.BookFirstAid",
    "Base.BookFishing",
    "Base.BookForaging",
    "Base.BookGlassmaking",
    "Base.BookFlintKnapping",
    "Base.BookLongBlade",
    "Base.BookMaintenance",
    "Base.BookMasonry",
    "Base.BookMechanic",
    "Base.BookPottery",
    "Base.BookReloading",
    "Base.BookTailoring",
    "Base.BookTracking",
    "Base.BookTrapping",
    "Base.BookMetalWelding",
}

function EffectGiveRandomSkillBook:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomSkillBook] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = math.floor(ZombRand(1, #SKILL_BOOK_IDS + 1))
    local randomSkillBookId = SKILL_BOOK_IDS[randomIndex]
    if not randomSkillBookId then return end

    local randomChance = ZombRand(0, 100 + 1)

    if randomChance < 75 then
        randomSkillBookId = randomSkillBookId .. "1"
    elseif randomChance < 80 then
        randomSkillBookId = randomSkillBookId .. "2"
    elseif randomChance < 95 then
        randomSkillBookId = randomSkillBookId .. "3"
    elseif randomChance < 99 then
        randomSkillBookId = randomSkillBookId .. "4"
    else
        randomSkillBookId = randomSkillBookId .. "5"
    end

    local newItem = inventory:AddItem(randomSkillBookId)
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(player, newItem)
end
