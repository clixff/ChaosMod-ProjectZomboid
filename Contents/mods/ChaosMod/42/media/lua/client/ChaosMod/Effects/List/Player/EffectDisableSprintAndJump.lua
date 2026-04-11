---@class EffectDisableSprintAndJump : ChaosEffectBase
---@field previousSprint boolean
---@field previousRun boolean
---@field previousJump boolean
EffectDisableSprintAndJump = ChaosEffectBase:derive("EffectDisableSprintAndJump", "disable_sprint_and_jump")

function EffectDisableSprintAndJump:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.previousSprint = player:isAllowSprint()
    self.previousRun = player:isAllowRun()
    self.previousIgnoreAutoVault = player:isIgnoreAutoVault()

    player:setAllowRun(false)
    player:setAllowSprint(false)
    player:setIgnoreAutoVault(true)
end

function EffectDisableSprintAndJump:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    player:setAllowRun(self.previousRun)
    player:setAllowSprint(self.previousSprint)
    player:setIgnoreAutoVault(self.previousIgnoreAutoVault)
end
