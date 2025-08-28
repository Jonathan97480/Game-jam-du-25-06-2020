local Effect = {}



-- ===== Effets modernes (dispatch) =====
local function _applyDamageLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    local shield = tonumber(target.state.shield or 0) or 0
    if shield > 0 then
        local absorb = math.min(shield, amount)
        target.state.shield = shield - absorb
        amount = amount - absorb
    end
    if amount > 0 then
        local life = tonumber(target.state.life or 0) or 0
        target.state.life = math.max(0, life - amount)
        if target.state.life <= 0 then target.state.dead = true end
    end
end

local function _applyHealLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    local maxLife = tonumber(target.state.maxLife or target.state.life or 0) or 0
    target.state.life = math.min(maxLife, (tonumber(target.state.life or 0) or 0) + amount)
end

local function _applyShieldLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.shield = (tonumber(target.state.shield or 0) or 0) + amount
end

local function _applyEpineLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.epine = (tonumber(target.state.epine or 0) or 0) + amount
end

local function _applySkipLocal(target, percent)
    if not (target and target.state) then return end
    percent = math.max(0, tonumber(percent) or 0)
    target.state.chancePassTour = math.max(tonumber(target.state.chancePassTour or 0) or 0, percent)
end

-- Nouveaux effets modernes
local function _applyAttackReductionLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.attackReduction = (tonumber(target.state.attackReduction or 0) or 0) + amount
end

local function _applyShieldPassLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.shieldPass = (tonumber(target.state.shieldPass or 0) or 0) + amount
end

local function _applyBleedingLocal(target, effectData)
    if not (target and target.state) then return end
    if type(effectData) ~= "table" then return end

    local value = math.max(0, tonumber(effectData.value or 0) or 0)
    local turns = math.max(1, tonumber(effectData.number_turns or 1) or 1)

    if not target.state.bleeding then
        target.state.bleeding = {}
    end

    -- Ajouter l'effet de saignement
    table.insert(target.state.bleeding, {
        value = value,
        remainingTurns = turns
    })
end

local function _applyForceAugmentedLocal(target, effectData)
    if not (target and target.state) then return end
    if type(effectData) ~= "table" then return end

    local value = math.max(0, tonumber(effectData.value or 0) or 0)
    local turns = math.max(1, tonumber(effectData.number_turns or 1) or 1)

    if not target.state.forceAugmented then
        target.state.forceAugmented = {}
    end

    -- Ajouter l'effet de force augmentée
    table.insert(target.state.forceAugmented, {
        value = value,
        remainingTurns = turns
    })
end

local function _applyChancePassedTourLocal(target, percent)
    if not (target and target.state) then return end
    percent = math.max(0, tonumber(percent) or 0)
    target.state.chancePassedTour = math.max(tonumber(target.state.chancePassedTour or 0) or 0, percent)
end

local function _applyEnergyCostIncreaseLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.energyCostIncrease = (tonumber(target.state.energyCostIncrease or 0) or 0) + amount
end

local function _applyEnergyCostDecreaseLocal(target, amount)
    if not (target and target.state) then return end
    amount = math.max(0, tonumber(amount) or 0)
    target.state.energyCostDecrease = (tonumber(target.state.energyCostDecrease or 0) or 0) + amount
end


-- Fonction pour calculer les bonus d'attaque actuels
function calculateAttackBonus(target)
    if not (target and target.state and target.state.forceAugmented) then return 0 end

    local totalBonus = 0
    for _, augmentEffect in ipairs(target.state.forceAugmented) do
        if augmentEffect.remainingTurns > 0 then
            totalBonus = totalBonus + augmentEffect.value
        end
    end

    return totalBonus
end

-- Fonction pour calculer la réduction d'attaque totale
function calculateAttackReduction(target)
    if not (target and target.state) then return 0 end
    return tonumber(target.state.attackReduction or 0) or 0
end

-- Fonction pour calculer le coût d'énergie modifié
function calculateModifiedEnergyCost(baseCost, target)
    if not target or not target.state then return baseCost end

    local increase = tonumber(target.state.energyCostIncrease or 0) or 0
    local decrease = tonumber(target.state.energyCostDecrease or 0) or 0

    return math.max(0, baseCost + increase - decrease)
end

