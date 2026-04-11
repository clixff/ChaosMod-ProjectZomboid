EffectGiveRandomTool = ChaosEffectBase:derive("EffectGiveRandomTool", "give_random_tool")

function EffectGiveRandomTool:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomTool] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = math.floor(ZombRand(1, #TOOL_ITEM_IDS + 1))
    local randomTool = TOOL_ITEM_IDS[randomIndex]
    if not randomTool then return end

    local newItem = inventory:AddItem(randomTool)
    if not newItem then return end


    ChaosPlayer.SayLineNewItem(player, newItem)
end
