EffectHealRandomWound = ChaosEffectBase:derive("EffectHealRandomWound", "heal_random_wound")

function EffectHealRandomWound:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return end

    ---@type BodyPart[]
    local candidates = {}
    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part and (part:HasInjury() or part:getHealth() < 100) then
            candidates[#candidates + 1] = part
        end
    end

    if #candidates == 0 then return end

    local part = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not part then return end

    part:RestoreToFullHealth()
    bodyDamage:calculateOverallHealth()

    ChaosPlayer.SayLineByColor(player, string.format("Healed %s", bodyDamage:getBodyPartName(part:getType())),
        ChaosPlayerChatColors.green)
end
