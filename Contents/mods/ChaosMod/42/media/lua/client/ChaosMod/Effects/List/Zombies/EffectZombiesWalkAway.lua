---@class EffectZombiesWalkAway : ChaosEffectBase
EffectZombiesWalkAway = ChaosEffectBase:derive("EffectZombiesWalkAway", "zombies_walk_away")

local USELESS_DURATION_MS = 10000

function EffectZombiesWalkAway:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ---@type table<integer, {zombie: IsoZombie, pos: { x, y, z } }>
    local objects = {}

    ChaosZombie.ForEachZombieInRange(px, py, 30, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        local zx = zombie:getX()
        local zy = zombie:getY()
        local zz = zombie:getZ()

        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 0.01 then return end

        local nx = dx / dist
        local ny = dy / dist

        local tx = math.floor(zx + nx * 30)
        local ty = math.floor(zy + ny * 30)

        zombie:clearAggroList()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setTarget(nil)
        zombie:setTargetSeenTime(0)

        ChaosZombie.MoveToLocation(zombie, tx, ty, zz, true, true, true, true)

        local iZ = math.floor(zz)

        zombie:setUseless(true)


        zombie:pathToSound(tx, ty, 0)
        zombie:setLastHeardSound(tx, ty, 0)

        table.insert(objects, {
            zombie = zombie,
            pos = { x = tx, y = ty, z = iZ }
        })
    end, true, nil)

    ChaosSpecialAction.AddNewAction({ objects = objects }, USELESS_DURATION_MS,
        function(_deltaMs, data)
            for _, obj in ipairs(data.objects) do
                ---@type IsoZombie
                local zombie = obj.zombie
                if zombie and zombie:isAlive() then
                    zombie:setUseless(true)
                    ---@diagnostic disable-next-line: param-type-mismatch
                    zombie:setTarget(nil)
                    zombie:setTargetSeenTime(0)
                end
            end
        end,
        function(data)
            for _, obj in ipairs(data.objects) do
                local zombie = obj.zombie
                if zombie then
                    zombie:setUseless(false)
                end
            end
        end,
        function(data)
            for _, obj in ipairs(data.objects) do
                local zombie = obj.zombie
                if zombie then
                    zombie:setUseless(false)
                end
            end
        end)
end
