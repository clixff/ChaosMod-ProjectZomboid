---@class EffectPlayerSaysTips : ChaosEffectBase
---@field timerMs integer
EffectPlayerSaysTips = ChaosEffectBase:derive("EffectPlayerSaysTips", "player_says_tips")

local INTERVAL_MS = 5000

local function sayRandomTip(player)
    local index = ZombRand(1, 60)
    local tip = getText("UI_quick_tip" .. index)
    ChaosPlayer.SayLine(player, tip, 0.3, 0.7, 1.0)
end

function EffectPlayerSaysTips:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    sayRandomTip(player)
    self.timerMs = 0
end

function EffectPlayerSaysTips:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= INTERVAL_MS then
        local player = getPlayer()
        if player then
            sayRandomTip(player)
        end
        self.timerMs = 0
    end
end
