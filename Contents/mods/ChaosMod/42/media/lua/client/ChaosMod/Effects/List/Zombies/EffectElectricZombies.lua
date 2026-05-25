---@class EffectElectricZombies : ChaosEffectBase
EffectElectricZombies = ChaosEffectBase:derive("EffectElectricZombies", "electric_zombies")

---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
local function OnHitZombie(attacker, target, weapon, damage)
    if not target or not attacker then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not instanceof(target, "IsoZombie") then return end
    if ChaosNPCUtils.IsNPC(target) then return end

    ---@cast attacker IsoPlayer
    local square = target:getSquare()
    if square then
        if isServer() then
            playServerSound("chaos_electric_sound", square)
        else
            square:playSound("chaos_electric_sound")
        end

        local cell = getCell()
        if cell then
            local light = IsoLightSource.new(
                square:getX(),
                square:getY(),
                square:getZ(),
                0.5, 0.8, 0.9,
                14,
                6
            )
            cell:addLamppost(light)
        end
    end

    local bodyDamage = attacker:getBodyDamage()
    if bodyDamage then
        bodyDamage:ReduceGeneralHealth(10)
    end

    attacker:setKnockedDown(true)
end

function EffectElectricZombies:OnStart()
    ChaosEffectBase:OnStart()

    Events.OnWeaponHitCharacter.Add(OnHitZombie)
end

function EffectElectricZombies:OnEnd()
    ChaosEffectBase:OnEnd()

    Events.OnWeaponHitCharacter.Remove(OnHitZombie)
end
