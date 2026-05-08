EffectEquipBunnyCostume = ChaosEffectBase:derive("EffectEquipBunnyCostume", "equip_bunny_costume")

function EffectEquipBunnyCostume:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.UnequipAllClothes(player)

    local items = {
        inventory:AddItem("Base.Hat_BunnyEarsBlack"),
        inventory:AddItem("Base.BunnyTail"),
        inventory:AddItem("Base.BunnySuitBlack"),
    }

    for _, item in ipairs(items) do
        if item then
            ChaosPlayer.EquipClothes(player, item)
            ChaosPlayer.SayLineNewItem(player, item)
        end
    end
end
