EffectRemoveMuscleFatigue = ChaosEffectBase:derive("EffectRemoveMuscleFatigue", "remove_muscle_fatigue")

function EffectRemoveMuscleFatigue:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            parts:get(i):setStiffness(0)
        end
    end

    local fitness = player:getFitness()
    if fitness then
        fitness:resetValues()
    end
end
