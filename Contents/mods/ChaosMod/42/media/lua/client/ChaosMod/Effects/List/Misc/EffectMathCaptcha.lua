---@class EffectMathCaptcha : ChaosEffectBase
---@field answer integer
---@field captchaWindow ChaosCaptchaWindow | nil
EffectMathCaptcha = ChaosEffectBase:derive("EffectMathCaptcha", "math_captcha")

function EffectMathCaptcha:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectMathCaptcha] OnStart")

    setGameSpeed(0)

    local a = ZombRand(0, 999)
    local b = ZombRand(0, 999)
    self.answer = math.floor(a + b)

    local question = string.format("%d + %d = ?", a, b)

    self.captchaWindow = ChaosCaptchaWindow:new(self, question)
    self.captchaWindow:initialise()
    self.captchaWindow:addToUIManager()
    self.captchaWindow:setVisible(true)
end

function EffectMathCaptcha.applyWrongAnswer()
    print("[EffectMathCaptcha] Wrong answer")
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

    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "wrong_answer"),
        ChaosPlayerChatColors.removedItem)
end

function EffectMathCaptcha.applyCorrectAnswer()
    print("[EffectMathCaptcha] Correct answer")
    local player = getPlayer()
    if not player then return end
    ChaosPlayer.SayLine(player, ChaosLocalization.GetString("misc", "correct_answer"), 0.0, 1.0, 0.0)
end

function EffectMathCaptcha:OnEnd()
    setGameSpeed(1)

    if self.captchaWindow and not self.captchaWindow.resolved then
        self.captchaWindow.resolved = true
        self.captchaWindow:setVisible(false)
        self.captchaWindow:removeFromUIManager()
    end
    self.captchaWindow = nil
end
