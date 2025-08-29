-- my-librairie/ai/card_selection_strategy.lua
-- Module de stratégie de sélection de cartes et de ciblage pour l'IA
-- Sépare la logique de décision du controller principal pour une meilleure lisibilité

-- Chargement sécurisé pour éviter les boucles circulaires
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local globalFunction = _G.globalFunction or rawget(_G, 'globalFunction')
local Card = _G.Card or rawget(_G, "Card") or rawget(_G, "card")
local Hero = _G.Hero or rawget(_G, "Hero")
local EnemiesManager = _G.Enemies or rawget(_G, "Enemies")

-- Module principal
local CardSelectionStrategy = {}

-- ============================================================================
-- UTILITÉS COMMUNES
-- ============================================================================

local function logf(fmt, ...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(string.format(fmt, ...))
    end
end

local function snap(actor)
    if not actor or not actor.state then return {} end
    return {
        life = actor.state.life or 0,
        sh = actor.state.shield or 0,
        ep = actor.state.epine or 0
    }
end

local function lifeRatio(actor)
    if not actor or not actor.state then return 0 end
    local max = tonumber(actor.state.maxLife) or 1
    local cur = tonumber(actor.state.life) or 0
    return cur / max
end

local function getShield(actor)
    if not actor or not actor.state then return 0 end
    return tonumber(actor.state.shield) or 0
end

local function getEffects(c)
    if not c then return { hero = {}, enemy = {} } end
    local eff = c.effect or c.Effect or {}
    return {
        hero = eff.hero or {},
        enemy = eff.enemy or {}
    }
end

-- ============================================================================
-- LOGIQUE DE CIBLAGE ET DÉTECTION D'ALLIÉS
-- ============================================================================

-- Récupère l'ennemi courant depuis le Template Combat (plus fiable)
function CardSelectionStrategy.getCurrentEnemy()
    -- Priorité au système de transition moderne
    if EnemiesManager and EnemiesManager.curentEnemy then
        return EnemiesManager.curentEnemy
    end
    -- Fallback vers variable globale ou paramètre
    return _G.currentEnemy
end

-- Détecte tous les alliés vivants pour ciblage intelligent
function CardSelectionStrategy.getAllAllies(sourceEnemy)
    local allies = {}
    if not EnemiesManager or not EnemiesManager.listeEnemies then
        return allies
    end

    for _, enemy in ipairs(EnemiesManager.listeEnemies) do
        if enemy ~= sourceEnemy and enemy.state and not enemy.state.dead and (enemy.state.life or 0) > 0 then
            table.insert(allies, enemy)
        end
    end

    -- Ajouter l'ennemi courant s'il est différent de la source et vivant
    local current = EnemiesManager.curentEnemy
    if current and current ~= sourceEnemy and current.state and not current.state.dead and (current.state.life or 0) > 0 then
        local alreadyExists = false
        for _, ally in ipairs(allies) do
            if ally == current then
                alreadyExists = true; break
            end
        end
        if not alreadyExists then
            table.insert(allies, current)
        end
    end

    return allies
end

-- Trouve le meilleur allié pour une carte de soin
function CardSelectionStrategy.findBestHealTarget(sourceEnemy, allies)
    if not allies or #allies == 0 then return nil end

    local bestAlly = nil
    local lowestHealthRatio = 1.0

    for _, ally in ipairs(allies) do
        if ally.state then
            local maxLife = tonumber(ally.state.maxLife) or 1
            local life = tonumber(ally.state.life) or 0
            local ratio = life / maxLife

            -- Priorité aux alliés blessés mais pas morts
            if ratio < lowestHealthRatio and ratio > 0 then
                lowestHealthRatio = ratio
                bestAlly = ally
            end
        end
    end

    logf("[AI] Meilleure cible soin: %s (vie: %.1f%%)",
        bestAlly and bestAlly.name or "aucune", lowestHealthRatio * 100)
    return bestAlly
end

-- ============================================================================
-- CLASSIFICATION ET ANALYSE DES CARTES
-- ============================================================================

-- Détermine le type de carte basé sur ses effets
function CardSelectionStrategy.getCardType(c)
    local eff = getEffects(c)
    local h, e = eff.hero or {}, eff.enemy or {}

    if (e.heal and e.heal > 0) then return "heal" end
    if (e.shield and e.shield > 0) or (e.epine and e.epine > 0) then return "shield" end
    if (h.attack and h.attack > 0) then return "attack" end
    if (h.skip and h.skip > 0) then return "control" end
    return "other"
end

-- Analyse une carte et retourne ses caractéristiques détaillées
function CardSelectionStrategy.analyzeCard(card, index)
    local cardType = CardSelectionStrategy.getCardType(card)
    local effects = getEffects(card)

    logf("[AI] card[%d]: name=%s type=%s  eff.hero=%s eff.enemy=%s",
        index, tostring(card.name), cardType,
        globalFunction.tstr(effects.hero), globalFunction.tstr(effects.enemy))

    return {
        i = index,
        c = card,
        t = cardType,
        eff = effects
    }
end

-- ============================================================================
-- STRATÉGIE DE SÉLECTION PRINCIPALE
-- ============================================================================

-- Fonction principale de sélection déterministe de cartes
function CardSelectionStrategy.chooseDeterministic(deck, playsRemaining)
    if not deck or #deck == 0 then return nil, nil end

    Hero = Hero or rawget(_G, "Hero")
    if not EnemiesManager then
        EnemiesManager = EnemiesManager or rawget(_G, "Enemies")
    end

    local heroActor = Hero and Hero.actor
    local enemyActor = CardSelectionStrategy.getCurrentEnemy()

    logf("[AI] status  enemy: %s", globalFunction.tstr(snap(enemyActor)))
    logf("[AI] status  hero : %s", globalFunction.tstr(snap(heroActor)))
    logf("[AI] plays remaining this turn: %d", playsRemaining or 0)

    -- Détection des alliés pour ciblage intelligent
    local allies = CardSelectionStrategy.getAllAllies(enemyActor)
    logf("[AI] alliés disponibles: %d", #allies)

    -- Analyse de toutes les cartes disponibles
    local playable = {}
    for i, card in ipairs(deck) do
        playable[#playable + 1] = CardSelectionStrategy.analyzeCard(card, i)
    end

    if #playable == 0 then
        logf("[AI] aucune carte jouable → fin de tour")
        return nil, nil
    end

    -- Vérification de la limite de jeu par tour
    if playsRemaining <= 0 then
        logf("[AI] limite de cartes atteinte ce tour → fin de tour")
        return nil, nil
    end

    -- Groupement des cartes par type pour stratégie
    local cardGroups = { heal = {}, shield = {}, attack = {}, control = {}, other = {} }
    for _, cardInfo in ipairs(playable) do
        cardGroups[cardInfo.t][#cardGroups[cardInfo.t] + 1] = cardInfo
    end

    -- Analyse de l'état du combat
    local enemyHP = lifeRatio(enemyActor)
    local heroHP = lifeRatio(heroActor)
    local enemyShield = getShield(enemyActor)

    return CardSelectionStrategy.selectBestCard(cardGroups, enemyHP, heroHP, enemyShield, allies)
end

-- ============================================================================
-- LOGIQUE DE DÉCISION STRATÉGIQUE
-- ============================================================================

-- Sélectionne la meilleure carte selon la stratégie de combat
function CardSelectionStrategy.selectBestCard(cardGroups, enemyHP, heroHP, enemyShield, allies)
    local g = cardGroups

    -- Priorité absolue : soin si l'ennemi courant est en danger critique
    if enemyHP <= 0.35 and #g.heal > 0 then
        logf("[AI] priorité: HEAL (ennemi critique: %.1f%%)", enemyHP * 100)
        return g.heal[1].i, g.heal[1].c
    end

    -- Si on a des alliés blessés et des cartes de soin, priorité au soin d'allié
    if #allies > 0 and #g.heal > 0 then
        for _, ally in ipairs(allies) do
            local allyHP = lifeRatio(ally)
            if allyHP <= 0.5 then
                logf("[AI] priorité: HEAL allié blessé '%s' (vie: %.1f%%)", ally.name or "?", allyHP * 100)
                return g.heal[1].i, g.heal[1].c
            end
        end
    end

    -- Défense préventive si l'ennemi est moyennement blessé
    if enemyHP <= 0.7 and enemyShield < 3 and #g.shield > 0 then
        logf("[AI] priorité: SHIELD (protection: vie=%.1f%%, shield=%d)", enemyHP * 100, enemyShield)
        return g.shield[1].i, g.shield[1].c
    end

    -- Attaque si le héros est en bonne forme ou si on n'a pas d'autres options
    if heroHP >= 0.6 and #g.attack > 0 then
        logf("[AI] priorité: ATTACK (héros en forme: %.1f%%)", heroHP * 100)
        return g.attack[1].i, g.attack[1].c
    end

    -- Contrôle si on a besoin de gagner du temps
    if #g.control > 0 then
        logf("[AI] priorité: CONTROL (stratégie défensive)")
        return g.control[1].i, g.control[1].c
    end

    -- Soin de sécurité si disponible
    if #g.heal > 0 then
        logf("[AI] priorité: HEAL (soin de sécurité)")
        return g.heal[1].i, g.heal[1].c
    end

    -- Protection de base
    if #g.shield > 0 then
        logf("[AI] priorité: SHIELD (protection de base)")
        return g.shield[1].i, g.shield[1].c
    end

    -- Attaque par défaut
    if #g.attack > 0 then
        logf("[AI] priorité: ATTACK (par défaut)")
        return g.attack[1].i, g.attack[1].c
    end

    -- Dernière option : autres cartes
    if #g.other > 0 then
        logf("[AI] priorité: OTHER (dernière option)")
        return g.other[1].i, g.other[1].c
    end

    logf("[AI] aucune stratégie applicable → pas de carte")
    return nil, nil
end

-- ============================================================================
-- STRATÉGIES SPÉCIALISÉES (FUTURES EXTENSIONS)
-- ============================================================================

-- Stratégie agressive : privilégie l'attaque
function CardSelectionStrategy.selectAggressive(cardGroups, enemyHP, heroHP, enemyShield, allies)
    local g = cardGroups

    -- Soin critique seulement
    if enemyHP <= 0.2 and #g.heal > 0 then
        return g.heal[1].i, g.heal[1].c
    end

    -- Attaque en priorité
    if #g.attack > 0 then
        return g.attack[1].i, g.attack[1].c
    end

    -- Fallback vers stratégie normale
    return CardSelectionStrategy.selectBestCard(cardGroups, enemyHP, heroHP, enemyShield, allies)
end

-- Stratégie défensive : privilégie la survie
function CardSelectionStrategy.selectDefensive(cardGroups, enemyHP, heroHP, enemyShield, allies)
    local g = cardGroups

    -- Soin en priorité
    if enemyHP <= 0.8 and #g.heal > 0 then
        return g.heal[1].i, g.heal[1].c
    end

    -- Protection ensuite
    if enemyShield < 5 and #g.shield > 0 then
        return g.shield[1].i, g.shield[1].c
    end

    -- Fallback vers stratégie normale
    return CardSelectionStrategy.selectBestCard(cardGroups, enemyHP, heroHP, enemyShield, allies)
end

-- Configuration des stratégies disponibles
CardSelectionStrategy.strategies = {
    balanced = CardSelectionStrategy.selectBestCard,
    aggressive = CardSelectionStrategy.selectAggressive,
    defensive = CardSelectionStrategy.selectDefensive
}

-- Stratégie par défaut
CardSelectionStrategy.currentStrategy = "balanced"

-- Fonction pour changer de stratégie
function CardSelectionStrategy.setStrategy(strategyName)
    if CardSelectionStrategy.strategies[strategyName] then
        CardSelectionStrategy.currentStrategy = strategyName
        logf("[AI] Stratégie changée: %s", strategyName)
    else
        logf("[AI] Stratégie inconnue: %s", strategyName)
    end
end

-- ============================================================================
-- SYSTÈME DE CIBLAGE INTELLIGENT
-- ============================================================================

-- Trouve le meilleur allié pour une carte de bouclier
function CardSelectionStrategy.findBestShieldTarget(sourceEnemy, allies)
    if not allies or #allies == 0 then return nil end

    local bestAlly = nil
    local lowestShield = math.huge

    for _, ally in ipairs(allies) do
        if ally.state then
            local shield = tonumber(ally.state.shield) or 0
            if shield < lowestShield then
                lowestShield = shield
                bestAlly = ally
            end
        end
    end

    logf("[AI] Meilleure cible bouclier: %s (bouclier: %d)",
        bestAlly and bestAlly.name or "aucune", lowestShield == math.huge and 0 or lowestShield)
    return bestAlly
end

-- Sélectionne intelligemment la cible pour une carte donnée
function CardSelectionStrategy.selectTargetForCard(card, sourceEnemy, heroActor)
    local eff = getEffects(card)
    local e = eff.enemy or {} -- Effets sur l'ennemi (celui qui joue la carte)
    local allies = CardSelectionStrategy.getAllAllies(sourceEnemy)

    -- Cartes de soin : priorité aux alliés blessés
    if e.heal and e.heal > 0 and #allies > 0 then
        local healTarget = CardSelectionStrategy.findBestHealTarget(sourceEnemy, allies)
        if healTarget then
            logf("[AI] Ciblage intelligent: carte soin '%s' → allié '%s'",
                card.name or "?", healTarget.name or "?")
            return healTarget
        end
    end

    -- Cartes de bouclier : priorité aux alliés vulnérables
    if e.shield and e.shield > 0 and #allies > 0 then
        local shieldTarget = CardSelectionStrategy.findBestShieldTarget(sourceEnemy, allies)
        if shieldTarget then
            logf("[AI] Ciblage intelligent: carte bouclier '%s' → allié '%s'",
                card.name or "?", shieldTarget.name or "?")
            return shieldTarget
        end
    end

    -- Cartes d'épines : priorité aux alliés offensifs
    if e.epine and e.epine > 0 and #allies > 0 then
        -- Choisir l'allié avec le plus d'attaque
        local bestAlly = allies[1]
        for _, ally in ipairs(allies) do
            if ally.state and ally.state.attack and bestAlly.state and bestAlly.state.attack then
                if ally.state.attack > bestAlly.state.attack then
                    bestAlly = ally
                end
            end
        end
        if bestAlly then
            logf("[AI] Ciblage intelligent: carte épines '%s' → allié offensif '%s'",
                card.name or "?", bestAlly.name or "?")
            return bestAlly
        end
    end

    -- Fallback : cible par défaut (héros pour attaque, soi-même pour support)
    local h = eff.hero or {}
    if h.attack and h.attack > 0 then
        logf("[AI] Ciblage par défaut: carte attaque '%s' → héros", card.name or "?")
        return heroActor
    else
        logf("[AI] Ciblage par défaut: carte support '%s' → soi-même", card.name or "?")
        return sourceEnemy
    end
end

return CardSelectionStrategy
