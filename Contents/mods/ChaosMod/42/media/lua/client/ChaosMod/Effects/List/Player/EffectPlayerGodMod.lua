---@class EffectPlayerGodMod : ChaosEffectBase
---@field previousGodMod boolean
EffectPlayerGodMod = ChaosEffectBase:derive("EffectPlayerGodMod", "player_god_mod")

function EffectPlayerGodMod:CurePlayerInfection(player)
    local bd = player:getBodyDamage()
    if bd then
        bd:setInfected(false)
        bd:setIsFakeInfected(false)
        bd:setInfectionTime(-1)
        bd:setInfectionMortalityDuration(-1)
        local bodyParts = bd:getBodyParts()
        if bodyParts then
            for i = 0, bodyParts:size() - 1 do
                local part = bodyParts:get(i)
                if part then
                    part:SetInfected(false)
                    part:SetFakeInfected(false)
                    part:SetBitten(false)
                end
            end
        end
    end

    local stats = player:getStats()
    if stats then
        stats:reset(CharacterStat.getById("ZombieInfection"))
        stats:reset(CharacterStat.getById("ZombieFever"))
    end
end

function EffectPlayerGodMod:KeepPlayerSafe(player)
    if not player then return end

    player:setGodMod(true, true)
    player:setInvulnerable(true)

    local bd = player:getBodyDamage()
    if bd then
        bd:RestoreToFullHealth()
    end

    local stats = player:getStats()
    if stats then
        stats:reset(CharacterStat.HUNGER)
        stats:reset(CharacterStat.THIRST)
        stats:reset(CharacterStat.FATIGUE)
        stats:reset(CharacterStat.PAIN)
        stats:reset(CharacterStat.PANIC)
        stats:reset(CharacterStat.STRESS)
        stats:reset(CharacterStat.SICKNESS)
        stats:reset(CharacterStat.FOOD_SICKNESS)
        stats:reset(CharacterStat.POISON)
        stats:reset(CharacterStat.ZOMBIE_FEVER)
        stats:reset(CharacterStat.ZOMBIE_INFECTION)

        stats:set(CharacterStat.ENDURANCE, 1.0)
        stats:set(CharacterStat.MORALE, 1.0)
        stats:set(CharacterStat.SANITY, 1.0)
    end

    self:CurePlayerInfection(player)
end

function EffectPlayerGodMod:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    self.previousGodMod = player:isGodMod()

    self.onPlayerUpdate = function(p)
        if p == getPlayer() then
            self:KeepPlayerSafe(p)
        end
    end

    Events.OnPlayerUpdate.Add(self.onPlayerUpdate)

    self:KeepPlayerSafe(player)
end

function EffectPlayerGodMod:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.onPlayerUpdate then
        Events.OnPlayerUpdate.Remove(self.onPlayerUpdate)
        self.onPlayerUpdate = nil
    end

    local player = getPlayer()
    if not player then return end

    player:setGodMod(self.previousGodMod or false, true)
    player:setInvulnerable(self.previousGodMod or false)
end
