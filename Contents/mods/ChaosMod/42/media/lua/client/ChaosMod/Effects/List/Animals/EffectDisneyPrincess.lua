---@class EffectDisneyPrincess : ChaosEffectBase
EffectDisneyPrincess = ChaosEffectBase:derive("EffectDisneyPrincess", "disney_princess")

local ANIMALS_TO_SPAWN = {
    { type = "cowcalf",     breed = "holstein",    count = 1 },
    { type = "chick",       breed = "rhodeisland", count = 3 },
    { type = "fawn",        breed = "whitetailed", count = 2 },
    { type = "doe",         breed = "whitetailed", count = 1 },
    { type = "mousepups",   breed = "deer",        count = 2 },
    { type = "piglet",      breed = "landrace",    count = 1 },
    { type = "rabkitten",   breed = "appalachian", count = 2 },
    { type = "raccoonkit",  breed = "grey",        count = 1 },
    { type = "lamb",        breed = "friesian",    count = 1 },
    { type = "turkeypoult", breed = "meleagris",   count = 1 },
}

local MIN_RADIUS = 1
local MAX_RADIUS = 6
local MAX_TRIES = 50

function EffectDisneyPrincess:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local spawned = 0

    for _, entry in ipairs(ANIMALS_TO_SPAWN) do
        for _ = 1, entry.count do
            local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_RADIUS, MAX_RADIUS, MAX_TRIES, true,
                true, true)
            if square then
                local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), entry.type,
                    entry.breed)
                if animal then
                    spawned = spawned + 1
                end
            end
        end
    end

    print("[EffectDisneyPrincess] Spawned " .. tostring(spawned) .. " animals")
end
