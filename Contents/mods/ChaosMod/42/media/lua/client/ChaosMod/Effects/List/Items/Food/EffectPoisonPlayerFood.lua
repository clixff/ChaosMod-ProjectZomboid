---@class EffectPoisonPlayerFood : ChaosEffectBase
EffectPoisonPlayerFood = ChaosEffectBase:derive("EffectPoisonPlayerFood", "poison_player_food")

local POISON_POWER = 20
local POISON_DETECTION_LEVEL = 10

---@param item InventoryItem
local function poisonFoodItem(item)
    if not item or not item:isFood() then return false end
    ---@cast item Food
    item:setPoisonPower(POISON_POWER)
    item:setPoisonDetectionLevel(POISON_DETECTION_LEVEL)
    return true
end

function EffectPoisonPlayerFood:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local totalPoisoned = 0
    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if poisonFoodItem(item) then
            totalPoisoned = totalPoisoned + 1
        end
    end)

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.Bread")
    local msg = string.format(ChaosLocalization.GetString("misc", "food_poisoned"), imgCode, totalPoisoned)
    ChaosPlayer.SayLineByColor(player, msg, ChaosPlayerChatColors.red)
end

function EffectPoisonPlayerFood:OnEnd()
    ChaosEffectBase:OnEnd()
end
