ChaosZombie = ChaosZombie or {}

---@param player IsoGameCharacter
---@param zombie IsoZombie
---@param checkLightLevel boolean
---@param doLineTrace boolean
---@return boolean
function ChaosZombie.CanPlayerSeeZombie(player, zombie, checkLightLevel, doLineTrace)
    if not player or not zombie then
        return false
    end

    if ChaosMod.wallhack then
        return true
    end
    local isCulled = zombie:isSceneCulled()
    if isCulled then
        return false
    end

    local zombieSquare = zombie:getSquare()
    -- Check if player can see square where zombie is located
    local squareCanSee = zombieSquare:isCanSee(0)
    if squareCanSee == false then
        return false
    end
    if checkLightLevel then
        local lightLevel = zombieSquare:getLightLevel(0)
        local lightLevelThreshold = 0.2
        if lightLevel < lightLevelThreshold then
            return false
        end
    end
    if doLineTrace then
        local canSeeLineTrace = ChaosZombie.CanPlayerSeeZombieLineTrace(player, zombie)
        if canSeeLineTrace == false then
            return false
        end
    end
    return true
end

--- Spawns zombies at the given position
---@param x number
---@param y number
---@param z number
---@param totalZombies integer
---@param outfit string
---@param femaleChance? integer
---@return ArrayList<IsoZombie>
function ChaosZombie.SpawnZombieAt(x, y, z, totalZombies, outfit, femaleChance)
    local x1 = math.floor(x)
    local y1 = math.floor(y)
    local z1 = math.floor(z)
    local femaleChance = femaleChance or 50
    local zombies = addZombiesInOutfit(x1, y1, z1, totalZombies, outfit, femaleChance)
    return zombies
end

---@param player IsoGameCharacter
---@param zombie IsoZombie
---@return boolean
function ChaosZombie.CanPlayerSeeZombieLineTrace(player, zombie)
    local playerSquare = player:getSquare()
    local playerX = playerSquare:getX()
    local playerY = playerSquare:getY()
    local playerZ = playerSquare:getZ()
    local playerCell = playerSquare:getCell()

    local zombieSquare = zombie:getSquare()
    local zombieX = zombieSquare:getX()
    local zombieY = zombieSquare:getY()
    local zombieZ = zombieSquare:getZ()
    local lineTrace = LosUtil.lineClear(playerCell, playerX, playerY, playerZ, zombieX, zombieY, zombieZ, false)
    local resultString = tostring(lineTrace)
    return resultString == "Clear"
end

---@param zombie IsoZombie
function ChaosZombie.HumanizeZombie(zombie)
    if not zombie then return end

    local humanVisual = zombie:getHumanVisual()
    if not humanVisual then
        print("[ChaosZombie] Failed to get human visual")
        return
    end
    humanVisual:setSkinTextureName(zombie:isFemale() and "FemaleBody03" or "MaleBody03")
    humanVisual:removeBlood()
    humanVisual:removeDirt()

    local bloodBodyPartsMaxIndex = BloodBodyPartType.MAX:index()
    -- Remove blood from body
    for i = 0, bloodBodyPartsMaxIndex - 1 do
        local bodyPart = BloodBodyPartType.FromIndex(i)
        humanVisual:setBlood(bodyPart, 0)
        humanVisual:setDirt(bodyPart, 0)
    end

    local itemVisuals = zombie:getItemVisuals()

    -- Remove blood from clothes and items
    for i = 0, itemVisuals:size() - 1 do
        local item = itemVisuals:get(i)
        if item then
            for j = 0, bloodBodyPartsMaxIndex - 1 do
                local part = BloodBodyPartType.FromIndex(j)
                item:setDirt(part, 0)
                item:setBlood(part, 0)
                item:removeHole(j)
            end
        end
    end
end