-- Fonction moderne pour appliquer les effets depuis la structure des cartes
function Effect.applyCardEffect(card, source, target)
    if type(card) ~= "table" then return end
    if type(source) ~= "table" then return end
    if type(target) ~= "table" then return end

    if not (card and card.Effect) then return end
    if not (source and target) then return end

    local effect = card.Effect
    local actorEffects = effect.Actor or {}
    local enemyEffects = effect.Enemy or {}

    -- Déterminer qui applique les effets basé sur les tags
    local sourceIsHero = (source.tag == "Hero" or source.tag == "hero")
    local targetIsHero = (target.tag == "Hero" or target.tag == "hero")

    -- Appliquer les effets sur l'acteur (celui qui joue la carte)
    if sourceIsHero then
        -- Le héros joue la carte, donc actorEffects s'appliquent au héros
        Effect._applyEffectSet(source, actorEffects, source)
        -- Et enemyEffects s'appliquent à l'ennemi (target)
        Effect._applyEffectSet(target, enemyEffects, source)
    else
        -- L'ennemi joue la carte, donc actorEffects s'appliquent à l'ennemi
        Effect._applyEffectSet(source, actorEffects, source)
        -- Et enemyEffects s'appliquent au héros (target)
        Effect._applyEffectSet(target, enemyEffects, source)
    end

    -- Exécuter la fonction action personnalisée si elle existe
    if effect.action and type(effect.action) == "function" then
        local ok, err = pcall(effect.action)
        if not ok and DEBUG_CARD then
            dprint(string.format("[card.action] error: %s", tostring(err)))
        end
    end
end

function Effect._applyEffectSet(source, actorEffects, source)

end

function Effect.dispatchEffect(target, kind, value, source)
    kind          = tostring(kind or ""):lower()
    value         = value or 0

    local handled = false
    if actorManager and actorManager.applyEffect then
        local ok = pcall(actorManager.applyEffect, target, kind, value, { source = source })
        handled = ok or false
        if DEBUG_CARD then
            local tname = target and target.name or "?"
            dprint(string.format("[card.effect] via actorManager: %s %s -> %s", kind, tostring(value), tname))
        end
    end
    if handled then return end

    local tname = target and target.name or "?"

    -- Effets de base
    if kind == "damage" then
        _applyDamageLocal(target, tonumber(value) or 0)
    elseif kind == "heal" then
        _applyHealLocal(target, tonumber(value) or 0)
    elseif kind == "shield" then
        _applyShieldLocal(target, tonumber(value) or 0)
    elseif kind == "epine" or kind == "thorns" then
        _applyEpineLocal(target, tonumber(value) or 0)
    elseif kind == "skip" then
        _applySkipLocal(target, tonumber(value) or 0)

        -- Nouveaux effets
    elseif kind == "attackreduction" or kind == "attack_reduction" then
        _applyAttackReductionLocal(target, tonumber(value) or 0)
    elseif kind == "shieldpass" or kind == "shield_pass" then
        _applyShieldPassLocal(target, tonumber(value) or 0)
    elseif kind == "bleeding" then
        _applyBleedingLocal(target, value)       -- value est un objet table
    elseif kind == "forceaugmented" or kind == "force_augmented" then
        _applyForceAugmentedLocal(target, value) -- value est un objet table
    elseif kind == "chancepassedtour" or kind == "chance_passed_tour" then
        _applyChancePassedTourLocal(target, tonumber(value) or 0)
    elseif kind == "energycostincrease" or kind == "energy_cost_increase" then
        _applyEnergyCostIncreaseLocal(target, tonumber(value) or 0)
    elseif kind == "energycostdecrease" or kind == "energy_cost_decrease" then
        _applyEnergyCostDecreaseLocal(target, tonumber(value) or 0)
    end

    dprint(string.format("[card.effect] local: %s %s -> %s", kind, tostring(value), tname))
end

-- Fonction pour traiter les effets sur la durée à chaque tour
function Effect.processTurnBasedEffects(target)
    if not (target and target.state) then return end

    -- Traiter les effets de saignement
    if target.state.bleeding then
        local totalDamage = 0
        local remainingBleedings = {}

        for _, bleedEffect in ipairs(target.state.bleeding) do
            if bleedEffect.remainingTurns > 0 then
                totalDamage = totalDamage + bleedEffect.value
                bleedEffect.remainingTurns = bleedEffect.remainingTurns - 1

                if bleedEffect.remainingTurns > 0 then
                    table.insert(remainingBleedings, bleedEffect)
                end
            end
        end

        target.state.bleeding = remainingBleedings

        if totalDamage > 0 then
            Effect.dispatchEffect(target, "damage", totalDamage, "bleeding")
            local pos = (target and target.vector2) or { x = 0, y = 0 }
            if effect and effect.play then effect.play("bleeding", pos.x, pos.y) end
        end
    end

    -- Traiter les effets de force augmentée
    if target.state.forceAugmented then
        local remainingAugmentations = {}

        for _, augmentEffect in ipairs(target.state.forceAugmented) do
            if augmentEffect.remainingTurns > 0 then
                augmentEffect.remainingTurns = augmentEffect.remainingTurns - 1

                if augmentEffect.remainingTurns > 0 then
                    table.insert(remainingAugmentations, augmentEffect)
                end
            end
        end

        target.state.forceAugmented = remainingAugmentations
    end
end

return Effect
