-- my-librairie/ai/card_selection_strategy.lua
-- Module de stratégie de sélection de cartes et de ciblage pour l'IA
-- Sépare la logique de décision du controller principal pour une meilleure lisibilité


local globalFunction = _G.globalFunction or require("my-librairie.utils.globalFunction")
local Card = _G.Card or rawget(_G, "Card") or rawget(_G, "card")
local Hero = _G.Hero or rawget(_G, "Hero")
local EnemiesManager = require("my-librairie/ActorScripts/Enemy/Enemies")
local TransitionCombat = _G.TransitionCombat or require("my-librairie/transitions/templateCombatTransition")

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
    if EnemiesManager and EnemiesManager.listeEnemies then
        return EnemiesManager.listeEnemies[TransitionCombat.enemyIndex] or nil
    end
    -- Fallback vers variable globale ou paramètre
    return nil
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

return CardSelectionStrategy
