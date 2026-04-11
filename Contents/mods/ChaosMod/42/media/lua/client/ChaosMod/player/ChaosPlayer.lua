---@class ChaosPlayer
---@field hitStunLastTimeMs? integer
ChaosPlayer = ChaosPlayer or {}

---@param player IsoPlayer
---@param dropHandItems boolean
function ChaosPlayer.DropAllItemsOnGround(player, dropHandItems)
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end

    local items = inv:getItems()
    if not items then return end

    local wornItems = player:getWornItems()

    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)
        if item then
            pcall(function() wornItems:remove(item) end)
        end
    end

    -- Copy first
    ---@type table<integer, InventoryItem>
    local list = {}
    for i = 0, items:size() - 1 do
        list[#list + 1] = items:get(i)
    end

    if dropHandItems then
        player:dropHandItems()
    end

    local sq = player:getSquare()
    if not sq then return end

    for _, item in ipairs(list) do
        if item then
            inv:Remove(item)
            sq:AddWorldInventoryItem(item, 0.5, 0.5, 0.0)
        end
    end

    player:onWornItemsChanged()
end

---@param player IsoPlayer
---@param minRadius integer
---@param z integer | nil
---@param maxRadius integer
---@param maxTries integer
---@param shouldCheckEmpty boolean
---@param allowInteriors boolean
---@param returnPlayerSquare boolean
---@return IsoGridSquare | nil
function ChaosPlayer.GetRandomSquareAroundPlayer(player, z, minRadius, maxRadius, maxTries, shouldCheckEmpty,
                                                 allowInteriors, returnPlayerSquare)
    if not player then return nil end
    local square = player:getSquare()
    if not square then return nil end
    local x = square:getX()
    local y = square:getY()
    local newZ = z ~= nil and z or square:getZ()

    local cell = square:getCell()

    maxTries = maxTries or 50
    for i = 1, maxTries do
        local dx = ZombRand(-maxRadius, maxRadius + 1)
        local dy = ZombRand(-maxRadius, maxRadius + 1)
        local distSq = dx * dx + dy * dy
        local minSq = minRadius * minRadius
        local maxSq = maxRadius * maxRadius

        -- only accept squares between min and max radius
        if distSq >= minSq and distSq <= maxSq then
            local newX = x + dx
            local newY = y + dy
            local sq = cell:getGridSquare(newX, newY, newZ)
            if sq and sq:isSolidFloor() then
                local interiorCheck = true

                if allowInteriors == false then
                    if sq:isOutside() == false then
                        interiorCheck = false
                    end
                end

                local emptyCheck = true

                if shouldCheckEmpty == true then
                    if sq:isFree(false) == false then
                        emptyCheck = false
                    end
                end

                if interiorCheck and emptyCheck then
                    return sq
                end
            end
        end
    end

    if returnPlayerSquare == true then
        return square
    end

    return nil
end

---@param player IsoPlayer
---@param square IsoGridSquare
function ChaosPlayer.TeleportPlayer(player, square)
    if not player then return end
    if not square then return end

    local playerVehicle = player:getVehicle()
    if playerVehicle then
        playerVehicle:setX(square:getX())
        playerVehicle:setY(square:getY())
        playerVehicle:setZ(square:getZ())
        return
    end

    player:teleportTo(square:getX(), square:getY(), square:getZ())
end

---@param player IsoGameCharacter | nil
---@return boolean
function ChaosPlayer.IsPlayerKnockedDown(player)
    if not player then return false end
    local actionState = player:getActionStateName()
    if actionState == "knockeddown" then
        return true
    end
    return false
end

---@param character IsoGameCharacter
---@param baseDamage number
---@param weapon HandWeapon
function ChaosPlayer.SetRandomBodyDamageByMeleeWeapon(character, baseDamage, weapon)
    if not character then return end

    local isBlade = false
    local isBlunt = false

    if weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE) or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE) then
        isBlade = true
    else
        isBlunt = true
    end

    -- Generate random body part index
    local bodyPartIndex = ZombRand(BodyPartType.ToIndex(BodyPartType.Hand_L),
        BodyPartType.ToIndex(BodyPartType.Torso_Lower) + 1)

    if ZombRand(0, 10) == 0 then
        bodyPartIndex = BodyPartType.ToIndex(BodyPart.Head)
    end

    print("[ChaosPlayer] Body part index: " .. tostring(bodyPartIndex))
    bodyPartIndex = math.floor(bodyPartIndex)

    local bodyDamage = character:getBodyDamage()
    if not bodyDamage then return end

    local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(bodyPartIndex))
    if not bodyPart then return end

    character:addHole(BloodBodyPartType.FromIndex(bodyPartIndex))
    bodyDamage:splatBloodFloorBig()

    local pain = 0.0
    if isBlade then
        -- Generate random body part status
        local randNumber = ZombRand(0, 10)
        if randNumber < 6 then
            bodyPart:generateDeepWound()
        elseif randNumber < 9 then
            bodyPart:setCut(true, true)
        else
            bodyPart:setScratched(true, true)
        end

        pain = bodyDamage:getInitialScratchPain() * BodyPartType.getPainModifyer(bodyPartIndex)
    elseif isBlunt then
        -- Generate random body part status
        local randNumber = ZombRand(0, 4)
        if randNumber < 3 then
            bodyPart:setCut(true, true)
        else
            bodyPart:setScratched(true, true)
        end
        pain = bodyDamage:getInitialThumpPain() * BodyPartType.getPainModifyer(bodyPartIndex)
    end

    print("[ChaosPlayer] Adding pain: " .. tostring(pain))
    print("[ChaosPlayer] Adding damage: " .. tostring(baseDamage))
    bodyPart:AddDamage(baseDamage)
    character:getStats():add(CharacterStat.PAIN, pain)
    character:playWeaponHitArmourSound(bodyPartIndex, false)
