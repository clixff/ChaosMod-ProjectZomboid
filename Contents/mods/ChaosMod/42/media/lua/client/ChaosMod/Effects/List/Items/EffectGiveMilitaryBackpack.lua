---@class EffectGiveMilitaryBackpack : ChaosEffectBase
EffectGiveMilitaryBackpack = ChaosEffectBase:derive("EffectGiveMilitaryBackpack", "give_military_backpack")

function EffectGiveMilitaryBackpack:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local newItem = inventory:AddItem("Base.Bag_SurvivorBag")
    if not newItem then return end

    local wornItems = player:getWornItems()
    local wornItemBack = wornItems:getItem(ItemBodyLocation.BACK)

    if not wornItemBack then
        player:setWornItem(ItemBodyLocation.BACK, newItem)
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)

    ChaosPlayer.SayLineNewItemByString(player, "Base.Bag_SurvivorBag")
end
