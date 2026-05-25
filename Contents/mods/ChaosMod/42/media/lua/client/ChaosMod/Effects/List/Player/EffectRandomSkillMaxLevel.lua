---@class EffectRandomSkillMaxLevel : ChaosEffectBase
EffectRandomSkillMaxLevel = ChaosEffectBase:derive("EffectRandomSkillMaxLevel", "random_skill_max_level")

function EffectRandomSkillMaxLevel:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local perk = SKILL_EXP_IDS[ChaosUtils.RandArrayIndex(SKILL_EXP_IDS)]
    if not perk then return end

    while player:getPerkLevel(perk) < 10 do
        player:LevelPerk(perk, false)
    end

    local str = string.format(ChaosLocalization.GetString("misc", "skill_maxed_out"), perk:getName())
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
end

function EffectRandomSkillMaxLevel:OnEnd()
    ChaosEffectBase:OnEnd()
end
