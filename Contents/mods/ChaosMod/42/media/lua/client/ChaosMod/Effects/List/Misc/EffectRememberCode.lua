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

    ChaosUtils.RemoveRandomItem(player)

    local stats = player:getStats()
    if stats and stats:get(CharacterStat.ENDURANCE) > 0.5 then
        stats:set(CharacterStat.ENDURANCE, 0.5)
    end

    player:setKnockedDown(true)

    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "wrong_answer"), ChaosPlayerChatColors.removedItem)
end

function EffectRememberCode.applyCorrectAnswer()
    print("[EffectRememberCode] Correct answer")
    local player = getPlayer()
    if not player then return end
    ChaosPlayer.SayLine(player, ChaosLocalization.GetString("misc", "correct_answer"), 0.0, 1.0, 0.0)
end

function EffectRememberCode:OnEnd()
    setGameSpeed(1)

    if self.rememberCodeWindow and not self.rememberCodeWindow.resolved then
        self.rememberCodeWindow.resolved = true
        self.rememberCodeWindow:setVisible(false)
        self.rememberCodeWindow:removeFromUIManager()
    end
    self.rememberCodeWindow = nil
end
