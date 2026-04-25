---@class EffectTeleportToNearestBasement : ChaosEffectBase
EffectTeleportToNearestBasement = ChaosEffectBase:derive("EffectTeleportToNearestBasement",
    "teleport_to_nearest_basement")

function EffectTeleportToNearestBasement:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    local px, py = square:getX(), square:getY()

    local radius = 100
    ---@type IsoGridSquare | nil
    local bestSq = nil
    local bestDistSq = math.huge

    for dx = -radius, radius do
        for dy = -radius, radius do
            local distSq = dx * dx + dy * dy
            if distSq <= radius * radius and distSq < bestDistSq then
                local sq = cell:getGridSquare(px + dx, py + dy, -1)
                if sq and sq:isSolidFloor() and sq:isFree(false) then
                    bestSq = sq
                    bestDistSq = distSq
                end
            end
        end
    end

    if not bestSq then
        ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "no_basement_found"),
            ChaosPlayerChatColors.red)
        print("[EffectTeleportToNearestBasement] No basement found")
        return
    end

    ChaosPlayer.TeleportPlayer(player, bestSq)
    print(string.format("[EffectTeleportToNearestBasement] Teleported to basement at %d, %d, -1", bestSq:getX(),
        bestSq:getY()))
end
