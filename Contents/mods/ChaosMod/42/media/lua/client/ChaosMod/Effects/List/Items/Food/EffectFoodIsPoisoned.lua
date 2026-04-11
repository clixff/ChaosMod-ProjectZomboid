EffectFoodIsPoisoned = ChaosEffectBase:derive("EffectFoodIsPoisoned", "food_is_poisoned")

local orig_ISEatFoodAction_complete = nil

function EffectFoodIsPoisoned:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectFoodIsPoisoned] OnStart " .. tostring(self.effectId))

    orig_ISEatFoodAction_complete = ISEatFoodAction.complete

    ISEatFoodAction.complete = function(eatAction)
        if instanceof(eatAction.item, "Food") then
            -- eatAction.item:setPoisonPower(25)

            local stats = getPlayer():getStats()
            if stats then
                if stats:get(CharacterStat.POISON) < 20 then
                    stats:set(CharacterStat.POISON, 20)
                end

                -- if stats:get(CharacterStat.FOOD_SICKNESS) < 60 then
                -- stats:set(CharacterStat.FOOD_SICKNESS, 20)
                -- end
            end
        end
        return orig_ISEatFoodAction_complete(eatAction)
    end
end

function EffectFoodIsPoisoned:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectFoodIsPoisoned] OnEnd " .. tostring(self.effectId))

    if orig_ISEatFoodAction_complete then
        ISEatFoodAction.complete = orig_ISEatFoodAction_complete
        orig_ISEatFoodAction_complete = nil
    end
end
