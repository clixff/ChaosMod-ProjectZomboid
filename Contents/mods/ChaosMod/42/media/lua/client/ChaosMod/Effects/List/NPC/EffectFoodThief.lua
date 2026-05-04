---@class EffectFoodThief : ChaosEffectBase
EffectFoodThief = ChaosEffectBase:derive("EffectFoodThief", "food_thief")

function EffectFoodThief:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        playerSquare:getX(), playerSquare:getY(), playerSquare:getZ(), 1, "Spiffo", 0)
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.ROBBER
    npc:AddTag("item_robber")
    self.npc = npc

    local inventory = player:getInventory()
    ---@type InventoryItem[]
    local foodItems = {}
    local worn = player:getWornItems()
    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if item and item:isFood() then
            table.insert(foodItems, item)
        end
    end)

    if #foodItems == 0 then return end

    for i = 1, #foodItems do
        local stolenItem = foodItems[i]
        if worn and worn:contains(stolenItem) then
            player:removeWornItem(stolenItem)
        end
        inventory:Remove(stolenItem)
        zombie:addItemToSpawnAtDeath(stolenItem)

        local imgCode = ChaosUtils.GetImgCodeByItemTexture(stolenItem)
        local str = string.format(
            ChaosLocalization.GetString("misc", "robber_steals_item"),
            imgCode, stolenItem:getDisplayName())
        ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
    end
end

function EffectFoodThief:OnEnd()
    if self.npc then
        self.npc:Destroy()
        self.npc = nil
    end
end
