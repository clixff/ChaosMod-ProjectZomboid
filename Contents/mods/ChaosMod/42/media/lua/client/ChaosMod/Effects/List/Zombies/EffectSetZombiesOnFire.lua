EffectSetZombiesOnFire = ChaosEffectBase:derive("EffectSetZombiesOnFire", "set_zombies_on_fire")

function EffectSetZombiesOnFire:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    local cell = getCell()

    local countReanimated = 0

    local zombies = cell:getZombieList()

    local radius = 15

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local x2 = zombie:getX()
            local y2 = zombie:getY()

            if ChaosUtils.isInRange(x, y, x2, y2, radius) then
                zombie:SetOnFire()
            end
        end
    end

    print("[EffectSetZombiesOnFire] Set " .. tostring(countReanimated) .. " zombies on fire")
end
