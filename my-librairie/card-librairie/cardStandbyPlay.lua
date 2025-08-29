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

local gf = _G.globalFunction
local responsive = _safeRequire("my-librairie/responsive")

-- État du système
CardStandbyPlay.state = {
    cardInStandby = nil,                -- Carte actuellement en standby
    originalHandIndex = nil,            -- Index original dans la main
    standbyPosition = { x = 0, y = 0 }, -- Position de standby
    handManagementDisabled = false,     -- Gestion main désactivée
    isActive = false                    -- Système actif
}

-- Configuration
CardStandbyPlay.config = {
    standbyX = 10,         -- Position X de standby (test : coin supérieur gauche)
    standbyY = 10,         -- Position Y de standby (test : coin supérieur gauche)
    animationSpeed = 0.15, -- Vitesse d'animation vers standby
    debugMode = true       -- Logs de debug
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

    -- Position de test fixe
    CardStandbyPlay.config.standbyX = 10 -- Test coin supérieur gauche
    CardStandbyPlay.config.standbyY = 10
    _log("info",
        "📍 Position standby TEST: (" .. CardStandbyPlay.config.standbyX .. ", " .. CardStandbyPlay.config.standbyY .. ")")

    return true
end -- Vérifier si une carte est en standby

function CardStandbyPlay.hasCardInStandby()
    return CardStandbyPlay.state.isActive and CardStandbyPlay.state.cardInStandby ~= nil
end

-- Récupérer la carte en standby
function CardStandbyPlay.getStandbyCard()
    return CardStandbyPlay.state.cardInStandby
end

-- Mettre une carte en standby
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

    _log("info", "🎯 CARTE EN STANDBY: " .. (card.name or "Inconnue"))

    -- Sauvegarder l'état
    CardStandbyPlay.state.cardInStandby = card
    CardStandbyPlay.state.originalHandIndex = originalHandIndex or 1
    CardStandbyPlay.state.isActive = true

    -- Retirer la carte de la main
    local Card = _G.Card
    if Card and Card.hand and Card.hand.cards then
        for i, handCard in ipairs(Card.hand.cards) do
            if handCard == card then
                table.remove(Card.hand.cards, i)
                CardStandbyPlay.state.originalHandIndex = i
                _log("info", "📤 Carte retirée de la main (index " .. i .. ")")
                break
            end
        end
    end

    -- Positionner la carte en standby
    CardStandbyPlay.state.standbyPosition.x = CardStandbyPlay.config.standbyX
    CardStandbyPlay.state.standbyPosition.y = CardStandbyPlay.config.standbyY

    -- Animer vers la position de standby
    if card.vector2 then
        _log("info", "📍 Position carte AVANT: (" .. card.vector2.x .. ", " .. card.vector2.y .. ")")
        card.targetPosition = {
            x = CardStandbyPlay.state.standbyPosition.x,
            y = CardStandbyPlay.state.standbyPosition.y
        }
        _log("info",
            "🎬 Animation vers standby: (" ..
            CardStandbyPlay.state.standbyPosition.x .. ", " .. CardStandbyPlay.state.standbyPosition.y .. ")")
    else
        _log("error", "❌ Carte sans position ! Impossible d'animer")
    end

    -- Désactiver la gestion de la main
    CardStandbyPlay.disableHandManagement()

    -- NOUVEAU: Activer automatiquement le système de ciblage pour les cartes qui en ont besoin
    local CardTargetSelection = _G.CardTargetSelection
    if CardTargetSelection and CardTargetSelection.startTargetSelection then
        -- Vérifier si la carte nécessite un ciblage (basé sur ses effets)
        local needsTargeting = false
        if card.effect and card.effect.target and card.effect.target == "enemy" then
            needsTargeting = true
        elseif card.name and (string.find(card.name:lower(), "attaque") or string.find(card.name:lower(), "frappe")) then
            needsTargeting = true -- Fallback pour cartes d'attaque
        end

        if needsTargeting then
            _log("info", "🎯 Activation du système de ciblage pour carte: " .. (card.name or "Inconnue"))
            local success = CardTargetSelection.startTargetSelection(card)
            _log("info", "📊 startTargetSelection retourné: " .. tostring(success))
        else
            _log("info", "⚪ Carte ne nécessite pas de ciblage")
        end
    else
        _log("warn", "⚠️ CardTargetSelection non disponible pour activation automatique")
    end

    return true
end

-- Remettre la carte dans la main
function CardStandbyPlay.returnCardToHand()
    if not CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Aucune carte en standby à remettre")
        return false
    end

    local card = CardStandbyPlay.state.cardInStandby
    local originalIndex = CardStandbyPlay.state.originalHandIndex or 1

    _log("info", "🔄 RETOUR EN MAIN: " .. (card.name or "Inconnue") .. " (index " .. originalIndex .. ")")

    -- Remettre la carte dans la main
    local Card = _G.Card
    if Card and Card.hand and Card.hand.cards then
        table.insert(Card.hand.cards, originalIndex, card)
        _log("info", "📥 Carte remise en main (index " .. originalIndex .. ")")

        -- Déclencher repositionnement de la main
        local common = _safeRequire("my-librairie/card-librairie/core/common")
        if common and common._updateHandTargets then
            common._updateHandTargets()
            _log("info", "🔄 Repositionnement main déclenché")
        end
    end

    -- Réactiver la gestion de la main
    CardStandbyPlay.enableHandManagement()

    -- Nettoyer l'état
    CardStandbyPlay.clearStandby()

    return true
end

-- Confirmer le jeu de la carte (aller au cimetière)
function CardStandbyPlay.confirmCardPlay()
    if not CardStandbyPlay.hasCardInStandby() then
        _log("warn", "⚠️ Aucune carte en standby à confirmer")
        return false
    end

    local card = CardStandbyPlay.state.cardInStandby
    _log("info", "✅ CONFIRMATION JEU: " .. (card.name or "Inconnue"))

    -- Envoyer au cimetière via le système normal
    local Card = _G.Card
    if Card and Card.graveyard then
        table.insert(Card.graveyard, card)
        _log("info", "⚰️ Carte envoyée au cimetière")
    end

    -- Réactiver la gestion de la main
    CardStandbyPlay.enableHandManagement()

    -- Nettoyer l'état
    CardStandbyPlay.clearStandby()

    return true
end

-- Désactiver la gestion de la main
function CardStandbyPlay.disableHandManagement()
    CardStandbyPlay.state.handManagementDisabled = true
    _log("info", "🚫 GESTION MAIN DÉSACTIVÉE")

    -- Utiliser le système dragLock existant
    local Common = _safeRequire("my-librairie/card-librairie/core/common")
    if Common then
        Common.__dragLock = true
        _log("info", "🔒 Common.__dragLock = true (désactivation drag & drop)")
    else
        _log("error", "❌ Impossible d'accéder à Common pour désactiver dragLock")
    end
end

-- Réactiver la gestion de la main
function CardStandbyPlay.enableHandManagement()
    CardStandbyPlay.state.handManagementDisabled = false
    _log("info", "✅ GESTION MAIN RÉACTIVÉE")

    -- Réactiver le système dragLock
    local Common = _safeRequire("my-librairie/card-librairie/core/common")
    if Common then
        Common.__dragLock = false
        _log("info", "🔓 Common.__dragLock = false (réactivation drag & drop)")
    else
        _log("error", "❌ Impossible d'accéder à Common pour réactiver dragLock")
    end
end

-- Vérifier si la gestion de la main est désactivée
function CardStandbyPlay.isHandManagementDisabled()
    return CardStandbyPlay.state.handManagementDisabled
end

-- Nettoyer l'état de standby
function CardStandbyPlay.clearStandby()
    _log("info", "🧹 NETTOYAGE ÉTAT STANDBY")
    CardStandbyPlay.state.cardInStandby = nil
    CardStandbyPlay.state.originalHandIndex = nil
    CardStandbyPlay.state.isActive = false
end

-- Gérer les clics pour annulation
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

                -- IMPORTANT: NE PAS remettre la carte en main, la jouer directement !
                if CardTargetSelection.handleMouseClick then
                    _log("info", "📞 Appel CardTargetSelection.handleMouseClick pour jouer la carte")
                    local success = CardTargetSelection.handleMouseClick(x, y, button)
                    if success then
                        _log("info", "✅ Carte jouée avec succès sur ennemi")
                        return true -- Carte jouée, événement géré
                    else
                        _log("error", "❌ Échec du jeu de carte sur ennemi")
                        -- En cas d'échec, remettre en main comme fallback
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
                _log("info", "🚫 Aucun ennemi détecté au clic")
            end
        else
            _log("warn", "⚠️ CardTargetSelection non disponible pour détecter ennemi")
        end

        -- Si on arrive ici: clic hors ennemi = annulation et remise en main
        _log("info", "❌ Clic hors ennemi - ANNULATION et remise en main")
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

    local card = CardStandbyPlay.state.cardInStandby
    if card and card.targetPosition and card.vector2 then
        -- Animation simple vers la position cible
        local speed = CardStandbyPlay.config.animationSpeed
        card.vector2.x = gf and gf.lerp and gf.lerp(card.vector2.x, card.targetPosition.x, speed) or
            card.targetPosition.x
        card.vector2.y = gf and gf.lerp and gf.lerp(card.vector2.y, card.targetPosition.y, speed) or
            card.targetPosition.y
    end
end

-- Rendu de la carte en standby
-- Fonction de rendu de la carte en standby
function CardStandbyPlay.draw()
    -- Vérifier si une carte est en standby avant de dessiner
    if not CardStandbyPlay.hasCardInStandby() then
        return
    end

    local card = CardStandbyPlay.state.cardInStandby

    -- Vérifier que la carte a les propriétés nécessaires
    if not card or not card.vector2 or not card.canvas then
        _log("error", "❌ Carte en standby manquante ou propriétés incomplètes")
        return
    end
    _G.globalFunction.log.info("Position standby:" .. card.vector2.x .. ' ' .. card.vector2.y)
    -- Dessiner la carte avec son positionnement actuel
    -- (Utilise le système de rendu existant pour la carte)
    love.graphics.draw(card.canvas, card.vector2.x, card.vector2.y)


    -- Indicateur visuel "EN ATTENTE" avec un effet jaune
    love.graphics.setColor(1, 1, 0, 0.7) -- Jaune semi-transparent

    -- Positionner le texte au centre de la carte
    -- Calcul de la position en fonction de la taille de la carte
    local textX = card.vector2.x
    local textY = card.vector2.y - (card.height / 2) -- Position au-dessus

    -- Dessiner le texte "EN ATTENTE" centré
    love.graphics.setFont(love.graphics.getFont()) -- Utiliser la police par défaut
    love.graphics.printf("EN ATTENTE", textX, textY, card.width, "center")

    -- Réinitialiser la couleur pour les dessins suivants
    love.graphics.setColor(1, 1, 1, 1)
end

-- Debug: afficher l'état
function CardStandbyPlay.dumpState()
    local state = CardStandbyPlay.state
    print("=== ÉTAT CARDSTANDBYPLAY ===")
    print("Actif:", state.isActive)
    print("Carte en standby:", state.cardInStandby and state.cardInStandby.name or "Aucune")
    print("Index original:", state.originalHandIndex)
    print("Position standby:", state.standbyPosition.x .. ", " .. state.standbyPosition.y)
    print("Gestion main désactivée:", state.handManagementDisabled)
    print("===========================")
end

return CardStandbyPlay
