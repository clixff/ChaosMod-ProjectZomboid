---@class EffectMedievalPlague : ChaosEffectBase
EffectMedievalPlague = ChaosEffectBase:derive("EffectMedievalPlague", "medieval_plague")

local RAT_COUNT = 10
---@type string[]
local RAT_BREEDS = { "grey", "white" }

function EffectMedievalPlague:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local spawned = 0
    for _ = 1, RAT_COUNT do
        local breed = RAT_BREEDS[ChaosUtils.RandArrayIndex(RAT_BREEDS)]
        if breed then
            local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
            if randomSquare then
                local rat = ChaosAnimals.SpawnAnimal(randomSquare:getX(), randomSquare:getY(), randomSquare:getZ(), "rat",
                    breed)
                if rat then
                    local sa = SpecialAnimal:new(rat)
                    sa.followPlayer = false
                    spawned = spawned + 1
                    rat:pathToCharacter(player)
                end
            end
        end
    end

    local bd = player:getBodyDamage()
    bd:setCatchACold(0)
    bd:setHasACold(true)
    bd:setColdStrength(20)
    bd:setTimeToSneezeOrCough(0)
    bd:TriggerSneezeCough()

    print("[EffectMedievalPlague] Spawned " .. tostring(spawned) .. " rats")
end
