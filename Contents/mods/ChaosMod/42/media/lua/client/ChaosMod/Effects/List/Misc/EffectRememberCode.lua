---@class EffectRememberCode : ChaosEffectBase
---@field code string
---@field rememberCodeWindow ChaosRememberCodeWindow | nil
EffectRememberCode = ChaosEffectBase:derive("EffectRememberCode", "remember_code")

function EffectRememberCode:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRememberCode] OnStart")

    setGameSpeed(0)

    local codeParts = {}
    for _ = 1, 6 do
        codeParts[#codeParts + 1] = tostring(ZombRand(0, 10))
    end
    self.code = table.concat(codeParts)

    self.rememberCodeWindow = ChaosRememberCodeWindow:new(self, self.code)
    self.rememberCodeWindow:initialise()
    self.rememberCodeWindow:addToUIManager()
    self.rememberCodeWindow:setVisible(true)
end

function EffectRememberCode.applyWrongAnswer()
    print("[EffectRememberCode] Wrong answer")
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if square then
        ChaosUtils.TriggerExplosionAt(square)
    end

    local stats = player:getStats()
    if stats and stats:get(CharacterStat.ENDURANCE) > 0.5 then
        stats:set(CharacterStat.ENDURANCE, 0.5)
    end


    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "wrong_answer"),
        ChaosPlayerChatColors.removedItem)
end

function EffectRememberCode.applyCorrectAnswer()
    print("[EffectRememberCode] Correct answer")
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if inventory then
        local itemId = GetRandomLootboxItem()
        if itemId then
            local item = inventory:AddItem(itemId)
            if item then
                ChaosItems.SetFullAmmoIfWeapon(item)

                ChaosPlayer.SayLineNewItem(player, item)
            end
        end
    end

    if player.playGainExperienceLevelSound then
        player:playGainExperienceLevelSound()
    end
end

function EffectRememberCode:OnEnd()
    if self.rememberCodeWindow and not self.rememberCodeWindow.resolved then
        self.rememberCodeWindow.resolved = true
        self.rememberCodeWindow:setVisible(false)
        self.rememberCodeWindow:removeFromUIManager()
    end
    self.rememberCodeWindow = nil

    setGameSpeed(1)
end
