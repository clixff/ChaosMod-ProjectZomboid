---@class EffectIgniteRecentPlayerPositions : ChaosEffectBase
EffectIgniteRecentPlayerPositions = ChaosEffectBase:derive("EffectIgniteRecentPlayerPositions",
    "ignite_recent_player_positions")

local MAX_SQUARES = 25
local SAFE_DISTANCE = 2

function EffectIgniteRecentPlayerPositions:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = math.floor(player:getZ())

    local history = ChaosUtils.playerPositionHistory
    if not history then return end

    local cell = getCell()
    if not cell then return end

    local seen = {}
    local picked = 0

    for i = #history, 1, -1 do
        if picked >= MAX_SQUARES then break end

        local entry = history[i]
        if entry then
            local tx = math.floor(entry.x)
            local ty = math.floor(entry.y)
            local tz = math.floor(entry.z)
            local key = tx .. "|" .. ty .. "|" .. tz

            if not seen[key] then
                local skip = false
                if tz == playerZ and ChaosUtils.distTo(playerX, playerY, entry.x, entry.y) < SAFE_DISTANCE then
                    skip = true
                end

                if not skip then
                    local sq = cell:getGridSquare(tx, ty, tz)
                    if sq then
                        seen[key] = true
                        picked = picked + 1
                        IsoFireManager.StartFire(cell, sq, true, 100, 3000)
                    end
                end
            end
        end
    end
end

function EffectIgniteRecentPlayerPositions:OnEnd()
    ChaosEffectBase:OnEnd()
end
