EffectReplaceWaterWithBleach = ChaosEffectBase:derive("EffectReplaceWaterWithBleach", "replace_water_with_bleach")

---@param item InventoryItem
---@return boolean
local function handleItem(item)
    if not item then return false end
    if item:IsInventoryContainer() then return false end

    local fluidContainer = item:getFluidContainer()
    if not fluidContainer then return false end

    if fluidContainer:isWaterSource() then
        local amount = fluidContainer:getAmount()
        fluidContainer:Empty()
        fluidContainer:addFluid(FluidType.Bleach, amount)
        return true
    end

    return false
end


function EffectReplaceWaterWithBleach:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceWaterWithBleach] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local itemsList = inventory:getItems()
    if not itemsList then return end

    local count = 0

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if handleItem(item) then
            count = count + 1
        end
    end)

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.WaterBottle")
    local str = string.format(ChaosLocalization.GetString("misc", "water_replaced_with_bleach"), imgCode, count)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