---@param zombie IsoZombie
function ChaosZombie.OnZombieDead(zombie)
    -- Return early if zombie is not valid
    if not zombie then return end
    -- Return early if mod is not enabled
    if ChaosMod.enabled == false then
        return
    end

    -- Find who killed the zombie
    local killer = zombie:getAttackedBy()
    -- Return early if killer is not valid
    if not killer then
        return
    end

    -- If setting for saying killed zombie name is enabled
    if ChaosConfig.IsKilledZombieNameEnabled() then
        local name, color = ChaosNicknames.ensureZombieNicknameAndColor(zombie)
        if name and instanceof(killer, "IsoPlayer") then
            local stringToSay = string.format(ChaosLocalization.GetString("misc", "killed_zombie"), name)
            ChaosPlayer.SayLineByColor(killer, stringToSay, ChaosPlayerChatColors.removedItem)
        end
    end

    -- Adoring fans react when player kills any zombie
    if instanceof(killer, "IsoPlayer") then
        local adoringFans = ChaosNPCUtils.GetNPCsWithTag("adoring_fan")
        if adoringFans and #adoringFans > 0 then
            ---@type string[]
            local phrases = { "Wow!", "Cool!", "Amazing!", "Incredible!", "Awesome!" }
            for _, fan in ipairs(adoringFans) do
                local phrase = phrases[math.floor(ZombRand(#phrases) + 1)]
                if phrase then
                    fan:SayDebug(phrase)
                end
            end
        end
    end
end

---@param character IsoGameCharacter
---@param zombie IsoZombie
function ChaosZombie.CopyCharacterVisualsAndClothes(character, zombie)
    if not character or not zombie then return end

    -- local previousReanimatedPlayer = false

    if instanceof(character, "IsoZombie") then
        ---@type IsoZombie
        local zombieCharacter = character
        -- previousReanimatedPlayer = zombieCharacter:isReanimatedPlayer()
        -- zombieCharacter:setReanimatedPlayer(true)
    end

    -- zombie:setReanimatedPlayer(true)
    zombie:setFemaleEtc(character:isFemale())

    -- Copy body / face / hair / skin visual
    local playerVisual = character:getVisual()
    local zombieVisual = zombie:getVisual()
    if playerVisual and zombieVisual then
        zombieVisual:copyFrom(playerVisual)
    end


    -- Keep descriptor visual in sync
    local playerDesc = character:getDescriptor()
    local zombieDesc = zombie:getDescriptor()
    if playerDesc and zombieDesc then
        local playerDescVisual = playerDesc:getHumanVisual()
        local zombieDescVisual = zombieDesc:getHumanVisual()
        if playerDescVisual and zombieDescVisual then
            zombieDescVisual:copyFrom(playerDescVisual)
        end
    end

    -- BUG 1 FIX: vanilla zombies store clothes in itemVisuals, not wornItems.
    -- setReanimatedPlayer(true) makes getItemVisuals() read from wornItems (empty!),
    -- so we must convert BEFORE touching setReanimatedPlayer on the source.
    if instanceof(character, "IsoZombie") then
        ---@type IsoZombie
        local characterAsZombie = character
        if not characterAsZombie:isReanimatedPlayer() then
            local srcWorn = characterAsZombie:getWornItems()
            local srcVisuals = characterAsZombie:getItemVisuals() -- returns itemVisuals while NOT reanimated
            srcWorn:setFromItemVisuals(srcVisuals)                -- converts visual → actual WornItem objects
        end
    end

    local zombieWorn = zombie:getWornItems()
    if zombieWorn then
        -- backward loop
        for i = zombieWorn:size() - 1, 0, -1 do
            local wornItem = zombieWorn:getItemByIndex(i)
            if wornItem then
                local slot = zombieWorn:getLocation(wornItem)
                if slot then
                    pcall(function() wornItem:removeFromWorld() end)
                    -- Clear slot in zombie worn items
                    ---@diagnostic disable-next-line: param-type-mismatch
                    pcall(function() zombieWorn:setItem(slot, nil) end)
                end
            end
        end
    end

    local zombieInventory = zombie:getInventory()
    local zombieItems = zombieInventory:getItems()

    -- Backward loop in zombie inventory items to delete everything
    for i = zombieItems:size() - 1, 0, -1 do
        local item = zombieItems:get(i)
        if item then
            pcall(function() zombieInventory:Remove(item) end)
            pcall(function() item:removeFromWorld() end)
        end
    end

    local playerWorn = character:getWornItems()
    if playerWorn then
        for i = 0, playerWorn:size() - 1 do
            local wornItem = playerWorn:getItemByIndex(i)
            if wornItem then
                local location = playerWorn:getLocation(wornItem)
                if location then
                    local condition = wornItem:getCondition()
                    local newItem = zombieInventory:AddItem(wornItem:getFullType())
                    if newItem then
                        newItem:getVisual():copyVisualFrom(wornItem:getVisual())

                        if wornItem:isCustomColor() then
                            newItem:setColor(wornItem:getColor())
                            newItem:setCustomColor(true)
                        end

                        newItem:setCondition(condition)
                        zombie:setWornItem(location, newItem)
                    end
                end
            end
        end
    end

    zombie:onWornItemsChanged()
    zombie:resetModelNextFrame()

    if instanceof(character, "IsoZombie") then
        ---@type IsoZombie
        local zombieCharacter = character
        -- zombieCharacter:setReanimatedPlayer(previousReanimatedPlayer)
    end

    zombie:setReanimatedPlayer(true)
end

---@param x number
---@param y number
---@param maxDist number
---@param skipNPC boolean?
---@param z number? -- If nil, then return all zombies in all Z levels
---@return ArrayList<IsoZombie>
function ChaosZombie.GetNearestZombies(x, y, maxDist, skipNPC, z)
    skipNPC = skipNPC or false
    local zombies = ArrayList:new()
    local cell = getCell()
    if not cell then return zombies end
    local allZombies = cell:getZombieList()
    if not allZombies then return zombies end
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and zombie:isAlive() then
            local x2 = zombie:getX()
            local y2 = zombie:getY()
            local z2 = zombie:getZ()
            if ChaosUtils.isInRange(x, y, x2, y2, maxDist) then
                local shouldAdd = true
                if skipNPC and ChaosNPCUtils.IsNPC(zombie) then
                    shouldAdd = false
                end
                if z ~= nil and math.abs(z2 - z) > 0.5 then
                    shouldAdd = false
                end

                if shouldAdd then
                    zombies:add(zombie)
                end
            end
        end
    end
    return zombies
end

---@param x number
---@param y number
---@param maxDist number
---@param callback fun(zombie: IsoZombie)
---@param skipNPC boolean?
---@param z number? -- If nil, then return all zombies in all Z levels
function ChaosZombie.ForEachZombieInRange(x, y, maxDist, callback, skipNPC, z)
    skipNPC = skipNPC or false
    if not callback then return end
    local cell = getCell()
    if not cell then return end
    local allZombies = cell:getZombieList()
    if not allZombies then return end
    -- backward loop
    for i = allZombies:size() - 1, 0, -1 do
        local zombie = allZombies:get(i)
        if zombie and zombie:isAlive() then
            local x2 = zombie:getX()
            local y2 = zombie:getY()
            local z2 = zombie:getZ()
            if ChaosUtils.isInRange(x, y, x2, y2, maxDist) then
                local isValid = true

                if skipNPC and ChaosNPCUtils.IsNPC(zombie) then
                    isValid = false
                end

                if z ~= nil and math.abs(z2 - z) > 0.5 then
                    isValid = false
                end
                if isValid then
                    callback(zombie)
                end
            end
        end
    end
end

---@param inventory ItemContainer
local function removeAllWeapons(inventory)
    if not inventory then return end

    local items = inventory:getItems()
    if not items then return end

    -- backward loop
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and item:IsWeapon() then
            pcall(function() item:Remove() end)
        end
    end
end

---@param character IsoGameCharacter
function ChaosZombie.RemoveAllWeapons(character)
    if not character then return end

    local inventory = character:getInventory()
    if not inventory then return end

    removeAllWeapons(inventory)
end

---@param zombie IsoZombie
---@param x number
---@param y number
---@param z number
---@param clearTarget boolean?
---@param resetPath boolean?
---@param faceLocation boolean?
---@param setTurnAlerted boolean?
function ChaosZombie.MoveToLocation(zombie, x, y, z, clearTarget, resetPath, faceLocation, setTurnAlerted)
    if not zombie then return end
    if clearTarget == nil then clearTarget = true end
    if resetPath == nil then resetPath = true end
    if faceLocation == nil then faceLocation = false end
    if setTurnAlerted == nil then setTurnAlerted = true end

    if clearTarget then
        zombie:clearAggroList()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setTarget(nil)
    end

    if resetPath then
        zombie:getPathFindBehavior2():reset()
        zombie:getPathFindBehavior2():cancel()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
    end

    if faceLocation then
        zombie:faceLocation(x, y)
    end

    local x2, y2, z2 = math.floor(x), math.floor(y), math.floor(z)

    if setTurnAlerted then
        zombie:setTurnAlertedValues(x2, y2)
    end

    zombie:getPathFindBehavior2():pathToLocation(x2, y2, z2)
end

---@param x number
---@param y number
---@param skipNPC boolean?
---@return IsoZombie?
function ChaosZombie.GetNearestZombie(x, y, skipNPC)
    skipNPC = skipNPC or false
    local cell = getCell()
    if not cell then return end
    local allZombies = cell:getZombieList()
    local nearestZombie = nil
    local nearestDist = 0.0
    if not allZombies then return end
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and zombie:isAlive() then
            local allowUsing = true

            if skipNPC and ChaosNPCUtils.IsNPC(zombie) then
                allowUsing = false
            end

            if allowUsing then
                local x2 = zombie:getX()
                local y2 = zombie:getY()
                local dist = ChaosUtils.distTo(x, y, x2, y2)
                if not nearestZombie or dist < nearestDist then
                    nearestZombie = zombie
                    nearestDist = dist
                end
            end
        end
    end
    return nearestZombie
end
