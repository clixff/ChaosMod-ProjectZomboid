---@class EffectQuestKillZombies : ChaosEffectBase
---@field killCount integer
---@field finished boolean
EffectQuestKillZombies = ChaosEffectBase:derive("EffectQuestKillZombies", "quest_kill_zombies")

local REQUIRED_KILLS = 4
local QUEST_PROGRESS_COLOR = { r = 1.0, g = 0.84, b = 0.0 }

---@type EffectQuestKillZombies?
local activeEffect = nil

---@param player IsoPlayer
local function RewardPlayer(player)
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local coinItem = nil
    for _ = 1, 10 do
        coinItem = inventory:AddItem("Base.SilverCoin")
    end

    if coinItem then
        ChaosPlayer.SayLineNewItem(player, coinItem, 10)
    end

    for _ = 1, 2 do
        local itemType = GetRandomLootboxItem()
        if itemType then
            local rewardItem = inventory:AddItem(itemType)
            if rewardItem then
                ChaosPlayer.SayLineNewItem(player, rewardItem)
            end
        end
    end
end

---@param zombie IsoZombie
local function OnZombieDead(zombie)
    if not zombie then return end
    if not activeEffect then return end
    if activeEffect.finished then return end
    if ChaosNPCUtils.IsNPC(zombie) then return end

    local lastAttacker = zombie:getAttackedBy()
    if not lastAttacker then return end
    if not instanceof(lastAttacker, "IsoPlayer") then return end

    activeEffect.killCount = activeEffect.killCount + 1

    if activeEffect.killCount < REQUIRED_KILLS then
        ChaosPlayer.SayLineByColor(lastAttacker,
            string.format("Zombie: %d/%d", activeEffect.killCount, REQUIRED_KILLS),
            QUEST_PROGRESS_COLOR)
        return
    end

    activeEffect.finished = true
    ChaosUtils.PlayUISound("chaos_quest_complete")
    RewardPlayer(lastAttacker)
    ChaosEffectsManager.DisableSpecificEffects({ "quest_kill_zombies" })
end

function EffectQuestKillZombies:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectQuestKillZombies] OnStart " .. tostring(self.effectId))

    self.killCount = 0
    self.finished = false
    activeEffect = self

    ChaosUtils.PlayUISound("chaos_quest_start")
    Events.OnZombieDead.Add(OnZombieDead)
end

function EffectQuestKillZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnZombieDead.Remove(OnZombieDead)

    if activeEffect == self then
        activeEffect = nil
    end
end
