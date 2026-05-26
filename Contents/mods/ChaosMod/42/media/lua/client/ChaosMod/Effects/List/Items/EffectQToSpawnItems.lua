---@class EffectQToSpawnItems : ChaosEffectBase
---@field cooldownMs integer
---@field onKeyPressed fun(key: integer)
EffectQToSpawnItems = ChaosEffectBase:derive("EffectQToSpawnItems", "q_to_spawn_items")

local COOLDOWN_MS = 600

function EffectQToSpawnItems:OnStart()
    ChaosEffectBase:OnStart()
    self.cooldownMs = 0
    self.onKeyPressed = function(key) self:HandleKeyPressed(key) end
    Events.OnKeyPressed.Add(self.onKeyPressed)
end

---@param key integer
function EffectQToSpawnItems:HandleKeyPressed(key)
    if key ~= Keyboard.KEY_Q then return end
    if self.cooldownMs > 0 then return end

    local player = getPlayer()
    if not player then return end

    local sq = player:getSquare()
    if not sq then return end

    local itemId = ChaosItems.GetRandomItemId()
    if not itemId then return end

    print("[EffectQToSpawnItems] Spawning item: " .. itemId)

    local item = sq:AddWorldInventoryItem(itemId, 0.5, 0.5, 0)
    if item then
        ChaosPlayer.SayLineNewItem(player, item)
        self.cooldownMs = COOLDOWN_MS
    end
end

---@param deltaMs integer
function EffectQToSpawnItems:OnTick(deltaMs)
    if self.cooldownMs > 0 then
        self.cooldownMs = self.cooldownMs - deltaMs
    end
end

function EffectQToSpawnItems:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.onKeyPressed then
        Events.OnKeyPressed.Remove(self.onKeyPressed)
        self.onKeyPressed = nil
    end
end
