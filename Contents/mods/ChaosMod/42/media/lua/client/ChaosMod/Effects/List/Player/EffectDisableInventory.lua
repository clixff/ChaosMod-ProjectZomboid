---@class EffectDisableInventory : ChaosEffectBase
---@field wasInvVisible boolean
---@field wasLootVisible boolean
EffectDisableInventory = ChaosEffectBase:derive("EffectDisableInventory", "disable_inventory")

local playerNum = 0

function EffectDisableInventory:OnStart()
    ChaosEffectBase:OnStart()
    local inv = getPlayerInventory(playerNum)
    local loot = getPlayerLoot(playerNum)
    self.wasInvVisible = inv ~= nil and inv:isVisible()
    self.wasLootVisible = loot ~= nil and loot:isVisible()
    if inv then inv:setVisible(false) end
    if loot then loot:setVisible(false) end
end

function EffectDisableInventory:OnTick(_deltaMs)
    local inv = getPlayerInventory(playerNum)
    local loot = getPlayerLoot(playerNum)
    if inv then inv:setVisible(false) end
    if loot then loot:setVisible(false) end
end

function EffectDisableInventory:OnEnd()
    ChaosEffectBase:OnEnd()
    local inv = getPlayerInventory(playerNum)
    local loot = getPlayerLoot(playerNum)
    if inv then inv:setVisible(self.wasInvVisible) end
    if loot then loot:setVisible(self.wasLootVisible) end
end
