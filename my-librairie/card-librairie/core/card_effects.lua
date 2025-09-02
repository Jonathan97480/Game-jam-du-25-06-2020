-- my-librairie/card-librairie/core/card_effects.lua
-- Module central pour l'application des effets de cartes
-- Remplace le module applyEffect manquant appelé par Common.playCard()

local card_effects = {}

-- Modules requis
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local attack = _safeRequire("my-librairie/card-librairie/cardEffect/attack")
local heal = _safeRequire("my-librairie/card-librairie/cardEffect/heal")
local giveShield = _safeRequire("my-librairie/card-librairie/cardEffect/giveSheld")
local giveEpine = _safeRequire("my-librairie/card-librairie/cardEffect/giveEpine")
local actorManager = _safeRequire("my-librairie/managers/actorManager")

-- Configuration des assets par effet (JSON à renseigner plus tard)
local EFFECT_ASSETS = {
    attack = {
        visual = "img/effect/Attaque-base/", -- Utilise les 8 frames existantes
        audio = "placeholder_attack.ogg"
    },
    heal = {
        visual = "img/effect/heal/", -- Utilise les 5 frames existantes
        audio = "placeholder_heal.ogg"
    },
    shield = {
        visual = "img/effect/shield/", -- Assets existants
        audio = "placeholder_shield.ogg"
    },
    epine = {
        visual = "img/effect/epine/", -- Assets existants
        audio = "placeholder_epine.ogg"
    },
    bleeding = {
        visual = "img/effect/degat/", -- Réutilise dégâts pour bleeding
        audio = "placeholder_bleeding.ogg"
    },
    -- Effets temporaires mappés sur existants
    chancePassedTour = {
        visual = "img/effect/heal/", -- Placeholder avec heal (étoiles dorées)
        audio = "placeholder_sleep.ogg"
    },
    AttackReduction = {
        visual = "img/effect/degat/", -- Placeholder avec dégâts
        audio = "placeholder_weakness.ogg"
    },
    force_augmented = {
        visual = "img/effect/Attaque-base/", -- Placeholder avec attaque
        audio = "placeholder_buff.ogg"
    }
}

-- Fonction de log
local function _log(level, message)
    local gf = _G.globalFunction
    local prefix = "[card_effects]"
    if gf and gf.log then
        if level == "info" and gf.log.info then
            gf.log.info(prefix .. " " .. message)
        elseif level == "warn" and gf.log.warn then
            gf.log.warn(prefix .. " " .. message)
        elseif level == "error" and gf.log.error then
            gf.log.error(prefix .. " " .. message)
        end
    else
        print(prefix .. " [" .. level .. "] " .. message)
    end
end

-- ⭐ FONCTION PRINCIPALE - remplace applyEffect.applyCardEffect
function card_effects.applyCardEffect(card, source, target)
    if not card then
        _log("error", "applyCardEffect: carte manquante")
        return false
    end
    if not source then
        _log("error", "applyCardEffect: source manquante")
        return false
    end
    if not target then
        _log("error", "applyCardEffect: target manquante")
        return false
    end

    _log("info", "🎯 Application effet carte: " .. (card.name or "sans nom"))
    _log("info", "   Source: " .. (source.tag or source.name or "inconnu"))
    _log("info", "   Target: " .. (target.tag or target.name or "inconnu"))

    -- ⭐ NOUVEAU: Détection multiTarget
    if card.multiTarget then
        _log("info", "💥 Carte AOE détectée - application sur tous les ennemis")
        return card_effects.applyCardEffectAOE(card, source)
    end

    local success = true

    -- Appliquer les effets caster sur source
    if card.Effect and card.Effect.caster then
        local casterSuccess = card_effects.applyCasterEffects(card, source)
        success = success and casterSuccess
    end

    -- Appliquer les effets target sur target
    if card.Effect and card.Effect.target then
        local targetSuccess = card_effects.applyToTarget(card, target, source)
        success = success and targetSuccess
    end

    -- Exécuter l'action personnalisée si présente
    if card.Effect and card.Effect.action then
        local actionSuccess = card_effects.executeAction(card, { source = source, target = target })
        success = success and actionSuccess
    end

    _log("info", "✅ Application effet terminée: " .. tostring(success))
    return success
