---@class EffectSpawnDoctor : ChaosEffectBase
EffectSpawnDoctor = ChaosEffectBase:derive("EffectSpawnDoctor", "spawn_doctor")

local HEAL_CHECK_INTERVAL_MS = 1000
local HEAL_COOLDOWN_MS = 15000
local HEAL_DISTANCE = 2.0
local HEAL_MAX_COUNT = 5
local DEFAULT_NAME = "The doctor"

---@param zombie IsoZombie
---@return string
local function GetDoctorName(zombie)
    if not zombie then return DEFAULT_NAME end
    local md = zombie:getModData()
    if md and type(md[ChaosNicknames.modDataNameKey]) == "string" and md[ChaosNicknames.modDataNameKey] ~= "" then
        return md[ChaosNicknames.modDataNameKey]
    end
    return DEFAULT_NAME
end

---@param player IsoPlayer
---@return BodyPart[]
local function CollectWoundedBodyParts(player)
    ---@type BodyPart[]
    local candidates = {}
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return candidates end

    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return candidates end

    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part and (part:HasInjury() or part:getHealth() < 100) then
            candidates[#candidates + 1] = part
        end
    end
    return candidates
end

---@param data { zombie: IsoZombie, healsDone: integer, sinceLastHealMs: integer }
local function DoctorHealTick(deltaMs, data)
    data.sinceLastHealMs = data.sinceLastHealMs + deltaMs
end

---@param data { zombie: IsoZombie, healsDone: integer, sinceLastHealMs: integer }
---@return boolean?
local function DoctorHealEnd(data)
    local zombie = data.zombie
    if not zombie or not zombie:isAlive() then return true end

    local player = getPlayer()
    if not player then return true end

    if data.sinceLastHealMs < HEAL_COOLDOWN_MS then return false end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    if dist > HEAL_DISTANCE then return false end

    local candidates = CollectWoundedBodyParts(player)
    if #candidates == 0 then return false end

    local part = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not part then return false end

    part:RestoreToFullHealth()
    local bodyDamage = player:getBodyDamage()
    if bodyDamage then bodyDamage:calculateOverallHealth() end

    data.healsDone = data.healsDone + 1
    data.sinceLastHealMs = 0

    local name = GetDoctorName(zombie)
    local line = string.format("%s healed one wound (%d/%d)", name, data.healsDone, HEAL_MAX_COUNT)
    ChaosPlayer.SayLineByColor(player, line, ChaosPlayerChatColors.green)

    if data.healsDone >= HEAL_MAX_COUNT then
        return true
    end
    return false
end

function EffectSpawnDoctor:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnDoctor] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Doctor",
        100
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.WEAK)
    npc.npcGroup = ChaosNPCGroupID.FOLLOWERS

    ChaosZombie.HumanizeZombie(zombie)

    ChaosZombie.AddZombieClothes(zombie, "Base.Bag_Satchel_Medical", nil, nil, true)

    zombie:resetModelNextFrame()

    ChaosSpecialAction.AddNewAction(
        { zombie = zombie, healsDone = 0, sinceLastHealMs = HEAL_COOLDOWN_MS },
        HEAL_CHECK_INTERVAL_MS,
        DoctorHealTick,
        DoctorHealEnd,
        nil,
        true
    )
end

function EffectSpawnDoctor:OnEnd()
    ChaosEffectBase:OnEnd()
end
