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

    local stats = player:getStats()
    if stats and stats:get(CharacterStat.ENDURANCE) > 0.5 then
        stats:set(CharacterStat.ENDURANCE, 0.5)
    end

    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "wrong_answer"),
        ChaosPlayerChatColors.removedItem)

    local inventory = player:getInventory()
    if inventory then
        local calculator = inventory:AddItem("Base.Calculator")
        if calculator then
            ChaosPlayer.SayLineNewItem(player, calculator)
        end
    end
end

function EffectMathCaptcha.applyCorrectAnswer()
    print("[EffectMathCaptcha] Correct answer")
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

function EffectMathCaptcha:OnEnd()
    if self.captchaWindow and not self.captchaWindow.resolved then
        self.captchaWindow.resolved = true
        self.captchaWindow:setVisible(false)
        self.captchaWindow:removeFromUIManager()
    end
    self.captchaWindow = nil

    setGameSpeed(1)
end
