---@class EffectPlayerCantEat : ChaosEffectBase
EffectPlayerCantEat = ChaosEffectBase:derive("EffectPlayerCantEat", "player_cant_eat")

local orig_ISInventoryPaneContextMenu_onEatItems = nil

---@param player IsoPlayer | number | nil
---@return IsoPlayer | nil
local function getEatPlayer(player)
    if type(player) == "number" then
        return getSpecificPlayer(math.floor(player))
    end

    return player or getPlayer()
end

function EffectPlayerCantEat:OnStart()
    ChaosEffectBase:OnStart()

    orig_ISInventoryPaneContextMenu_onEatItems = ISInventoryPaneContextMenu.onEatItems

    ISInventoryPaneContextMenu.onEatItems = function(items, percentage, player, openingRecipe, eatPercentage)
        local playerObj = getEatPlayer(player)
        if playerObj then
            ChaosPlayer.SayLineByColor(playerObj, "I can't eat.", ChaosPlayerChatColors.red)
        end
        return
    end
end

function EffectPlayerCantEat:OnEnd()
    ChaosEffectBase:OnEnd()

    if orig_ISInventoryPaneContextMenu_onEatItems then
        ISInventoryPaneContextMenu.onEatItems = orig_ISInventoryPaneContextMenu_onEatItems
        orig_ISInventoryPaneContextMenu_onEatItems = nil
    end
end
