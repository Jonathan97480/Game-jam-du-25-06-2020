--[[
====================================
CARD STANDBY PLAY SYSTEM
====================================
Système de gestion des cartes en attente de sélection d'ennemi.
Quand le joueur joue une carte, elle passe en "standby" hors de la main
jusqu'à ce qu'il sélectionne une cible ou annule.
]] --

local CardStandbyPlay = {}

-- Modules requis
local _safeRequire = function(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local gf = _G.globalFunction or require("my-librairie/utils/globalFunction")
local responsive = _G.screen or require("my-librairie/utils/responsive")
local config = require("my-librairie/card-librairie/config") or {}
local cacheManager = _G.cache or require("my-librairie.managers.resource_cache")

-- État du système (NOUVEAU : avec copie)
CardStandbyPlay.state = {
    cardInStandby = nil,                -- Carte originale (invisible dans la main)
    standbyCopy = nil,                  -- Copie visible à gauche
    originalHandIndex = nil,            -- Index original dans la main
    standbyPosition = { x = 0, y = 0 }, -- Position de standby
    handManagementDisabled = false,     -- Gestion main désactivée
    isActive = false                    -- Système actif
}


-- Configuration
CardStandbyPlay.config = {
    standbyX = config.STANDBY.standbyX or 50,               -- Position X de standby (gauche écran)
    standbyY = config.STANDBY.standbyY or 400,              -- Position Y de standby (centre vertical)
    animationSpeed = config.STANDBY.animationSpeed or 0.15, -- Vitesse d'animation vers standby
    debugMode = config.STANDBY.DEBUG_ENABLED or false       -- Logs de debug
}

-- Fonction de log interne
local function _log(level, message)
    if CardStandbyPlay.config.debugMode and gf and gf.log then
        local prefix = "[CardStandbyPlay]"
        if level == "info" then
            gf.log.info(prefix .. " " .. message)
        elseif level == "warn" then
            gf.log.warn(prefix .. " " .. message)
        elseif level == "error" then
            gf.log.error(prefix .. " " .. message)
        end
    end
end

-- Initialisation du système
function CardStandbyPlay.init()
    _log("info", "🚀 SYSTÈME STANDBY INITIALISÉ")

    -- Calculer position de standby responsive
    if responsive then
        local screenW, screenH = love.graphics.getDimensions()
        CardStandbyPlay.config.standbyX = responsive.toScreenX(50)
        CardStandbyPlay.config.standbyY = responsive.toScreenY(screenH / 2)
    end

    return true
end

-- Vérifier si une carte est en standby
function CardStandbyPlay.hasCardInStandby()
    return CardStandbyPlay.state.isActive and CardStandbyPlay.state.cardInStandby ~= nil
end

-- Récupérer la carte en standby
function CardStandbyPlay.getStandbyCard()
    return CardStandbyPlay.state.cardInStandby
end

-- Mettre une carte en standby (NOUVEAU SYSTÈME : copie + invisible)
function CardStandbyPlay.putCardInStandby(card, originalHandIndex)
    if not card then
        _log("error", "❌ Tentative de mettre une carte nil en standby")
        return false
    end


    -- Vérifier qu'aucune carte n'est déjà en standby
    if CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Une carte est déjà en standby, annulation automatique")
        CardStandbyPlay.returnCardToHand()
    end

    _log("info", "🎯 NOUVEAU SYSTÈME STANDBY: " .. (card.name or "Inconnue"))

    -- 1. RENDRE LA CARTE ORIGINALE INVISIBLE dans la main
    card.isVisible = false
    _log("info", "👻 Carte originale rendue invisible dans la main")

    -- 2. CRÉER UNE COPIE pour le standby avec globalFunction.clone
    local gf = _G.globalFunction
    local standbyCard = nil

    if gf and gf.clone then
        standbyCard = gf.clone(card)
        _log("info", "📋 Copie créée avec globalFunction.clone")
    else
        _log("error", "[putCardInStandby] : globalFunction.clone non disponible, vérifier la fonction ou l'appel")
    end

    -- Vérifier que la copie a bien été créée avant tout accès
    if standbyCard == nil then
        _log("error", "❌ Échec de la création de la copie standby, annulation")
        card.isVisible = true -- Remettre visible
        return false
    end

    -- La copie est visible et marquée
    standbyCard.isVisible = true
    standbyCard.isStandbyCopy = true -- Marquer comme copie

    -- Assurer champs vector2/scale existants
    standbyCard.vector2 = standbyCard.vector2 or {}
    standbyCard.scale = standbyCard.scale or {}

    standbyCard.scale.x = standbyCard.scale.x or (config.STANDBY.scaleX or 0.8)
    standbyCard.scale.y = standbyCard.scale.y or (config.STANDBY.scaleY or 0.8)

    -- 4. SAUVEGARDER L'ÉTAT
    CardStandbyPlay.state.cardInStandby = card      -- Carte originale (invisible)
    CardStandbyPlay.state.standbyCopy = standbyCard -- Copie visible

    CardStandbyPlay.state.originalHandIndex = originalHandIndex or 1
    CardStandbyPlay.state.isActive = true


    -- Si la carte est self-only, lancer un timer d'auto-confirmation (2s)
    if card.self_only then
        CardStandbyPlay.state.autoTimer = config.STANDBY.AUTO_CONFIRM or 2.0

        _log("info", "⏱️ Carte self-only détectée — auto-play dans 2s: " .. tostring(card.name or "<unknown>"))
    else
        CardStandbyPlay.state.autoTimer = nil
    end

    _log("info", "✅ SYSTÈME STANDBY ACTIVÉ - Original invisible, copie visible à gauche")
    return true
end

-- Remettre la carte dans la main
-- Remettre la carte dans la main (NOUVEAU SYSTÈME : rendre visible + détruire copie)
function CardStandbyPlay.returnCardToHand()
    if not CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Aucune carte en standby à remettre")
        return false
    end

    local card = CardStandbyPlay.state.cardInStandby
    _log("info", "🔄 NOUVEAU RETOUR EN MAIN: " .. (card.name or "Inconnue"))

    -- 1. RENDRE LA CARTE ORIGINALE VISIBLE dans la main
    if card then
        card.isVisible = true
        _log("info", "���️ Carte originale redevenue visible dans la main")
    end

    -- 2. DÉTRUIRE LA COPIE (elle sera automatiquement ignorée par le rendu)
    CardStandbyPlay.state.standbyCopy = nil
    _log("info", "���️ Copie standby détruite")

    -- Nettoyer l'état
    CardStandbyPlay.clearStandby()
    return true
end

-- Confirmer le jeu de la carte (NOUVEAU SYSTÈME : appliquer invisible + détruire copie)
function CardStandbyPlay.confirmCardPlay()
    if not CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Aucune carte en standby à confirmer")
        return false
    end

    local card = CardStandbyPlay.state.cardInStandby
    _log("info", "✅ NOUVEAU JEU DE CARTE: " .. (card.name or "Inconnue"))

    -- 1. APPLIQUER LES EFFETS de la carte invisible (ici elle reste dans la main pour l'instant)
    -- L'effet sera appliqué par le système de ciblage

    -- 2. DÉTRUIRE LA COPIE STANDBY
    CardStandbyPlay.state.standbyCopy = nil
    _log("info", "🗑️ Copie standby détruite après jeu")

    -- 3. GARDER LA CARTE INVISIBLE (elle sera gérée par le système normal de jeu)
    -- Elle sera envoyée au cimetière par le système normal après application de l'effet

    -- Nettoyer l'état standby
    CardStandbyPlay.clearStandby()
    return true
end

-- Nouvelle fonction : obtenir la copie standby pour le rendu
function CardStandbyPlay.getStandbyCopy()
    return CardStandbyPlay.state.standbyCopy
end

-- Fonction d'auto-play pour les cartes self-only
function CardStandbyPlay.autoPlaySelfOnly()
    if not CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Aucune carte en standby à auto-jouer")
        return false
    end

    local card = CardStandbyPlay.state.cardInStandby
    if not card or not card.self_only then
        _log("warn", "⚠️ Carte non valide pour auto-play: " .. tostring(card.name or "<unknown>"))
        return false
    end

    _log("info", "⏳ Tentative d'auto-play self-only pour: " .. tostring(card.name or "<unknown>"))

    --[[ -- Rendre temporairement visible pour le rendu/validation
    card.isVisible = true ]]

    local ok = false

    local CardMod = _G.Card or require("my-librairie/card-librairie/card")

    if CardMod and CardMod.Play and type(CardMod.Play._cardPlaySelf) == "function" then
        -- Déterminer la source selon actorTag
        local source = nil
        if card.actorTag == 'Hero' then
            source = _G.Hero and _G.Hero.actor
        else
            _log("warn", "⚠️ ActorTag non-Hero soit l'actor est vide soit elle pas le type Hero")
            return false
        end

        ok = CardMod.Play._cardPlaySelf(card, source)
    else
        _log("error", "Card.Play._cardPlaySelf non disponible pour auto-play")
    end

    if ok then
        _log("info", "✅ Auto-play réussi pour: " .. tostring(card.name or "<unknown>"))
        CardStandbyPlay.confirmCardPlay()
        return true
    else
        _log("warn", "❌ Auto-play échoué pour: " .. tostring(card.name or "<unknown>") .. " — remise en main")
        card.isVisible = false
        CardStandbyPlay.returnCardToHand()
        return false
    end
end

-- Nettoyer l'état de standby
function CardStandbyPlay.clearStandby()
    _log("info", "🧹 NETTOYAGE ÉTAT STANDBY")
    CardStandbyPlay.state.cardInStandby = nil
    CardStandbyPlay.state.standbyCopy = nil -- Nettoyer aussi la copie
    CardStandbyPlay.state.originalHandIndex = nil
    CardStandbyPlay.state.isActive = false
end

-- Gérer les clics pour annulation ou joueur de carte (NOUVEAU SYSTÈME)
function CardStandbyPlay.handleClick(x, y, button)
    if not CardStandbyPlay.hasCardInStandby() then
        return false -- Pas en mode standby
    end

    if button == 1 then -- Clic gauche
        _log("info", "🖱️ Clic gauche détecté en mode standby")

        -- PREMIÈRE VÉRIFICATION: Est-ce un clic sur un ennemi ?
        local CardTargetSelection = _G.CardTargetSelection
        if CardTargetSelection and CardTargetSelection.findHoveredEnemyAt then
            local enemy = CardTargetSelection.findHoveredEnemyAt(x, y)
            if enemy then
                _log("info", "🎯 ENNEMI DÉTECTÉ: " .. (enemy.name or "Inconnu") .. " - JOUER LA CARTE")

                -- IMPORTANT: Jouer la carte invisible depuis la main
                if CardTargetSelection.handleMouseClick then
                    _log("info", "📞 Appel CardTargetSelection.handleMouseClick pour jouer la carte")

                    -- NOUVEAU : Rendre la carte invisible visible temporairement pour le jeu
                    local originalCard = CardStandbyPlay.state.cardInStandby
                    if originalCard then
                        originalCard.isVisible = true -- Temporairement visible pour le jeu
                    end

                    local success = CardTargetSelection.handleMouseClick(x, y, button)
                    if success then
                        _log("info", "✅ Carte jouée avec succès sur ennemi")
                        -- Confirmer le jeu (détruit la copie standby)
                        CardStandbyPlay.confirmCardPlay()
                        return true -- Carte jouée, événement géré
                    else
                        _log("error", "❌ Échec du jeu de carte sur ennemi")
                        -- En cas d'échec, remettre invisible et remettre en main
                        if originalCard then
                            originalCard.isVisible = false
                        end
                        CardStandbyPlay.returnCardToHand()
                        return true
                    end
                else
                    _log("error", "❌ CardTargetSelection.handleMouseClick non disponible")
                    -- Fallback: remettre en main
                    CardStandbyPlay.returnCardToHand()
                    return true
                end
            else
                -- Clic hors ennemi - carte reste en standby (pas de log spam)
                return false -- Laisser passer le clic, ne pas remettre en main
            end
        else
            _log("warn", "⚠️ CardTargetSelection non disponible pour détecter ennemi")
            return false    -- Laisser passer le clic, ne pas remettre en main
        end
    elseif button == 2 then -- Clic droit = annulation
        _log("info", "🖱️ Clic droit - ANNULATION et remise en main")
        CardStandbyPlay.returnCardToHand()
        return true -- Événement géré
    end

    return false
end

-- Mise à jour (pour animations)
function CardStandbyPlay.update(dt)
    if not CardStandbyPlay.hasCardInStandby() then
        return
    end

    -- Animer la copie standby si elle existe (utiliser vector2/target pour cohérence)
    local standby = CardStandbyPlay.state.standbyCopy
    if standby then
        standby.vector2 = standby.vector2 or { x = CardStandbyPlay.config.standbyX, y = CardStandbyPlay.config.standbyY }
        standby._targetPos = standby._targetPos or { x = standby.vector2.x, y = standby.vector2.y }
        -- Si un target est défini, lerp vers celui-ci
        local speed = config.STANDBY.animationSpeed or 0.15
        if standby.target and standby.target.x and standby.target.y then
            standby._targetPos.x = config.STANDBY.standbyX or 50
            standby._targetPos.y = config.STANDBY.standbyY or 50
        end
        -- Safely interpolate numeric values. globalFunction.lerp expects tables; use lerpNum for scalars.
        local actualDt = dt or rawget(_G, "Delta") or 0.016
        local coef = math.min(1, (speed or 0.15) * actualDt)
        if gf and gf.lerpNum then
            standby.vector2.x = gf.lerpNum(standby.vector2.x or standby._targetPos.x, standby._targetPos.x, coef)
            standby.vector2.y = gf.lerpNum(standby.vector2.y or standby._targetPos.y, standby._targetPos.y, coef)
        else
            standby.vector2.x = standby._targetPos.x
            standby.vector2.y = standby._targetPos.y
        end
    end

    -- Gestion du timer d'auto-play pour les cartes self-only
    if CardStandbyPlay.state.autoTimer then
        CardStandbyPlay.state.autoTimer = CardStandbyPlay.state.autoTimer - (dt or 0)
        if CardStandbyPlay.state.autoTimer <= 0 then
            -- Tenter l'auto-play
            CardStandbyPlay.state.autoTimer = nil
            CardStandbyPlay.autoPlaySelfOnly()
        end
    end
end

-- Rendu de la carte en standby
function CardStandbyPlay.draw()
    if not CardStandbyPlay.hasCardInStandby() then
        return
    end

    local card = CardStandbyPlay.getStandbyCopy()
    if card and card.vector2 then
        -- Dessiner la carte en standby avec un effet visuel


        -- Légère transparence pour indiquer l'état standby
        love.graphics.setColor(1, 1, 1, 0.8)

        -- Dessiner la carte (utiliser le système de rendu existant)
        local cardRender = require("my-librairie.card-librairie.play.anim")
        if cardRender and cardRender.drawSingleCard then
            cardRender.drawSingleCard(card)
        end

        -- Indicateur visuel "EN ATTENTE"
        love.graphics.setColor(1, 1, 0, 0.7) -- Jaune semi-transparent
        local font = cacheManager.font(config.STANDBY.fontPath, config.STANDBY.fontSize or 20)
        love.graphics.setFont(font)
        love.graphics.printf("EN ATTENTE", card.vector2.x + 50, card.vector2.y - 300, 100, "center")


        love.graphics.setColor(1, 1, 1, 1) -- Reset couleur
    end
end

return CardStandbyPlay
