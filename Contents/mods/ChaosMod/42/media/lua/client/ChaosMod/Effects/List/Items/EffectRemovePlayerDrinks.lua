EffectRemovePlayerDrinks = ChaosEffectBase:derive("EffectRemovePlayerDrinks", "remove_player_drinks")

local removedCount = 0

---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end

    if not item:isFluidContainer() then
        return
    end

    local container = item:getFluidContainer()
    if container == nil then
        return
    end

    -- If empty, it's a fluid container with no petrol
    if container:isEmpty() then
        item:Remove()
        removedCount = removedCount + 1
        return
    end

    -- Check if the primary (dominant) fluid is NOT petrol
    if not container:isPrimaryFluidType("Petrol") then
        item:Remove()
        removedCount = removedCount + 1
    end
end

function EffectRemovePlayerDrinks:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerDrinks] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    removedCount = 0
    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.WaterBottle")

    local str = string.format(ChaosLocalization.GetString("misc", "drinks_removed"), imgCode, removedCount)

    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
