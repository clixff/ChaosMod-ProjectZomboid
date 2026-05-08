local BONFIRE_COLOR = { r = 1.0, g = 0.84, b = 0.2 }

EffectDarkSoulsBonfire = ChaosEffectBase:derive("EffectDarkSoulsBonfire", "dark_souls_bonfire")

function EffectDarkSoulsBonfire:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local targetSquare = nil
    local x = playerSquare:getX()
    local y = playerSquare:getY()
    local z = playerSquare:getZ()

    ChaosUtils.GetTilesBFS_2D(x, y, function(sq)
        if sq and sq:isFree(false) then
            targetSquare = sq
            return true
        end
    end, 1, 10, true, true, true, z, z)

    if not targetSquare then return end
    if not ChaosProps.SpawnCampfire(targetSquare) then return end

    ChaosPlayer.SayLineByColor(player, "Bonfire Lit", BONFIRE_COLOR)
    ChaosUtils.PlayUISound("bonfire_lit")

    local item = instanceItem("Base.Sword")
    if item then
        local placedItem = targetSquare:AddWorldInventoryItem(item, 0.5, 0.5, 0.5, false)
        if placedItem then
            placedItem:setWorldXRotation(0)
            placedItem:setWorldYRotation(270)
            placedItem:setWorldZRotation(0)

            local worldObj = placedItem:getWorldItem()
            if worldObj then
                worldObj:setOffX(0.5)
                worldObj:setOffY(0.5)
                worldObj:setOffZ(0.5)
                worldObj:setExtendedPlacement(true)
                worldObj:syncExtendedPlacement()
            end
        end
    end

    local bd = player:getBodyDamage()
    local stats = player:getStats()
    bd:RestoreToFullHealth()
    bd:setInfected(false)
    bd:setIsFakeInfected(false)
    bd:setInfectionTime(-1)
    bd:setInfectionMortalityDuration(-1)

    local bodyParts = bd:getBodyParts()
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part then
                part:SetInfected(false)
                part:SetFakeInfected(false)
                part:SetBitten(false)
            end
        end
    end

    stats:reset(CharacterStat.getById("ZombieInfection"))
    stats:reset(CharacterStat.getById("ZombieFever"))

    ChaosPlayer.SayLineByColor(player, "Player is healed", ChaosPlayerChatColors.green)

    local countReanimated = 0
    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local objects = sq:getStaticMovingObjects()
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                if instanceof(obj, "IsoDeadBody") then
                    local deadBody = obj
                    ---@diagnostic disable-next-line: undefined-field
                    local canReanimate = deadBody["reanimate"]
                    if canReanimate then
                        ---@diagnostic disable-next-line: undefined-field
                        deadBody:reanimate()
                        countReanimated = countReanimated + 1
                    end
                end
            end
        end
    end, 0, 90, false, false, true, z - 1, z + 2)

    ChaosPlayer.SayLineByColor(player, "Zombies were revived", ChaosPlayerChatColors.red)
    print("[EffectDarkSoulsBonfire] Reanimated " .. tostring(countReanimated) .. " zombies")
end
