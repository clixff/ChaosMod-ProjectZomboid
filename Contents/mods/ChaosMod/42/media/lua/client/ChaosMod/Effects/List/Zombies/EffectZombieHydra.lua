---@class EffectZombieHydra : ChaosEffectBase
EffectZombieHydra = ChaosEffectBase:derive("EffectZombieHydra", "zombie_hydra")

---@param zombie IsoZombie
local function OnZombieDead(zombie)
    if not zombie then return end
    if ChaosNPCUtils.IsNPC(zombie) then return end

    local zx = zombie:getX()
    local zy = zombie:getY()
    local zz = zombie:getZ()

    ---@type IsoGridSquare[]
    local candidates = {}
    ChaosUtils.SquareRingSearchTile_2D(math.floor(zx), math.floor(zy), function(sq)
        if sq then
            candidates[#candidates + 1] = sq
        end
    end, 2, 4, true, true, true, math.floor(zz), math.floor(zz))

    if #candidates == 0 then return end

    local spawnSquare = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not spawnSquare then return end
    local femaleChance = zombie:isFemale() and 100 or 0

    local clones = ChaosZombie.SpawnZombieAt(spawnSquare:getX(), spawnSquare:getY(), spawnSquare:getZ(), 1, "Tourist",
        femaleChance)
    if not clones or clones:size() == 0 then return end

    local clone = clones:getFirst()
    if not clone then return end

    ChaosZombie.CopyAppearanceToNormalZombie(zombie, clone)
end

function EffectZombieHydra:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnZombieDead.Add(OnZombieDead)
end

function EffectZombieHydra:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnZombieDead.Remove(OnZombieDead)
end
