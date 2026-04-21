---@class EffectSpawnItemOnWalk : ChaosEffectBase
---@field checkIntervalMs integer
---@field lastSquareX integer
---@field lastSquareY integer
EffectSpawnItemOnWalk = ChaosEffectBase:derive("EffectSpawnItemOnWalk", "spawn_item_on_walk")

local CHECK_INTERVAL_MS = 1000

function EffectSpawnItemOnWalk:OnStart()
    ChaosEffectBase:OnStart()
    self.checkIntervalMs = 0

    local player = getPlayer()
    if player then
        local sq = player:getSquare()
        self.lastSquareX = sq and sq:getX() or -1
        self.lastSquareY = sq and sq:getY() or -1
    end
end

---@param deltaMs integer
function EffectSpawnItemOnWalk:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    self.checkIntervalMs = self.checkIntervalMs + deltaMs
    if self.checkIntervalMs < CHECK_INTERVAL_MS then return end
    self.checkIntervalMs = self.checkIntervalMs - CHECK_INTERVAL_MS

    local sq = player:getSquare()
    if not sq then return end

    local x, y = sq:getX(), sq:getY()
    if x == self.lastSquareX and y == self.lastSquareY then return end

    self.lastSquareX = x
    self.lastSquareY = y

    local itemId = ChaosItems.GetRandomItemId()
    if not itemId then return end

    local item = sq:AddWorldInventoryItem(itemId, 0.5, 0.5, 0)

    if item then
        ChaosPlayer.SayLineNewItem(player, item)
    end
end

function EffectSpawnItemOnWalk:OnEnd()
    ChaosEffectBase:OnEnd()
end
