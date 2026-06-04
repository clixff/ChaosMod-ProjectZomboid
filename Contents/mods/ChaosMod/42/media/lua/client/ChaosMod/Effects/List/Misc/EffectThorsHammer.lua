---@class EffectThorsHammer : ChaosEffectBase
---@field isActive boolean
---@field canShoutPrevious boolean
---@field onKeyPressed fun(key: integer)
---@field cooldownMs integer
---@field isThrowing boolean
---@field throwElapsedMs integer
---@field dirX number
---@field dirY number
---@field spin number
---@field worldHammerItem InventoryItem?
---@field worldHammerObj IsoWorldInventoryObject?
---@field anchorSquare IsoGridSquare?
---@field hitThisThrow table<integer, boolean>
---@field zombiePool ArrayList?
---@field poolRefreshMs integer
EffectThorsHammer = ChaosEffectBase:derive("EffectThorsHammer", "thors_hammer")

---@type string
local HAMMER_ITEM_ID = "Base.ClubHammer"
---@type number
local THROW_DISTANCE = 8.0
---@type integer
local FLY_DURATION_MS = 1200
---@type integer
local COOLDOWN_MS = 1600
---@type number
local HIT_RADIUS = 2.5
---@type number
local HAMMER_Z_OFFSET = 0.3
---@type number
local POOL_RADIUS = 8.0
---@type integer
local POOL_REFRESH_MS = 500
---@type number
local ZOMBIE_DAMAGE = 5.0
---@type number
local SPIN_SPEED_DEG_PER_SEC = 720.0
---@type string
local REMINDER_TEXT = "Press Q to Use Hammer"

---@param zombie IsoZombie
---@param player IsoPlayer
---@return boolean
local function isValidTarget(zombie, player)
    if not zombie or not zombie:isAlive() then return false end
    if not ChaosNPCUtils.IsNPC(zombie) then return true end
    local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
    if not npc then return true end
    local relation = ChaosNPCRelations.GetRelationForNPC(npc, player)
    return relation == ChaosNPCRelationType.ATTACK
end

---@param self EffectThorsHammer
local function despawnHammer(self)
    if self.worldHammerObj then
        self.worldHammerObj:setHighlighted(0, false, false)
        self.worldHammerObj:setOutlineHighlight(0, false)
        ChaosUtils.RemoveWorldObject(self.worldHammerObj)
    end
    self.worldHammerItem = nil
    self.worldHammerObj = nil
    self.anchorSquare = nil
end

---@param self EffectThorsHammer
---@param square IsoGridSquare
local function spawnHammerOnSquare(self, square)
    local item = instanceItem(HAMMER_ITEM_ID)
    if not item then return end

    local placedItem = square:AddWorldInventoryItem(item, 0.5, 0.5, HAMMER_Z_OFFSET, false)
    if not placedItem then return end

    local worldObj = placedItem:getWorldItem()
    if not worldObj then return end

    self.worldHammerItem = placedItem
    self.worldHammerObj = worldObj
    self.anchorSquare = square

    worldObj:setHighlighted(0, true, false)
    worldObj:setOutlineHighlightCol(0, 1.0, 1.0, 0.0, 1.0)
end

---Returns the hammer's current world position based on throw progress.
---@param self EffectThorsHammer
---@param player IsoPlayer
---@return number, number, number
local function getHammerPosition(self, player)
    local t = self.throwElapsedMs / FLY_DURATION_MS
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    -- Triangle wave: 0 at start, 1.0 at midpoint (max distance), 0 on return.
    local tri = (t <= 0.5) and (t * 2.0) or ((1.0 - t) * 2.0)
    local dist = THROW_DISTANCE * tri

    local hx = player:getX() + self.dirX * dist
    local hy = player:getY() + self.dirY * dist
    local hz = player:getZ() + HAMMER_Z_OFFSET
    return hx, hy, hz
end

---@param self EffectThorsHammer
---@param player IsoPlayer
local function updateHammerTransform(self, player)
    local item = self.worldHammerItem
    local worldObj = self.worldHammerObj
    local anchor = self.anchorSquare
    if not item or not worldObj or not anchor then return end

    local hx, hy, hz = getHammerPosition(self, player)

    local offX = hx - anchor:getX()
    local offY = hy - anchor:getY()
    local offZ = hz - anchor:getZ()

    item:setWorldXRotation(0.0)
    item:setWorldYRotation(0.0)
    item:setWorldZRotation(ChaosUtils.Normalize360(self.spin))

    worldObj:setOffX(offX)
    worldObj:setOffY(offY)
    worldObj:setOffZ(offZ)
    worldObj:setExtendedPlacement(true)
    worldObj:syncExtendedPlacement()
    worldObj:invalidateRenderChunkLevel(256)
    worldObj:setTargetAlpha(0, 1.0)
end

---@param self EffectThorsHammer
---@param player IsoPlayer
local function refreshZombiePool(self, player)
    self.zombiePool = ChaosZombie.GetNearestZombies(player:getX(), player:getY(), POOL_RADIUS, false,
        math.floor(player:getZ()))
