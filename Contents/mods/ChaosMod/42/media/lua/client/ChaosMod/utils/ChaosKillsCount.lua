ChaosKillsCount = ChaosKillsCount or {}

local MOD_DATA_KEY = "ChaosSpentKills"

---@param player IsoPlayer
---@return integer
function ChaosKillsCount.getSpentKills(player)
    if not player then return 0 end
    local modData = player:getModData()
    if not modData then return 0 end
    local value = modData[MOD_DATA_KEY]
    if type(value) ~= "number" then return 0 end
    return math.floor(value)
end

---@param player IsoPlayer
---@return integer
function ChaosKillsCount.getPlayerKillsCountCurrency(player)
    if not player then return 0 end
    local totalKills = player:getZombieKills() or 0
    local currency = totalKills - ChaosKillsCount.getSpentKills(player)
    if currency < 0 then return 0 end
    return currency
end

---@param player IsoPlayer
---@param amount integer
function ChaosKillsCount.spendKills(player, amount)
    if not player then return end
    if not amount or amount <= 0 then return end
    local modData = player:getModData()
    if not modData then return end
    modData[MOD_DATA_KEY] = ChaosKillsCount.getSpentKills(player) + math.floor(amount)
end

---@param player IsoPlayer
---@param amount integer
---@return boolean
function ChaosKillsCount.hasEnoughCurrency(player, amount)
    if not player then return false end
    if not amount or amount <= 0 then return true end
    return ChaosKillsCount.getPlayerKillsCountCurrency(player) >= amount
end
