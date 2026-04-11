EffectGiveRandomMedicalItem = ChaosEffectBase:derive("EffectGiveRandomMedicalItem", "give_random_medical_item")

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
    "Base.Splint"
}

function EffectGiveRandomMedicalItem:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomMedicalItem] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = math.floor(ZombRand(1, #MEDICAL_ITEM_IDS + 1))
    local randomMedicalItem = MEDICAL_ITEM_IDS[randomIndex]
    if not randomMedicalItem then return end

    local randomAmount = math.floor(ZombRand(1, 5 + 1))

    for i = 1, randomAmount do
        local newItem = inventory:AddItem(randomMedicalItem)
        if not newItem then return end

        if i == randomAmount then
            ChaosPlayer.SayLineNewItem(player, newItem, randomAmount)
        end
    end
end
