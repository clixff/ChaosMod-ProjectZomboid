---@alias ChaosCourierEffectState
---| "move_to_player"
---| "move_from_player"

---@class ChaosCourierEffectOptions
---@field spawnMinRadius? integer
---@field spawnMaxRadius? integer
---@field outfit? string
---@field itemCount? integer
---@field itemProvider fun(): string?

---@class ChaosCourierEffectData
---@field courierNpc? ChaosNPC
---@field courierZombie? IsoZombie
---@field courierState? ChaosCourierEffectState
---@field courierExitSquare? IsoGridSquare
---@field courierItemCount? integer
---@field courierItemProvider? fun(): string?

---@class ChaosCourierEffectUtils
---@field STATE_MOVE_TO_PLAYER ChaosCourierEffectState
---@field STATE_MOVE_FROM_PLAYER ChaosCourierEffectState
ChaosCourierEffectUtils = ChaosCourierEffectUtils or {}

ChaosCourierEffectUtils.STATE_MOVE_TO_PLAYER = "move_to_player"
ChaosCourierEffectUtils.STATE_MOVE_FROM_PLAYER = "move_from_player"

---@param effect ChaosCourierEffectData
---@param options ChaosCourierEffectOptions
function ChaosCourierEffectUtils.Start(effect, options)
    local player = getPlayer()
    if not player then return end

    local spawnSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
        player,
        0,
        options.spawnMinRadius or 15,
        options.spawnMaxRadius or 25,
        50,
        true,
        false,
        false
    )
    if not spawnSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        spawnSquare:getX(),
        spawnSquare:getY(),
        spawnSquare:getZ(),
        1,
        options.outfit or "Tourist",
        0
    )
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COURIER
    npc:AddTag("effect_move_to_square")

    effect.courierNpc = npc
    effect.courierZombie = zombie
    effect.courierState = ChaosCourierEffectUtils.STATE_MOVE_TO_PLAYER
    npc.effectMoveTargetLocation = player:getSquare()
    effect.courierExitSquare = nil
    effect.courierItemCount = options.itemCount or 1
    effect.courierItemProvider = options.itemProvider
end

---@param effect ChaosCourierEffectData
function ChaosCourierEffectUtils.Destroy(effect)
    if effect.courierNpc and effect.courierNpc.zombie then
        effect.courierNpc:Destroy()
    end

    effect.courierNpc = nil
    effect.courierZombie = nil
    effect.courierState = nil
    effect.courierExitSquare = nil
    effect.courierItemCount = nil
    effect.courierItemProvider = nil
end

---@param effect ChaosCourierEffectData
---@param player IsoPlayer
local function giveItems(effect, player)
    local inventory = player:getInventory()
    if not inventory then return end
    if not effect.courierItemProvider then return end

    for _ = 1, effect.courierItemCount or 1 do
        local itemId = effect.courierItemProvider()
        if itemId then
            local item = inventory:AddItem(itemId)
            if item then
                ChaosPlayer.SayLineNewItem(player, item)
            end
        end
    end
end

---@param effect ChaosCourierEffectData
---@param zombie IsoZombie
---@param square IsoGridSquare
---@return boolean
local function isZombieOnSquare(effect, zombie, square)
    if not effect.courierNpc or not effect.courierNpc.zombie then return false end
    local zombieSquare = zombie:getSquare()
    if not zombieSquare or not square then return false end

    return zombieSquare:getX() == square:getX() and
        zombieSquare:getY() == square:getY() and
        zombieSquare:getZ() == square:getZ()
end

---@param effect ChaosCourierEffectData
function ChaosCourierEffectUtils.Update(effect)
    if not effect.courierNpc or not effect.courierNpc.zombie then return end

    local player = getPlayer()
    if not player then return end

    local zombie = effect.courierNpc.zombie
    local playerSquare = player:getSquare()
    local zombieSquare = zombie:getSquare()
    if not playerSquare or not zombieSquare then return end

    if effect.courierState == ChaosCourierEffectUtils.STATE_MOVE_TO_PLAYER then
        effect.courierNpc.effectMoveTargetLocation = playerSquare

        local sameZ = zombieSquare:getZ() == playerSquare:getZ()
        local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
        if sameZ and dist < 2.0 then
            giveItems(effect, player)

            effect.courierExitSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
                player,
                0,
                10,
                20,
                50,
                true,
                false,
                false
            )

            if not effect.courierExitSquare then
                ChaosCourierEffectUtils.Destroy(effect)
                return
            end

            effect.courierNpc:StopMoving(true, "courier_delivered")
            effect.courierNpc.moveTargetCharacter = nil
            effect.courierNpc.npcGroup = ChaosNPCGroupID.COURIER
            effect.courierNpc.effectMoveTargetLocation = effect.courierExitSquare
            effect.courierState = ChaosCourierEffectUtils.STATE_MOVE_FROM_PLAYER
        end
    elseif effect.courierState == ChaosCourierEffectUtils.STATE_MOVE_FROM_PLAYER then
        if not effect.courierExitSquare then
            ChaosCourierEffectUtils.Destroy(effect)
            return
        end

        if isZombieOnSquare(effect, zombie, effect.courierExitSquare) then
            ChaosCourierEffectUtils.Destroy(effect)
            return
        end

        effect.courierNpc.effectMoveTargetLocation = effect.courierExitSquare
    end
end

return ChaosCourierEffectUtils
