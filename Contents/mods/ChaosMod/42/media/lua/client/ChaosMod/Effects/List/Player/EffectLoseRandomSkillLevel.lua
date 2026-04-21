EffectLoseRandomSkillLevel = ChaosEffectBase:derive("EffectLoseRandomSkillLevel", "random_skill_level_lose")

function EffectLoseRandomSkillLevel:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local randomIndex = math.floor(ZombRand(1, #SKILL_EXP_IDS + 1))
    local perk = SKILL_EXP_IDS[randomIndex]
    if not perk then return end

    player:LoseLevel(perk)

    local str = (string.format(ChaosLocalization.GetString("misc", "skill_level_down"), perk:getName()))
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.red)
end
