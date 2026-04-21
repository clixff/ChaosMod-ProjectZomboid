EffectSpawnTent = ChaosEffectBase:derive("EffectSpawnTent", "spawn_tent")

---@param square IsoGridSquare
---@return IsoObject?
local function spawnTent(square)
    if not square then return nil end
    return camping.addTent(square, "camping_01_0")
end

function EffectSpawnTent:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
    if not square then return end

    spawnTent(square)
end
