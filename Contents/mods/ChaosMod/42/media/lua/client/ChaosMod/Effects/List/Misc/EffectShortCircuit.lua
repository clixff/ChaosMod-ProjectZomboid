---@class EffectShortCircuit : ChaosEffectBase
EffectShortCircuit = ChaosEffectBase:derive("EffectShortCircuit", "short_circuit")

local RADIUS = 35
local SOUND_RADIUS = 12.0
local KNOCKDOWN_RADIUS = 2.0
local FIRE_CHANCE = 50.0

function EffectShortCircuit:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px, py, pz = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
    local cell = getCell()
    if not cell then return end

    local nearestDist = nil
    local nearestSameZ = false

    local squaresCount = 0

    ---@type table<integer, IsoGridSquare>
    local allSquares = {}


    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        local hasElectronic = false

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            local kind = ChaosProps.GetElectronicKind(obj)
            if kind then
                hasElectronic = true
                if kind == "light_switch" or kind == "lamp" then
                    ---@cast obj IsoLightSwitch
                    if obj:isActivated() then
                        obj:setActive(false)
                    end
                end
            end
        end)

        if hasElectronic and ChaosUtils.RandFloat(0, 100) < FIRE_CHANCE then
            if cell then
                local light = IsoLightSource.new(
                    sq:getX(),
                    sq:getY(),
                    sq:getZ(),
                    0.5, 0.8, 0.9,
                    14,
                    6
                )
                cell:addLamppost(light)
            end

            local dist = ChaosUtils.distTo(px, py, sq:getX(), sq:getY())
            if not nearestDist or dist < nearestDist then
                nearestDist = dist
                nearestSameZ = sq:getZ() == pz
            end

            squaresCount = squaresCount + 1

            table.insert(allSquares, sq)
        end
    end, 0, RADIUS, false, false, true, -1, pz + 2)

    if nearestDist and nearestDist <= SOUND_RADIUS then
        if isServer() then
            playServerSound("chaos_electric_sound", playerSquare)
        else
            playerSquare:playSound("chaos_electric_sound")
        end

        if nearestDist < KNOCKDOWN_RADIUS and nearestSameZ then
            player:setKnockedDown(true)
        end
    end

    local str = string.format("%d objects affected", squaresCount)

    print("str: " .. str)

    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.blue)

    ChaosSpecialAction.AddNewAction({ squares = allSquares }, 2000, nil, function(data)
        local squares = data.squares
        if not squares then return end

        for i = 1, #squares do
            local sq = squares[i]
            if sq then
                print("Starting fire at " .. tostring(sq:getX()) .. ", " .. tostring(sq:getY()))
                IsoFireManager.StartFire(cell, sq, true, 100, 3000)
            end
        end
    end)
end

function EffectShortCircuit:OnEnd()
    ChaosEffectBase:OnEnd()
end