end

---Checks the cached zombie pool for any target near the hammer and hits it.
---@param self EffectThorsHammer
---@param player IsoPlayer
local function damageZombiesNearHammer(self, player)
    local pool = self.zombiePool
    if not pool then return end

    local hx, hy, _ = getHammerPosition(self, player)

    local didHit = false
    for i = 0, pool:size() - 1 do
        ---@type IsoZombie
        local zombie = pool:get(i)
        if zombie and zombie:isAlive() then
            local id = zombie:getID()
            if not self.hitThisThrow[id] then
                if ChaosUtils.isInRange(hx, hy, zombie:getX(), zombie:getY(), HIT_RADIUS)
                    and isValidTarget(zombie, player) then
                    self.hitThisThrow[id] = true
                    zombie:knockDown(true)
                    ChaosZombie.DamageZombie(zombie, ZOMBIE_DAMAGE, player)
                    zombie:setOnFire(true)
                    didHit = true
                end
            end
        end
    end

    if didHit then
        local square = getCell():getGridSquare(math.floor(hx), math.floor(hy), math.floor(player:getZ()))
        if square then
            ---@type string[]
            local sounds = {
                "thump3",
                "thump4",
                "thump5",
                "thump6"
            }

            ---@type string?
            local sound = sounds[ChaosUtils.RandArrayIndex(sounds)]

            if sound then
                local soundId = getSoundManager():PlayWorldSoundWav(sound, square, 1.0, 20.0, 1.0, true)

                if soundId then
                    local settingsVolume = getCore():getRealOptionSoundVolume()
                    soundId:setVolume(settingsVolume)
                end
            end
        end
    end
end

---@param self EffectThorsHammer
local function triggerThrow(self)
    if not self.isActive then return end
    if self.cooldownMs > 0 then return end

    local player = getPlayer()
    if not player then return end

    local fx = player:getForwardDirectionX() or 0
    local fy = player:getForwardDirectionY() or 0
    local len = math.sqrt(fx * fx + fy * fy)
    if len < 0.001 then
        fx, fy = 0, 1
    else
        fx, fy = fx / len, fy / len
    end

    self.dirX = fx
    self.dirY = fy
    self.cooldownMs = COOLDOWN_MS
    self.isThrowing = true
    self.throwElapsedMs = 0
    self.spin = 0
    self.hitThisThrow = {}

    local square = player:getSquare()
    if square then
        spawnHammerOnSquare(self, square)
    end

    refreshZombiePool(self, player)
    updateHammerTransform(self, player)
end

function EffectThorsHammer:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    self.canShoutPrevious = player:isCanShout()
    player:setCanShout(false)

    self.isActive = true
    self.cooldownMs = 0
    self.isThrowing = false
    self.throwElapsedMs = 0
    self.dirX = 0
    self.dirY = 1
    self.spin = 0
    self.hitThisThrow = {}
    self.poolRefreshMs = 0

    refreshZombiePool(self, player)

    ChaosPlayer.SayLine(player, REMINDER_TEXT, 0.0, 1.0, 0.0)

    self.onKeyPressed = function(key)
        if key ~= Keyboard.KEY_Q then return end
        triggerThrow(self)
    end
    Events.OnKeyPressed.Add(self.onKeyPressed)
end

---@param deltaMs integer
function EffectThorsHammer:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    if self.cooldownMs > 0 then
        self.cooldownMs = self.cooldownMs - deltaMs
        if self.cooldownMs < 0 then self.cooldownMs = 0 end
        local bar = UIManager.getProgressBar(0)
        if bar then
            bar:setValue(1.0 - (self.cooldownMs / COOLDOWN_MS))
        end
    end

    self.poolRefreshMs = self.poolRefreshMs - deltaMs
    if self.poolRefreshMs <= 0 then
        self.poolRefreshMs = POOL_REFRESH_MS
        refreshZombiePool(self, player)
    end

    if self.isThrowing then
        self.throwElapsedMs = self.throwElapsedMs + deltaMs
        self.spin = ChaosUtils.Normalize360(self.spin + SPIN_SPEED_DEG_PER_SEC * (deltaMs / 1000.0))

        if self.throwElapsedMs >= FLY_DURATION_MS then
            self.isThrowing = false
            despawnHammer(self)
        else
            updateHammerTransform(self, player)
            damageZombiesNearHammer(self, player)
        end
    end
end

function EffectThorsHammer:OnEnd()
    ChaosEffectBase:OnEnd()

    self.isActive = false
    self.isThrowing = false

    local player = getPlayer()
    if player then
        player:setCanShout(self.canShoutPrevious == true)
    end

    despawnHammer(self)

    local bar = UIManager.getProgressBar(0)
    if bar then
        bar:setValue(0)
    end

    if self.onKeyPressed then
        Events.OnKeyPressed.Remove(self.onKeyPressed)
        self.onKeyPressed = nil
    end
end