end

-- ⭐ NOUVELLE FONCTION: Application AOE sur tous les ennemis
function card_effects.applyCardEffectAOE(card, source)
    if not card or not source then
        _log("error", "applyCardEffectAOE: paramètres manquants")
        return false
    end

    _log("info", "💥 Application effet AOE: " .. (card.name or "sans nom"))

    local success = true
    local enemiesAffected = 0

    -- Appliquer les effets caster sur source
    if card.Effect and card.Effect.caster then
        local casterSuccess = card_effects.applyCasterEffects(card, source)
        success = success and casterSuccess
    end

    -- Obtenir tous les ennemis
    local enemies = {}
    if actorManager and actorManager.getAllEnemies then
        enemies = actorManager.getAllEnemies()
    elseif _G.actorManager and _G.actorManager.getAllEnemies then
        enemies = _G.actorManager.getAllEnemies()
    else
        _log("warn", "actorManager.getAllEnemies non disponible pour AOE")
    end

    -- Appliquer les effets target sur tous les ennemis
    if card.Effect and card.Effect.target and #enemies > 0 then
        for _, enemy in ipairs(enemies) do
            if enemy and enemy.state and (enemy.state.life or 0) > 0 then
                local targetSuccess = card_effects.applyToTarget(card, enemy, source)
                if targetSuccess then
                    enemiesAffected = enemiesAffected + 1
                end
                success = success and targetSuccess
            end
        end
    end

    -- Exécuter l'action personnalisée si présente
    if card.Effect and card.Effect.action then
        local actionSuccess = card_effects.executeAction(card, {
            source = source,
            targets = enemies,
            enemiesAffected = enemiesAffected
        })
        success = success and actionSuccess
    end

    _log("info", "💥 AOE terminé: " .. enemiesAffected .. " ennemis affectés, succès: " .. tostring(success))
    return success
end

-- Application des effets sur le lanceur (caster)
function card_effects.applyCasterEffects(card, casterActor)
    if not card.Effect or not card.Effect.caster then return true end
    if not casterActor then return false end

    _log("info", "🔄 Application effets caster sur: " .. (casterActor.tag or "acteur"))

    return card_effects.applyNumericEffects(card.Effect.caster, casterActor, "caster")
end

-- Application des effets sur la cible
function card_effects.applyToTarget(card, targetActor, casterActor)
    if not card.Effect or not card.Effect.target then return true end
    if not targetActor then return false end

    _log("info", "🎯 Application effets target sur: " .. (targetActor.tag or "acteur"))

    return card_effects.applyNumericEffects(card.Effect.target, targetActor, "target")
end

