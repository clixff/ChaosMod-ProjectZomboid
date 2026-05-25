---@class EffectElectricWeapons : ChaosEffectBase
EffectElectricWeapons = ChaosEffectBase:derive("EffectElectricWeapons", "electric_weapons")

---@type table<integer, {target: IsoZombie, hitFromBehind: boolean}>
local pendingKnockdowns = {}

local function ProcessPendingKnockdowns()
    if #pendingKnockdowns == 0 then return end

    for i = #pendingKnockdowns, 1, -1 do
        local entry = pendingKnockdowns[i]
        ---@type IsoZombie?
        local target = entry.target
        if target and not target:isDead() and target:getHealth() > 0 then
            target:knockDown(entry.hitFromBehind)
        end
        table.remove(pendingKnockdowns, i)
    end
end

---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
local function OnPlayerHit(attacker, target, weapon, damage)
    if not target or not attacker then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not instanceof(target, "IsoZombie") then return end

    ---@cast target IsoZombie
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

    table.insert(pendingKnockdowns, {
        target = target,
        hitFromBehind = attacker:isBehind(target)
    })

    target:setHealth(target:getHealth() - 0.25)
end

function EffectElectricWeapons:OnStart()
    ChaosEffectBase:OnStart()

    pendingKnockdowns = {}
    Events.OnWeaponHitCharacter.Add(OnPlayerHit)
    Events.OnTick.Add(ProcessPendingKnockdowns)
end

function EffectElectricWeapons:OnEnd()
    ChaosEffectBase:OnEnd()

    pendingKnockdowns = {}
    Events.OnWeaponHitCharacter.Remove(OnPlayerHit)
    Events.OnTick.Remove(ProcessPendingKnockdowns)
end
