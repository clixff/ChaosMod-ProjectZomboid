EffectEquipSpiffoCostume = ChaosEffectBase:derive("EffectEquipSpiffoCostume", "equip_spiffo_costume")

function EffectEquipSpiffoCostume:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local items = {
        inventory:AddItem("Base.SpiffoSuit"),
        inventory:AddItem("Base.Hat_Spiffo"),
        inventory:AddItem("Base.SpiffoTail"),
    }

    for _, item in ipairs(items) do
        if item then
            ChaosPlayer.EquipClothes(player, item)
            ChaosPlayer.SayLineNewItem(player, item)
        end
    end
end
