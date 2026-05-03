EffectEquipFurryEars = ChaosEffectBase:derive("EffectEquipFurryEars", "equip_furry_ears")

function EffectEquipFurryEars:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.Hat_FurryEars")
    if item then
        ChaosPlayer.EquipClothes(player, item)
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
