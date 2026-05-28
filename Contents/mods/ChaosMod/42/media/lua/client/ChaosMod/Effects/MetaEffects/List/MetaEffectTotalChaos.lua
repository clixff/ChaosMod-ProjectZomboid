---@class MetaEffectTotalChaos : ChaosMetaEffectBase
---@field originalEffectsInterval number
---@field originalVoteStartTime number
---@field scaledInterval number
MetaEffectTotalChaos = ChaosMetaEffectBase:derive("MetaEffectTotalChaos", "total_chaos")

local DEFAULT_MIN_TIME = 15
local DEFAULT_TIME_MULTIPLIER = 0.5

function MetaEffectTotalChaos:OnStart()
    ChaosMetaEffectBase.OnStart(self)

    local vars = self.variables or {}
    local minTime = tonumber(vars.min_time) or DEFAULT_MIN_TIME
    -- default_config uses "time_multipier" (typo); accept both.
    local timeMultiplier = tonumber(vars.time_multipier) or tonumber(vars.time_multiplier) or DEFAULT_TIME_MULTIPLIER

    self.originalEffectsInterval = ChaosConfig.effects_interval
    self.originalVoteStartTime = ChaosConfig.vote_start_time

    local newEffectsInterval = math.max(minTime, self.originalEffectsInterval * timeMultiplier)
    if newEffectsInterval <= 0 then newEffectsInterval = self.originalEffectsInterval end

    local oldVotingDuration = self.originalEffectsInterval - self.originalVoteStartTime
    local newVotingDuration = math.min(oldVotingDuration, newEffectsInterval)
    local newVoteStartTime = math.max(0, newEffectsInterval - newVotingDuration)

    ChaosConfig.effects_interval = newEffectsInterval
    ChaosConfig.vote_start_time = newVoteStartTime
    self.scaledInterval = newEffectsInterval

    local scale = newEffectsInterval / self.originalEffectsInterval
    ChaosEffectsManager.globalTimerMaxMs = math.floor(newEffectsInterval * 1000)
    ChaosEffectsManager.globalTimerMs = math.floor(ChaosEffectsManager.globalTimerMs * scale)
end

function MetaEffectTotalChaos:OnEnd()
    ChaosMetaEffectBase.OnEnd(self)

    -- Preserve remaining-time semantics: whatever ms are left in the current
    -- (shrunken) interval, keep that same number of ms remaining in the
    -- restored full-length interval.
    local currentMax = ChaosEffectsManager.globalTimerMaxMs
    local currentMs = ChaosEffectsManager.globalTimerMs
    local remainingMs = math.max(0, currentMax - currentMs)

    ChaosConfig.effects_interval = self.originalEffectsInterval
    ChaosConfig.vote_start_time = self.originalVoteStartTime

    local originalMaxMs = math.floor(self.originalEffectsInterval * 1000)
    ChaosEffectsManager.globalTimerMaxMs = originalMaxMs
    ChaosEffectsManager.globalTimerMs = math.max(0, originalMaxMs - remainingMs)
end
