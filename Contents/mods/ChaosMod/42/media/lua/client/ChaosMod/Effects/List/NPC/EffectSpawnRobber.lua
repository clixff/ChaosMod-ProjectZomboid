---@class EffectSpawnRobber : ChaosEffectBase
EffectSpawnRobber = ChaosEffectBase:derive("EffectSpawnRobber", "spawn_robber")

function EffectSpawnRobber:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnRobber] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        playerSquare:getX(), playerSquare:getY(), playerSquare:getZ(), 1, "Inmate", 0)
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.ROBBER
    npc:AddTag("item_robber")
    self.npc = npc

    ---@type InventoryItem[]
    local allItems = {}
    ChaosPlayer.CollectAllItems(player:getInventory(), allItems, false)


    if #allItems == 0 then return end

    local worn = player:getWornItems()
    local stealCount = math.min(3, #allItems)
    for i = 1, stealCount do
        local index = ChaosUtils.RandIntegerRange(1, #allItems + 1)
        local stolenItem = allItems[index]
        table.remove(allItems, index)
        if not stolenItem then break end
        if worn and worn:contains(stolenItem) then
            player:removeWornItem(stolenItem)
        end
        player:getInventory():Remove(stolenItem)
        zombie:addItemToSpawnAtDeath(stolenItem)

        local imgCode = ChaosUtils.GetImgCodeByItemTexture(stolenItem)
        local str = string.format(
            ChaosLocalization.GetString("misc", "robber_steals_item"),
            imgCode, stolenItem:getDisplayName())
        ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
    end
end

function EffectSpawnRobber:OnEnd()
    if self.npc then
        self.npc:Destroy()
        self.npc = nil
    end
end