-- Application multi-target (cartes AOE)
function card_effects.applyToAllTargets(card, enemies, casterActor)
    if not card.Effect or not card.Effect.target then return true end
    if not enemies or #enemies == 0 then return true end

    _log("info", "💥 Application effets AOE sur " .. #enemies .. " ennemis")

    local success = true
    for i, enemy in ipairs(enemies) do
        if enemy and enemy.state and (enemy.state.life or 0) > 0 then
            local targetSuccess = card_effects.applyToTarget(card, enemy, casterActor)
            success = success and targetSuccess
        end
    end

    return success
end

-- Application des champs numériques et temporels
function card_effects.applyNumericEffects(effectTable, actor, role)
    if not effectTable or not actor then return false end

    local success = true
    role = role or "unknown"

    -- Effets numériques simples
    if effectTable.heal and effectTable.heal > 0 then
        success = success and card_effects._applyHeal(actor, effectTable.heal)
    end

    if effectTable.shield and effectTable.shield > 0 then
        success = success and card_effects._applyShield(actor, effectTable.shield)
    end

    if effectTable.attack and effectTable.attack > 0 then
        success = success and card_effects._applyAttack(actor, effectTable.attack)
    end

    if effectTable.Epine and effectTable.Epine > 0 then
        success = success and card_effects._applyEpine(actor, effectTable.Epine)
    end

    if effectTable.AttackReduction and effectTable.AttackReduction > 0 then
        success = success and card_effects._applyAttackReduction(actor, effectTable.AttackReduction)
    end

    if effectTable.chancePassedTour and effectTable.chancePassedTour > 0 then
        success = success and card_effects._applyStun(actor, effectTable.chancePassedTour)
    end

    -- Effets temporels (tables avec value + number_turns)
    if effectTable.bleeding and effectTable.bleeding.value and effectTable.bleeding.value > 0 then
        success = success and card_effects._applyBleeding(actor, effectTable.bleeding)
    end

    if effectTable.force_augmented and effectTable.force_augmented.value and effectTable.force_augmented.value > 0 then
        success = success and card_effects._applyForceAugmented(actor, effectTable.force_augmented)
    end

    _log("info", "📊 Effets " .. role .. " appliqués: " .. tostring(success))
    return success
end

-- ===== IMPLÉMENTATIONS DES EFFETS SPÉCIFIQUES =====

function card_effects._applyHeal(actor, amount)
    if heal and heal.give then
        local healed = heal.give(nil, actor, amount)
        _log("info", "❤️ Heal appliqué: +" .. healed .. " PV")
        card_effects._playEffect("heal", actor)
        return healed > 0
    else
        -- Fallback manuel
        if actor.state and actor.state.life and actor.state.maxLife then
            local before = actor.state.life
            actor.state.life = math.min(actor.state.maxLife, actor.state.life + amount)
            local healed = actor.state.life - before
            _log("info", "❤️ Heal appliqué (fallback): +" .. healed .. " PV")
            card_effects._playEffect("heal", actor)
            return healed > 0
        end
    end
    return false
end

function card_effects._applyShield(actor, amount)
    if giveShield and giveShield.give then
        giveShield.give(nil, actor, amount)
        _log("info", "🛡️ Shield appliqué: +" .. amount)
        card_effects._playEffect("shield", actor)
        return true
    else
        -- Fallback manuel
        if actor.state then
            actor.state.shield = (actor.state.shield or 0) + amount
            _log("info", "🛡️ Shield appliqué (fallback): +" .. amount)
            card_effects._playEffect("shield", actor)
            return true
        end
    end
    return false
end

function card_effects._applyAttack(actor, amount)
    if attack and attack.applique then
        attack.applique(nil, nil, actor, amount)
        _log("info", "⚔️ Attaque appliquée: -" .. amount .. " PV")
        card_effects._playEffect("attack", actor)
        return true
    else
        -- Fallback manuel
        if actor.state and actor.state.life then
            local damage = amount
            -- Appliquer shield en premier
            if actor.state.shield and actor.state.shield > 0 then
                local shieldAbsorbed = math.min(actor.state.shield, damage)
                actor.state.shield = actor.state.shield - shieldAbsorbed
                damage = damage - shieldAbsorbed
                _log("info", "🛡️ Shield absorbe: " .. shieldAbsorbed .. " dégâts")
            end
            -- Dégâts restants sur PV
            if damage > 0 then
                actor.state.life = math.max(0, actor.state.life - damage)
                _log("info", "⚔️ Attaque appliquée (fallback): -" .. damage .. " PV")
            end
            card_effects._playEffect("attack", actor)
            return true
        end
    end
    return false
end

function card_effects._applyEpine(actor, amount)
    if giveEpine and giveEpine.give then
        giveEpine.give(nil, actor, amount)
        _log("info", "🌿 Épines appliquées: +" .. amount)
        card_effects._playEffect("epine", actor)
        return true
    else
        -- Fallback manuel
        if actor.state then
            actor.state.epine = (actor.state.epine or 0) + amount
            _log("info", "🌿 Épines appliquées (fallback): +" .. amount)
            card_effects._playEffect("epine", actor)
            return true
        end
    end
    return false
end

function card_effects._applyAttackReduction(actor, percentage)
    if actor.state then
        actor.state.attackReduction = (actor.state.attackReduction or 0) + percentage
        _log("info", "🔻 Réduction attaque appliquée: +" .. percentage .. "%")
        card_effects._playEffect("AttackReduction", actor)
        return true
    end
    return false
end

function card_effects._applyStun(actor, percentage)
    local chance = math.random(100)
    if chance <= percentage then
        if actor.state then
            actor.state.stunned = true
            actor.state.stunnedTurns = 1
            _log("info", "😴 Stun appliqué avec succès (" .. percentage .. "% de chance)")
            card_effects._playEffect("chancePassedTour", actor)
            return true
        end
    else
        _log("info", "😴 Stun raté (" .. percentage .. "% de chance, tiré: " .. chance .. ")")
    end
    return false
end

function card_effects._applyBleeding(actor, bleedingData)
    if actor.state then
        if not actor.state.bleeding then actor.state.bleeding = {} end
        table.insert(actor.state.bleeding, {
            value = bleedingData.value,
            turns = bleedingData.number_turns
        })
        _log("info",
            "🩸 Saignement appliqué: " .. bleedingData.value .. " dégâts sur " .. bleedingData.number_turns .. " tours")
        card_effects._playEffect("bleeding", actor)
        return true
    end
    return false
end

function card_effects._applyForceAugmented(actor, buffData)
    if actor.state then
        if not actor.state.force_augmented then actor.state.force_augmented = {} end
        table.insert(actor.state.force_augmented, {
            value = buffData.value,
            turns = buffData.number_turns
        })
        _log("info", "💪 Force augmentée appliquée: +" .. buffData.value .. " sur " .. buffData.number_turns .. " tours")
        card_effects._playEffect("force_augmented", actor)
        return true
    end
    return false
end

-- Exécution sécurisée des fonctions action
function card_effects.executeAction(card, context)
    if not card.Effect or not card.Effect.action then return true end
    if type(card.Effect.action) ~= "function" then return true end

    _log("info", "🎬 Exécution action personnalisée...")

    -- Sauvegarder contexte global
    local oldUser = _G._user
    local oldTarget = _G._target

    -- Définir contexte pour l'action
    if context then
        _G._user = context.source
        _G._target = context.target
    end

    local success, err = pcall(card.Effect.action, context) -- ⭐ PASSE LE CONTEXTE

    -- Restaurer contexte global
    _G._user = oldUser
    _G._target = oldTarget

    if success then
        _log("info", "✅ Action exécutée avec succès")
        return true
    else
        _log("error", "❌ Erreur dans l'action: " .. tostring(err))
        return false
    end
end

-- Jouer un effet visuel/audio
function card_effects._playEffect(effectType, actor)
    local assets = EFFECT_ASSETS[effectType]
    if not assets then return end

    local x = (actor.vector2 and actor.vector2.x) or 0
    local y = (actor.vector2 and actor.vector2.y) or 0

    -- Jouer effet visuel si système d'effets disponible
    local effect = _G.effect or _safeRequire("ressources/effect")
    if effect and effect.play then
        if type(effect.play) == "function" then
            -- Nouvelle signature (table)
            effect.play({
                name = effectType,
                vector2 = { x = x, y = y },
                visual = assets.visual
            })
        else
            -- Ancienne signature
            effect.play(effectType, x, y, { visual = assets.visual })
        end
    end

    -- TODO: Jouer audio quand système audio disponible
    -- audio.play(assets.audio)
end

-- Validation et logs
function card_effects.validateEffect(effect)
    if not effect then return false, "Effet manquant" end
    if type(effect) ~= "table" then return false, "Effet doit être une table" end
    if not effect.caster and not effect.target and not effect.action then
        return false, "Effet vide (pas de caster, target, ou action)"
    end
    return true, "Effet valide"
end

function card_effects.logEffectApplication(card, target, result)
    local cardName = (card and card.name) or "carte inconnue"
    local targetName = (target and (target.tag or target.name)) or "cible inconnue"
    _log("info", "📝 Résultat application " .. cardName .. " → " .. targetName .. ": " .. tostring(result))
end

-- Exposer globalement
_G.card_effects = card_effects

return card_effects
