EffectSetPirateOutfit = ChaosEffectBase:derive("EffectSetPirateOutfit", "set_pirate_outfit")

function EffectSetPirateOutfit:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetPirateOutfit] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end


    local hat = inventory:AddItem("Base.Hat_Pirate")
    local eyepatch = inventory:AddItem("Base.Glasses_Eyepatch_Left")
    local shirt = inventory:AddItem("Base.Shirt_Crafted_Cotton")
    local vest = inventory:AddItem("Base.Vest_Waistcoat")
    local trousers = inventory:AddItem("Base.Trousers_Black")
    local shoes = inventory:AddItem("Base.Shoes_CowboyBoots")

    -- Unequip all worn items
    player:clearWornItems()

    -- Equip new items
    player:setWornItem(hat:getBodyLocation(), hat)
    player:setWornItem(eyepatch:getBodyLocation(), eyepatch)
    player:setWornItem(shirt:getBodyLocation(), shirt)
    player:setWornItem(vest:getBodyLocation(), vest)
    player:setWornItem(trousers:getBodyLocation(), trousers)
    player:setWornItem(shoes:getBodyLocation(), shoes)

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