end

---@param inventory ItemContainer
---@param useDeepLookup boolean
---@param skipContainers boolean
---@param callback fun(item: InventoryItem)
function ChaosPlayer.RecursiveInventoryLookup(inventory, useDeepLookup, skipContainers, callback)
    if not inventory then return end
    if not callback then return end

    if not inventory.getItems then
        return
    end

    local items = inventory:getItems()
    if not items then return end

    --- backward loop
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item then
            local isContainer = item:IsInventoryContainer()
            local shouldCallFunc = true
            if skipContainers and isContainer then
                shouldCallFunc = false
            end
            if shouldCallFunc then
                callback(item)
            end

            if useDeepLookup and isContainer then
                ---@type InventoryContainer
                local containerItem = item
                ChaosPlayer.RecursiveInventoryLookup(containerItem:getInventory(), useDeepLookup, skipContainers,
                    callback)
            end
        end
    end
end

---@param player IsoPlayer
---@param item InventoryItem
function ChaosPlayer.EquipWeapon(player, item)
    if not player then return end
    if not item then return end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if primary or secondary then
        return
    end

    player:setPrimaryHandItem(item)
end

---@param player IsoPlayer
---@param item InventoryItem
---@param amount integer?
function ChaosPlayer.SayLineNewItem(player, item, amount)
    if not player then return end
    if not item then return end

    local itemDisplayName = item:getDisplayName()
    if not itemDisplayName then return end

    local imgCode = ChaosUtils.GetImgCodeByItemTexture(item)
    if not imgCode then return end

    local str = string.format("%s New item: %s", imgCode, itemDisplayName)

    if amount and amount > 1 then
        str = str .. string.format(" (x%d)", amount)
    end

    player:addLineChatElement(
        str,
        0.0, 1.0, 0.0,
        UIFont.Dialogue,
        30.0,
        "default",
        true,
        true,
        true,
        false,
        false,
        true
    )
end

---@param player IsoPlayer
---@param item string
---@param amount integer?
function ChaosPlayer.SayLineNewItemByString(player, item, amount)
    if not player then return end
    if not item then return end

    local item = instanceItem(item)
    if item then
        ChaosPlayer.SayLineNewItem(player, item, amount)
    end
end

---@param player IsoPlayer
---@param text string
---@param colorR number?
---@param colorG number?
---@param colorB number?
function ChaosPlayer.SayLine(player, text, colorR, colorG, colorB)
    if not player then return end
    if not text then return end

    if not colorR then colorR = 1.0 end
    if not colorG then colorG = 1.0 end
    if not colorB then colorB = 1.0 end

    player:addLineChatElement(
        text,
        colorR, colorG, colorB,
        UIFont.Dialogue,
        30.0,
        "default",
        true,
        true,
        true,
        false,
        false,
        true
    )
end
