---@class EffectShorterEffectsInterval : ChaosEffectBase
---@field originalEffectsInterval number
---@field originalVoteStartTime number
EffectShorterEffectsInterval = ChaosEffectBase:derive("EffectShorterEffectsInterval", "shorter_effects_interval")

function EffectShorterEffectsInterval:OnStart()
    ChaosEffectBase:OnStart()

    self.originalEffectsInterval = ChaosConfig.effects_interval
    self.originalVoteStartTime = ChaosConfig.vote_start_time

    local newEffectsInterval = self.originalEffectsInterval * 0.5
    local oldVotingDuration = self.originalEffectsInterval - self.originalVoteStartTime
    local newVotingDuration = math.min(oldVotingDuration, newEffectsInterval)
    local newVoteStartTime = math.max(0, newEffectsInterval - newVotingDuration)

    ChaosConfig.effects_interval = newEffectsInterval
    ChaosConfig.vote_start_time = newVoteStartTime

    local scale = newEffectsInterval / self.originalEffectsInterval
    ChaosEffectsManager.globalTimerMaxMs = math.floor(newEffectsInterval * 1000)
    ChaosEffectsManager.globalTimerMs = math.floor(ChaosEffectsManager.globalTimerMs * scale)
end

function EffectShorterEffectsInterval:OnEnd()
    ChaosEffectBase:OnEnd()

    local scale = self.originalEffectsInterval / ChaosConfig.effects_interval
    ChaosConfig.effects_interval = self.originalEffectsInterval
    ChaosConfig.vote_start_time = self.originalVoteStartTime
    ChaosEffectsManager.globalTimerMaxMs = math.floor(self.originalEffectsInterval * 1000)
    ChaosEffectsManager.globalTimerMs = math.floor(ChaosEffectsManager.globalTimerMs * scale)
end
