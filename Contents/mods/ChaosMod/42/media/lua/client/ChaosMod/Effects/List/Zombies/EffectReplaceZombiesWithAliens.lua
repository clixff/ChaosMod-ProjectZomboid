---@class EffectReplaceZombiesWithAliens : ChaosEffectBase
EffectReplaceZombiesWithAliens = ChaosEffectBase:derive("EffectReplaceZombiesWithAliens", "replace_zombies_with_aliens")

function EffectReplaceZombiesWithAliens:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 90
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if zombie:isDead() then return end
        if zombie:isReanimatedPlayer() then return end

        zombie:setFemaleEtc(false)

        local visual = zombie:getHumanVisual()
        if visual then
            visual:setHairModel("")
            visual:setBeardModel("")
            visual:setSkinTextureName("ChaosAlienMaleBody01")
        end

        local visuals = zombie:getItemVisuals()
        if visuals and visuals:size() > 0 then
            visuals:clear()
            zombie:clearWornItems()
        end

        zombie:resetModelNextFrame()
        updatedCount = updatedCount + 1
    end, true, z)

    print("[EffectReplaceZombiesWithAliens] Updated " .. tostring(updatedCount) .. " zombies")
end

function EffectReplaceZombiesWithAliens:OnEnd()
    ChaosEffectBase:OnEnd()
end
