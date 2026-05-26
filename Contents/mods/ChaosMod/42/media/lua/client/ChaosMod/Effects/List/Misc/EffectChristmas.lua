---@class EffectChristmas : ChaosEffectBase
---@field previousPrecipitationIsSnow boolean
---@field forceSnowBeforeStart boolean
---@field dressedZombies table<string, boolean>
---@field dressTimer ChaosManualTimer
---@field spawnTimer ChaosManualTimer
---@field previousTime number
EffectChristmas = ChaosEffectBase:derive("EffectChristmas", "christmas")

local TEMP_VALUE = -5
local ZOMBIE_RADIUS = 50
local DRESS_INTERVAL_MS = 500
local SPAWN_INTERVAL_MS = 15000
local SPAWN_MIN_RADIUS = 8
local SPAWN_MAX_RADIUS = 15
local SPAWN_HEALTH = 0.5

local SANTA_OUTFIT = {
    { type = "Base.Hat_SantaHat" },
    { type = "Base.JacketLong_Santa" },
    { type = "Base.Trousers_Santa" },
    { type = "Base.Gloves_LongWomenGloves" },
    { type = "Base.Shoes_BlackBoots" },
}

function EffectChristmas:OnStart()
    ChaosEffectBase:OnStart()



    self.dressedZombies = {}
    self.dressTimer = ChaosManualTimer.new(DRESS_INTERVAL_MS)
    self.spawnTimer = ChaosManualTimer.new(SPAWN_INTERVAL_MS)
    self.spawnTimer.currentMs = self.spawnTimer.maxMs

    local cm = ClimateManager.getInstance()
    if cm then
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_TEMPERATURE, true, TEMP_VALUE)

        self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()

        local isSnow = cm:getClimateBool(ClimateManager.BOOL_IS_SNOW)
        isSnow:setEnableModded(true)
        isSnow:setModdedValue(true)

        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)

        cm:triggerWinterIsComingStorm()
        cm:postCellLoadSetSnow()
    end

    self.forceSnowBeforeStart = getCore():isForceSnow() or false
    getCore():setForceSnow(true)

    local gameTime = GameTime:getInstance()
    if gameTime then
        self.previousTime = gameTime:getTimeOfDay()
        gameTime:setTimeOfDay(23.0)
    end

    self:dressNearbyZombies()

    local player = getPlayer()
    if not player then return end

    for _, item in pairs(SANTA_OUTFIT) do
        if item then
            local newClothes = instanceItem(item.type)
            ChaosPlayer.EquipClothes(player, newClothes)
        end
    end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())

    ChaosUtils.GetTilesBFS_2D(px, py, function(square)
        if square then
            local containerWorldItem = square:AddWorldInventoryItem("Base.Present_ExtraLarge", 0.5, 0.5, 0.0)
            ---@cast containerWorldItem InventoryContainer
            if containerWorldItem then
                local giftInv = containerWorldItem:getInventory()
                if giftInv then
                    giftInv:AddItem("Base.Machete")
                end
            end
            return true
        end
    end, 0, 10, true, true, true, pz, pz)
end

function EffectChristmas:dressNearbyZombies()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    ChaosZombie.ForEachZombieInRange(x, y, ZOMBIE_RADIUS, function(zombie)
        if zombie:isDead() then return end
        local id = tostring(zombie)
        if self.dressedZombies[id] then return end
        self.dressedZombies[id] = true
        ChaosZombie.AddZombieClothesBatch(zombie, SANTA_OUTFIT)

        if zombie:isFemale() == false then
            ChaosZombie.SetHairstyleAndBeard(zombie, {
                hairModel = "Messy",
                beardModel = "LongScruffy",
                useHairColorForBeard = true,
                hairColor = ChaosUtils.MakeRGB(255, 255, 255, true)
            })
        end
    end, true, z)
end

function EffectChristmas:spawnSantaZombie()
    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, nil, SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS, 50, true, true, false
    )
    if not square then return end

    local zombies = ChaosZombie.SpawnZombieAt(square:getX(), square:getY(), square:getZ(), 1, "Naked")
    if not zombies or zombies:size() == 0 then return end

    local zombie = zombies:getFirst()
    if not zombie then return end

    zombie:setHealth(SPAWN_HEALTH)

    local id = tostring(zombie)
    self.dressedZombies[id] = true
    ChaosZombie.AddZombieClothesBatch(zombie, SANTA_OUTFIT)

    if zombie:isFemale() == false then
        ChaosZombie.SetHairstyleAndBeard(zombie, {
            hairModel = "Messy",
            beardModel = "LongScruffy",
            useHairColorForBeard = true,
            hairColor = ChaosUtils.MakeRGB(255, 255, 255, true)
        })
    end

    ChaosZombie.MoveToPlayerSpotted(zombie, player)
end

---@param deltaMs integer
function EffectChristmas:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if cm then
        ChaosUtils.SetClimateFloatOverride(
            cm,
            ClimateManager.FLOAT_TEMPERATURE,
            true,
            TEMP_VALUE
        )
    end

    self.dressTimer:add(deltaMs)
    if self.dressTimer:isEnded() then
        self.dressTimer:reset()
        self:dressNearbyZombies()
    end

    self.spawnTimer:add(deltaMs)
    if self.spawnTimer:isEnded() then
        self.spawnTimer:reset()
        self:spawnSantaZombie()
    end
end

function EffectChristmas:OnEnd()
    ChaosEffectBase:OnEnd()

    local gameTime = GameTime:getInstance()
    if gameTime and self.previousTime then
        gameTime:setTimeOfDay(self.previousTime)
    end

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_TEMPERATURE, false, 0.0)

    local isSnow = cm:getClimateBool(ClimateManager.BOOL_IS_SNOW)
    if isSnow then
        isSnow:setEnableModded(false)
    end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)

    getCore():setForceSnow(self.forceSnowBeforeStart)
end
