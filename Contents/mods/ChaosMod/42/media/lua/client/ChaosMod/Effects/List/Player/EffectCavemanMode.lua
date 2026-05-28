---@class EffectCavemanMode : ChaosEffectBase
EffectCavemanMode = ChaosEffectBase:derive("EffectCavemanMode", "caveman_mode")

function EffectCavemanMode:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.UnequipAllClothes(player)

    local clothingTypes = {
        "Base.Underpants_Hide",
        "Base.Vest_Hide",
        "Base.Skirt_Short_FaunHide",
        "Base.Shoes_TireSandals",
    }

    for _, fullType in ipairs(clothingTypes) do
        local item = inventory:AddItem(fullType)
        if item then
            ChaosPlayer.EquipClothes(player, item)
        end
    end

    local weapon = inventory:AddItem("Base.LargeBoneClub")
    if weapon then
        ChaosPlayer.EquipWeapon(player, weapon)
        ChaosPlayer.SayLineNewItem(player, weapon)
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    player:addLotsOfDirt(nil, 200, true)

    player:resetModelNextFrame()
end

function EffectCavemanMode:OnEnd()
    ChaosEffectBase:OnEnd()
end
