---@class SpecialAnimal
---@field animal IsoAnimal
---@field followCharacter IsoGameCharacter?
---@field renderNickname boolean
---@field alwaysRunning boolean
---@field repathTicks integer
---@field maxRepathTicks integer
---@field lastDoorCheckMs integer
SpecialAnimal = SpecialAnimal or {}
SpecialAnimal.__index = SpecialAnimal

SpecialAnimal.modDataNameKey = "ChaosModAnimalNickname"
SpecialAnimal.modDataColorKey = "ChaosModAnimalNicknameColor"

local DOOR_CHECK_INTERVAL_MS = 1000
local DOOR_CHECK_RADIUS = 1

---@param animal IsoAnimal
---@return SpecialAnimal
function SpecialAnimal:new(animal)
    local o = {
        animal = animal,
        followCharacter = getPlayer(),
        renderNickname = true,
        alwaysRunning = true,
        repathTicks = 0,
        maxRepathTicks = 20,
        lastDoorCheckMs = 0
    }
    setmetatable(o, self)
    table.insert(ChaosMod.specialAnimalsFollowers, o)
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

---@param door IsoDoor
---@return boolean
local function forceOpenDoor(door)
    if not door or not instanceof(door, "IsoDoor") then
        return false
    end
    if door:isBarricaded() then
        return false
    end
    door:setLocked(false)
    door:setLockedByKey(false)
    if not door:IsOpen() then
        door:ToggleDoorSilent()
        door:sync()
    end
    return door:IsOpen()
end

---@param animal IsoAnimal
function SpecialAnimal:openNearbyDoors(animal)
    local sq = animal:getSquare()
    if not sq then return end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    ChaosUtils.SquareRingSearchTile_2D(x, y, function(s)
        if s then
            ChaosUtils.ForAllObjectsInSquare(s, function(obj)
                if instanceof(obj, "IsoDoor") then
                    forceOpenDoor(obj)
                end
            end)
        end
    end, 0, DOOR_CHECK_RADIUS, false, false, true, z, z)
end

---@return boolean
function SpecialAnimal:isDead()
    return not self.animal or self.animal:isDead()
end

---@return string nickname, ChaosZombieNicknameColor color
function SpecialAnimal:ensureNicknameAndColor()
    local animal = self.animal
    if not animal then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    local md = animal:getModData()
    if not md then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    if not md[SpecialAnimal.modDataNameKey] or not md[SpecialAnimal.modDataColorKey] then
        local newName, newColor = ChaosNicknames.GetRandomNickname()
        md[SpecialAnimal.modDataNameKey] = newName
        md[SpecialAnimal.modDataColorKey] = newColor
    end
    return md[SpecialAnimal.modDataNameKey], md[SpecialAnimal.modDataColorKey]
end

local NICKNAME_RENDER_DIST = 15

function SpecialAnimal:tick()
    local animal = self.animal
    if not animal or animal:isDead() then return end

    local player = getPlayer()

    if self.renderNickname and ChaosConfig.IsAnimalsNicknamesEnabled() and player then
        local inRange = ChaosUtils.isInRange(player:getX(), player:getY(), animal:getX(), animal:getY(),
            NICKNAME_RENDER_DIST)
        if inRange then
            local name, color = self:ensureNicknameAndColor()
            if not color then color = { r = 1.00, g = 0.00, b = 0.00 } end
            if animal.addLineChatElement then
                animal:addLineChatElement(name, color.r, color.g, color.b)
            end
        else
            if animal.addLineChatElement then
                animal:addLineChatElement("")
            end
        end
    else
        if animal.addLineChatElement then
            animal:addLineChatElement("")
        end
    end

    if self.alwaysRunning then
        animal:setVariable("animalRunning", true)
    end

    local follow = self.followCharacter
    if follow and not follow:isAlive() then
        self.followCharacter = nil
        follow = nil
    end

    if follow then
        self.repathTicks = self.repathTicks + 1
        if self.repathTicks >= self.maxRepathTicks then
            self.repathTicks = 0
            if animal:DistToProper(follow) > 2.0 then
                animal:pathToCharacter(follow)
            end
        end
    end

    local now = getTimestampMs()
    if (now - (self.lastDoorCheckMs or 0)) >= DOOR_CHECK_INTERVAL_MS then
        self.lastDoorCheckMs = now
        self:openNearbyDoors(animal)
    end
end

return SpecialAnimal
