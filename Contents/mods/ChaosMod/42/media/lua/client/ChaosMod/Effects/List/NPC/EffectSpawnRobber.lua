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

    local inventory = player:getInventory()
    local allItems = {}
    local invItems = inventory:getItems()
    for i = 0, invItems:size() - 1 do
        local it = invItems:get(i)
        if it and not it:IsInventoryContainer() then
            table.insert(allItems, it)
        end
    end
    if #allItems == 0 then return end

    local index = math.floor(ZombRand(1, #allItems + 1))
    local stolenItem = allItems[index]
    if not stolenItem then return end
    local worn = player:getWornItems()
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

function EffectSpawnRobber:OnEnd()
    if self.npc then
        self.npc:Destroy()
        self.npc = nil
    end
end
