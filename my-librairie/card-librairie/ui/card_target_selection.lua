-- my-librairie/card-librairie/ui/card_target_selection.lua
-- Module de gestion de sélection de cibles pour le système de ciblage multi-ennemis
-- Permet au joueur de sélectionner manuellement l'ennemi cible lors du jeu d'une carte

-- Dependencies (utilise _safeRequire centralisée)
local globalFunction = _G.globalFunction or _G._safeRequire("my-librairie.utils.globalFunction")

-- Import du nouveau CardManager
local CardManager = _G._safeRequire("my-librairie/card-librairie/card_manager")

-- Module principal
local CardTargetSelection = {}

-- Configuration Debug - Réduction verbosité (Problem #4)
CardTargetSelection.DEBUG = rawget(_G, "DEBUG_TARGET_SELECTION") or false       -- Configurable globalement
CardTargetSelection.DEBUG_VERBOSE = rawget(_G, "DEBUG_TARGET_VERBOSE") or false -- Logs ultra-détaillés

-- Debug de chargement uniquement si verbose activé
if CardTargetSelection.DEBUG_VERBOSE then
    print("[LOADING] CardTargetSelection module chargé - VERSION DEBUG!")
end

-- ============================================================================
-- VARIABLES D'ÉTAT GLOBALES
-- ============================================================================

-- État principal du système de sélection
CardTargetSelection.isSelectingTarget = false  -- Mode sélection actif
CardTargetSelection.selectedTarget = nil       -- Ennemi sélectionné
CardTargetSelection.hoveredEnemy = nil         -- Ennemi actuellement survolé
CardTargetSelection.cardBeingPlayed = nil      -- Carte en cours de jeu
CardTargetSelection.animationCompleted = false -- Flag pour éviter le spam de logs

-- Configuration visuelle
CardTargetSelection.config = {
    -- Couleurs des contours (RGBA)
    hoverColor = { 1, 1, 0, 0.8 },      -- Jaune pour survol
    selectableColor = { 1, 1, 1, 0.5 }, -- Blanc transparent pour sélectionnable
    selectedColor = { 0, 1, 0, 1 },     -- Vert pour confirmé

    -- Épaisseurs des contours
    hoverLineWidth = 3,
    selectableLineWidth = 2,
    selectedLineWidth = 4,

    -- Animation carte
    cardTargetPosition = { x = 100, y = nil }, -- Position à gauche (y calculé dynamiquement)
    cardSelectScale = { x = 1.2, y = 1.2 },    -- Échelle pendant sélection
    animationSpeed = 10,                       -- Vitesse lerp animation

    -- Détection souris
    mouseDetection = {
        enabled = true,             -- Active/désactive la détection souris
        hoverCheckInterval = 0.016, -- 60 FPS
        clickHoldTime = 0.1,        -- Délai pour distinguer clic/maintien
        maxClickDistance = 10       -- Distance max entre press/release
    }
}

-- Debug et logging avec niveaux de verbosité (Problem #4 Fix)
CardTargetSelection.DEBUG = rawget(_G, "DEBUG_TARGET_SELECTION") or false       -- Configurable via globale
CardTargetSelection.DEBUG_VERBOSE = rawget(_G, "DEBUG_TARGET_VERBOSE") or false -- Logs ultra-détaillés
CardTargetSelection.stats = {
    selectionsStarted = 0,
    selectionsCompleted = 0,
    selectionsCancelled = 0,
    hoversDetected = 0
}

-- Anti-spam pour les logs répétitifs
CardTargetSelection._lastLoggedPosition = nil
CardTargetSelection._lastLoggedTime = 0
CardTargetSelection._logSpamInterval = 0.5 -- Limite: 1 log par 500ms pour position

-- ============================================================================
-- UTILITAIRES ET LOGGING
-- ============================================================================

-- Fonction de logging avec anti-spam intégré
local function _logf(fmt, ...)
    if not CardTargetSelection.DEBUG then return end

    local text = string.format("[CardTargetSelection] " .. fmt, ...)

    -- Anti-spam pour les logs de position/hover fréquents
    local isPositionLog = text:match("findHoveredEnemyAt") or text:match("vérification.*ennemis") or
        text:match("getEnemyList")
    if isPositionLog and not CardTargetSelection.DEBUG_VERBOSE then
        local currentTime = os.clock()
        if CardTargetSelection._lastLoggedTime and
            (currentTime - CardTargetSelection._lastLoggedTime) < CardTargetSelection._logSpamInterval then
            return -- Skip ce log pour éviter le spam
        end
        CardTargetSelection._lastLoggedTime = currentTime
    end

    print(text) -- DEBUG temporaire
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(text)
    end
end

local function _logError(fmt, ...)
    local text = string.format("[CardTargetSelection ERROR] " .. fmt, ...)
    if globalFunction and globalFunction.log and globalFunction.log.error then
        globalFunction.log.error(text)
    else
        print("ERROR: " .. text)
    end
end

local function _getCursor()
    -- PRIORITÉ 1: Utiliser le système responsive pour les coordonnées converties
    local responsive = _G.screen or require("my-librairie.utils.responsive")
    if responsive and responsive.mouse then
        return responsive.mouse.X, responsive.mouse.Y
    end

    -- PRIORITÉ 2: Tenter de calculer manuellement la conversion
    if love and love.mouse and love.mouse.getPosition then
        local rawX, rawY = love.mouse.getPosition()
        local currentW, currentH = love.graphics.getDimensions()

        -- Ratio de conversion (résolution actuelle / résolution de référence)
        local gameResoW, gameResoH = 1920, 1080 -- Résolution de référence
        local ratioX = currentW / gameResoW
        local ratioY = currentH / gameResoH

        -- Conversion des coordonnées
        local convertedX = rawX / ratioX
        local convertedY = rawY / ratioY

        _logf("[CURSOR] Conversion souris: brut(%d,%d) → converti(%d,%d) ratio(%.3f,%.3f)",
            rawX, rawY, convertedX, convertedY, ratioX, ratioY)

        return convertedX, convertedY
    end

    -- Fallback pour tests
    return 0, 0
end

-- Helper pour accéder au système de dragLock sans dépendance circulaire
local function _setDragLock(state)
    if CardTargetSelection.DEBUG_VERBOSE then
        _logf("🔴 DEBUG: _setDragLock DÉSACTIVÉE - tentative de %s", state and "activation" or "désactivation")
        _logf("🔴 DEBUG: Le dragLock n'est pas modifié pour observation")
    end

    -- DÉSACTIVÉ TEMPORAIREMENT POUR DEBUG
    --[[ FONCTIONNALITÉ ORIGINALE COMMENTÉE
    -- Essaie d'abord via _G.Card
    local Card = _G.Card or rawget(_G, 'Card')
    if Card and Card.hand and Card.hand.cards then
        -- Accès via Common à travers Card
        local Common = rawget(Card, '_common') or rawget(Card, 'common')
        if Common then
            Common.__dragLock = state
            _logf("🔒 DragLock %s via Card.Common", state and "activé" or "désactivé")
            return true
        end
    end

    -- Essaie directement via require si disponible
    local Common = _G._safeRequire("my-librairie/card-librairie/core/common")
    if Common then
        Common.__dragLock = state
        _logf("🔒 DragLock %s via require Common", state and "activé" or "désactivé")
        return true
    end

    _logf("⚠️ Impossible d'accéder au dragLock")
    return false
    --]]

    return true -- Simuler un succès pour ne pas casser la logique
end

-- ============================================================================
-- GESTION D'ÉTAT DU MODULE
-- ============================================================================

-- Initialise le module (appelé au chargement)
function CardTargetSelection.init()
    _logf("Module CardTargetSelection initialisé")
    CardTargetSelection.reset()

    -- Calculer position Y dynamique pour la carte
    if love and love.graphics and love.graphics.getHeight then
        CardTargetSelection.config.cardTargetPosition.y = love.graphics.getHeight() / 2
    else
        CardTargetSelection.config.cardTargetPosition.y = 400 -- Fallback
    end

    _logf("Position carte cible: x=%d, y=%d",
        CardTargetSelection.config.cardTargetPosition.x,
        CardTargetSelection.config.cardTargetPosition.y)
end

-- Remet à zéro l'état du module
function CardTargetSelection.reset(keepDragLock)
    _logf("Reset état module (keepDragLock=%s)", tostring(keepDragLock))

    -- Récupérer la carte qui était en cours de ciblage
    local card = CardTargetSelection.cardBeingPlayed
    local success = keepDragLock -- keepDragLock indique généralement un succès

    -- NOUVEAU : Notifier CardManager de la fin de ciblage
    if CardManager and card then
        CardManager.onTargetingEnd(card, success)
    end

    -- DÉSACTIVER LE LOCK pour permettre le repositionnement normal
    -- SAUF si keepDragLock=true (carte jouée avec succès)
    if not keepDragLock then
        _setDragLock(false)
        _logf("DragLock désactivé - carte peut retourner en main")
    else
        _logf("DragLock conservé - carte reste en jeu")
    end

    CardTargetSelection.isSelectingTarget = false
    CardTargetSelection.selectedTarget = nil
    CardTargetSelection.hoveredEnemy = nil
    CardTargetSelection.cardBeingPlayed = nil
    CardTargetSelection.animationCompleted = false -- Reset du flag d'animation
end

-- Nettoyage complet (pour transitions de scène)
function CardTargetSelection.cleanup()
    _logf("Cleanup module pour transition scène")

    -- DÉSACTIVER LE LOCK avant le reset
    _setDragLock(false)
    CardTargetSelection.reset()
    -- Restaurer état cartes si nécessaire
    if CardTargetSelection.cardBeingPlayed then
        CardTargetSelection._restoreCardToHand(CardTargetSelection.cardBeingPlayed)
        CardTargetSelection.cardBeingPlayed = nil
    end
end

-- ============================================================================
-- GESTION DES STATISTIQUES ET DEBUG
-- ============================================================================

function CardTargetSelection.getStats()
    return {
        isActive = CardTargetSelection.isSelectingTarget,
        currentCard = CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "aucune",
        hoveredEnemy = CardTargetSelection.hoveredEnemy and CardTargetSelection.hoveredEnemy.name or "aucun",
        selectedTarget = CardTargetSelection.selectedTarget and CardTargetSelection.selectedTarget.name or "aucune",
        stats = CardTargetSelection.stats
    }
end

function CardTargetSelection.printStats()
    local stats = CardTargetSelection.getStats()
    _logf("=== STATS CIBLAGE ===")
    _logf("Mode actif: %s", tostring(stats.isActive))
    _logf("Carte courante: %s", stats.currentCard)
    _logf("Ennemi survolé: %s", stats.hoveredEnemy)
    _logf("Cible sélectionnée: %s", stats.selectedTarget)
    _logf("Sélections démarrées: %d", stats.stats.selectionsStarted)
    _logf("Sélections complétées: %d", stats.stats.selectionsCompleted)
    _logf("Sélections annulées: %d", stats.stats.selectionsCancelled)
    _logf("Survols détectés: %d", stats.stats.hoversDetected)
    _logf("====================")
end

-- ============================================================================
-- FONCTIONS DE BASE (INTERFACE PUBLIQUE)
-- ============================================================================

-- Démarre le mode sélection de cible pour une carte donnée
function CardTargetSelection.startTargetSelection(card)
    if not card then
        _logError("startTargetSelection appelé sans carte")
        return false
    end

    if CardTargetSelection.isSelectingTarget then
        _logf("Sélection déjà en cours pour carte '%s', annulation précédente",
            CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "inconnue")
        CardTargetSelection.cancelSelection()
    end

    _logf("Démarrage sélection cible pour carte: %s", card.name or "sans nom")

    CardTargetSelection.isSelectingTarget = true
    CardTargetSelection.cardBeingPlayed = card
    CardTargetSelection.selectedTarget = nil
    CardTargetSelection.hoveredEnemy = nil
    CardTargetSelection.animationCompleted = false -- Reset du flag d'animation
    CardTargetSelection.stats.selectionsStarted = CardTargetSelection.stats.selectionsStarted + 1

    -- NOUVEAU : Notifier CardManager du début de ciblage
    if CardManager then
        CardManager.onTargetingStart(card)
    end

    -- ACTIVER LE LOCK pour empêcher le repositionnement automatique des cartes
    _setDragLock(true)

    -- Déclencher animation carte vers la gauche
    CardTargetSelection.animateCardToLeft(card)

    _logf("Mode sélection activé avec succès")
    return true
end

-- Annule la sélection en cours
function CardTargetSelection.cancelSelection()
    if not CardTargetSelection.isSelectingTarget then
        _logf("cancelSelection appelé mais aucune sélection en cours")
        return false
    end

    _logf("Annulation sélection pour carte: %s",
        CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "inconnue")

    -- NOUVEAU : Remettre la carte en main via CardStandbyPlay
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay and CardStandbyPlay.hasCardInStandby() then
        local success = CardStandbyPlay.returnCardToHand()
        _logf("Carte remise en main via CardStandbyPlay: %s", tostring(success))
    else
        -- Fallback : ancien système
        _setDragLock(false)
        if CardTargetSelection.cardBeingPlayed then
            CardTargetSelection._restoreCardToHand(CardTargetSelection.cardBeingPlayed)
        end
    end

    CardTargetSelection.stats.selectionsCancelled = CardTargetSelection.stats.selectionsCancelled + 1
    CardTargetSelection.reset(true) -- keepDragLock = true car CardStandbyPlay gère le lock

    _logf("Sélection annulée avec succès")
    return true
end

-- Sélectionne une cible et finalise le processus
function CardTargetSelection.selectTarget(enemy)
    _logf("🎯 [SELECTTARGET APPELÉ] Début sélection cible...")
    _logf("📊 État isSelectingTarget: %s", tostring(CardTargetSelection.isSelectingTarget))
    _logf("📊 Ennemi fourni: %s", enemy and enemy.name or "AUCUN")
    _logf("📊 Carte en cours: %s",
        CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "AUCUNE")

    if not CardTargetSelection.isSelectingTarget then
        _logError("selectTarget appelé mais aucune sélection en cours")
        _logError("❌ [SELECTTARGET] ÉCHEC: Aucune sélection en cours")
        return false
    end

    if not enemy then
        _logError("selectTarget appelé sans ennemi")
        _logError("❌ [SELECTTARGET] ÉCHEC: Ennemi manquant")
        return false
    end

    _logf("Sélection cible confirmée: %s pour carte: %s",
        enemy.name or "ennemi sans nom",
        CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "carte sans nom")

    _logf("🎯 [SELECTTARGET] Assignation cible...")
    -- CORRECTION CRITIQUE: Assigner la cible AVANT d'appeler _executeCardPlay
    CardTargetSelection.selectedTarget = enemy
    CardTargetSelection.stats.selectionsCompleted = CardTargetSelection.stats.selectionsCompleted + 1

    -- IMPORTANT: Assigner aussi la cible directement à la carte pour tryPlay()
    if CardTargetSelection.cardBeingPlayed then
        CardTargetSelection.cardBeingPlayed.selectedTarget = enemy
        _logf("🎯 Cible assignée à la carte AVANT tryPlay: %s", enemy.name or "?")
        _logf("🎯 [SELECTTARGET] Cible assignée à la carte: %s", enemy.name or "?")
    end

    _logf("🚀 [SELECTTARGET] Appel _executeCardPlay...")
    -- Déclencher le jeu de la carte avec la cible sélectionnée
    local success = CardTargetSelection._executeCardPlay()
    _logf("📊 [SELECTTARGET] Résultat _executeCardPlay: %s", tostring(success))

    if success then
        _logf("Carte jouée avec succès sur cible sélectionnée")

        -- MARQUER LA CARTE COMME JOUÉE pour empêcher le repositionnement automatique
        if CardTargetSelection.cardBeingPlayed then
            CardTargetSelection.cardBeingPlayed._playing = true
            _logf("🏷️ Carte marquée _playing=true pour éviter repositionnement: %s",
                CardTargetSelection.cardBeingPlayed.name or "?")
        end

        -- IMPORTANT: Garder le lock pour empêcher la carte de retourner en main
        CardTargetSelection.reset(true) -- keepDragLock = true
    else
        _logError("Échec du jeu de carte, restoration état")
        CardTargetSelection.cancelSelection()
    end

    return success
end

-- ============================================================================
-- DÉTECTION DE COLLISION AVEC ENNEMIS (ÉTAPE 2)
-- ============================================================================

-- Obtient la liste des ennemis actuelle (compatible EnemiesG et Enemies)
-- Récupère la liste des ennemis à cibler, compatible avec plusieurs architectures d'ennemis
function CardTargetSelection.getEnemyList()
    -- Diagnostic : tente de récupérer le gestionnaire d'ennemis global
    local enemiesManager = _G.Enemies or require("my-librairie.entities.Enemy.Enemies")

    -- Debug réduit : logs seulement en mode verbose
    if CardTargetSelection.DEBUG_VERBOSE then
        _logf("🔍 [getEnemyList] Gestionnaire trouvé : %s", enemiesManager and tostring(enemiesManager) or "nil")
        if enemiesManager and enemiesManager.listeEnemies then
            _logf("    .listeEnemies présent (%d ennemis)", #enemiesManager.listeEnemies)
        else
            _logf("    .listeEnemies absent ou vide")
        end
    end

    -- Retourne la liste des ennemis si disponible, sinon une table vide
    if enemiesManager and type(enemiesManager.listeEnemies) == "table" then
        return enemiesManager.listeEnemies
    end

    _logError("Aucun gestionnaire d'ennemis valide trouvé (Enemies/EnemiesG/__ENEMY_SINGLETON__)")
    return {}
end

function CardTargetSelection.detectEnemyHover(enemy, mouseX, mouseY)
    if not enemy then
        if CardTargetSelection.DEBUG_VERBOSE then
            _logf("[ENEMY DEBUG] Enemy est nil")
        end
        return false
    end

    -- Logs de debug des ennemis seulement en mode VERBOSE
    if CardTargetSelection.DEBUG_VERBOSE then
        _logf("[ENEMY DEBUG] Check: %s at vector2(%s,%s)",
            enemy.name or "unnamed",
            tostring(enemy.vector2 and enemy.vector2.x),
            tostring(enemy.vector2 and enemy.vector2.y))
        _logf("[ENEMY DEBUG] Souris: x=%s y=%s", tostring(mouseX), tostring(mouseY))
    end

    -- Essayer différentes structures de position
    local x, y, w, h

    if enemy.vector2 and enemy.vector2.x and enemy.vector2.y then
        x = enemy.vector2.x
        y = enemy.vector2.y
    else
        if CardTargetSelection.DEBUG_VERBOSE then
            _logf("[ENEMY DEBUG] Aucune position trouvée pour ennemi: %s", enemy.name or "unnamed")
        end
        return false
    end

    w = enemy.width or 0
    h = enemy.height or 0

    if w == 0 and h == 0 then
        if CardTargetSelection.DEBUG_VERBOSE then
            _logf("[ENEMY DEBUG] Aucune taille valide pour ennemi: %s", enemy.name or "unnamed")
        end
        return false
    end

    local isHovered = CardTargetSelection.isPointInEnemy(mouseX, mouseY, x, y, w, h)

    if isHovered and CardTargetSelection.DEBUG then
        _logf("Ennemi survolé détecté: %s", enemy.name or "sans nom")
    end

    return isHovered
end

-- Vérifie si un point est dans la zone d'un ennemi
function CardTargetSelection.isPointInEnemy(pointX, pointY, enemyX, enemyY, enemyW, enemyH)
    return pointX >= enemyX and pointX <= (enemyX + enemyW) and
        pointY >= enemyY and pointY <= (enemyY + enemyH)
end

-- Trouve l'ennemi survolé par la souris dans la liste complète
function CardTargetSelection.findHoveredEnemy()
    if not CardTargetSelection.config.mouseDetection.enabled then
        return nil
    end

    -- Récupère les coordonnées de la souris
    local mouseX, mouseY = _getCursor()
    return CardTargetSelection.findHoveredEnemyAt(mouseX, mouseY)
end

-- Trouve l'ennemi à une position donnée (pour handleMouseClick)
function CardTargetSelection.findHoveredEnemyAt(x, y)
    if not CardTargetSelection.config.mouseDetection.enabled then
        if CardTargetSelection.DEBUG_VERBOSE then
            _logf("findHoveredEnemyAt: détection souris désactivée")
        end
        return nil
    end

    -- Obtient la liste des ennemis
    local enemyList = CardTargetSelection.getEnemyList()
    if not enemyList or #enemyList == 0 then
        if CardTargetSelection.DEBUG_VERBOSE then
            _logf("findHoveredEnemyAt: aucun ennemi dans la liste")
        end
        return nil
    end

    -- Log réduit (seulement si verbose OU première fois)
    if CardTargetSelection.DEBUG_VERBOSE then
        _logf("findHoveredEnemyAt: vérification %d ennemis à position (%d,%d)", #enemyList, x, y)
    end

    -- Parcourt la liste des ennemis pour détecter la collision
    for i, enemy in ipairs(enemyList) do
        if CardTargetSelection.detectEnemyHover(enemy, x, y) then
            if CardTargetSelection.DEBUG_VERBOSE then
                _logf("findHoveredEnemyAt: ennemi trouvé - %s", enemy.name or "sans nom")
            end
            return enemy, i
        end
    end

    -- Pas trouvé - log seulement si verbose
    return nil
end

-- Système de mise à jour des survols avec debouncing
function CardTargetSelection.updateHoverDetection(dt)
    if not CardTargetSelection.isSelectingTarget then
        return
    end

    -- SIMPLE: Forcer l'animation terminée quand en mode standby
    local CardStandbyPlay = _G.CardStandbyPlay or require("my-librairie.card-librairie.cardStandbyPlay")
    local isInStandbyMode = CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby()

    if isInStandbyMode then
        -- Force l'animation comme terminée pour permettre la détection d'ennemis
        CardTargetSelection.animationCompleted = true
    end

    -- Ne pas détecter les ennemis tant que l'animation de la carte n'est pas terminée
    if not CardTargetSelection.animationCompleted then
        _logf("[HOVER] Animation non terminée - pas de détection d'ennemi")
        return
    end

    -- Debouncing pour éviter les détections trop fréquentes
    CardTargetSelection._hoverCheckTimer = (CardTargetSelection._hoverCheckTimer or 0) + dt
    if CardTargetSelection._hoverCheckTimer < CardTargetSelection.config.mouseDetection.hoverCheckInterval then
        return
    end
    CardTargetSelection._hoverCheckTimer = 0

    -- Détection de l'ennemi survolé
    local hoveredEnemy, enemyIndex = CardTargetSelection.findHoveredEnemy()

    -- Mise à jour de l'état de survol
    local previousHover = CardTargetSelection.hoveredEnemy
    CardTargetSelection.hoveredEnemy = hoveredEnemy
    CardTargetSelection._hoveredEnemyIndex = enemyIndex

    -- Événements de changement de survol
    if previousHover ~= hoveredEnemy then
        if previousHover then
            _logf("Fin survol: %s", previousHover.name or "Inconnu")
        end
        if hoveredEnemy then
            _logf("Début survol: %s", hoveredEnemy.name or "Inconnu")
        end

        -- Met à jour les statistiques
        if hoveredEnemy then
            CardTargetSelection.stats.hoversDetected = CardTargetSelection.stats.hoversDetected + 1
        end
    end
end

-- Convertit les coordonnées brutes de clic en coordonnées de jeu
local function _convertClickCoordinates(rawX, rawY)
    -- PRIORITÉ 1: Utiliser le système responsive
    local responsive = _G.screen or require("my-librairie.utils.responsive")
    if responsive and responsive.ratioScreen then
        local ratioX = responsive.ratioScreen.width or 1
        local ratioY = responsive.ratioScreen.height or 1
        if ratioX == 0 then ratioX = 1 end
        if ratioY == 0 then ratioY = 1 end

        local convertedX = rawX / ratioX
        local convertedY = rawY / ratioY

        _logf("[CLICK] Conversion clic: brut(%d,%d) → converti(%d,%d) ratio(%.3f,%.3f)",
            rawX, rawY, convertedX, convertedY, ratioX, ratioY)

        return convertedX, convertedY
    end

    -- PRIORITÉ 2: Calcul manuel
    if love and love.graphics and love.graphics.getDimensions then
        local currentW, currentH = love.graphics.getDimensions()
        local gameResoW, gameResoH = 1920, 1080 -- Résolution de référence
        local ratioX = currentW / gameResoW
        local ratioY = currentH / gameResoH

        local convertedX = rawX / ratioX
        local convertedY = rawY / ratioY

        _logf("[CLICK] Conversion manuelle: brut(%d,%d) → converti(%d,%d) ratio(%.3f,%.3f)",
            rawX, rawY, convertedX, convertedY, ratioX, ratioY)

        return convertedX, convertedY
    end

    -- Fallback: pas de conversion
    _logf("[CLICK] Aucune conversion disponible - utilisation coordonnées brutes")
    return rawX, rawY
end

-- Gestion de l'événement clic souris pour sélection cible
function CardTargetSelection.handleMouseClick(x, y, button)
    print("[URGENT DEBUG] handleMouseClick appelé avec:", x, y, button)
    print("[URGENT DEBUG] isSelectingTarget:", CardTargetSelection.isSelectingTarget)
    print("[URGENT DEBUG] animationCompleted:", CardTargetSelection.animationCompleted)

    if not CardTargetSelection.isSelectingTarget then
        print("[URGENT DEBUG] Pas en mode sélection - retour false!")
        return false
    end

    -- NOUVEAU: Vérifier que l'animation de la carte est terminée
    if not CardTargetSelection.animationCompleted then
        print("[URGENT DEBUG] Animation non terminée - clic ignoré!")
        return false
    end

    if button ~= 1 then -- Seul clic gauche accepté
        print("[URGENT DEBUG] Bouton ignoré:", button)
        return false
    end

    -- NOUVEAU: Convertir les coordonnées du clic
    local convertedX, convertedY = _convertClickCoordinates(x, y)
    print("[URGENT DEBUG] Recherche ennemi à position convertie:", convertedX, convertedY)

    -- Vérifier si un ennemi est survolé au moment du clic (utiliser les coordonnées converties)
    local targetEnemy = CardTargetSelection.findHoveredEnemyAt(convertedX, convertedY)
    if targetEnemy then
        print("[URGENT DEBUG] Ennemi trouvé:", targetEnemy.name or "sans nom")
        return CardTargetSelection.selectTarget(targetEnemy)
    else
        print("[URGENT DEBUG] Aucun ennemi trouvé - annulation")
        return CardTargetSelection.cancelSelection()
    end
end -- ============================================================================

-- FONCTIONS INTERNES (PRIVÉES)
-- ============================================================================

-- Anime la carte vers la position de sélection à gauche
function CardTargetSelection.animateCardToLeft(card)
    if not card then return end

    local targetX = CardTargetSelection.config.cardTargetPosition.x
    local targetY = CardTargetSelection.config.cardTargetPosition.y

    _logf("Animation carte vers position sélection: x=%d, y=%d", targetX, targetY)

    -- Marquer la carte comme étant en sélection
    card._selectingTarget = true
    card._originalSelectingPos = {
        x = card.vector2.x,
        y = card.vector2.y,
        scaleX = card.scale and card.scale.x or 1,
        scaleY = card.scale and card.scale.y or 1
    }

    -- Utiliser le système d'animation existant de card-librairie/play/anim.lua
    local Common = rawget(_G, "Common")
    local animDuration = (Common and Common.DEAL and Common.DEAL.DURATION) or 0.5

    card.anim = {
        sx = card.vector2.x,
        sy = card.vector2.y,
        tx = targetX,
        ty = targetY,
        t = 0,
        hop = 20, -- Petit saut pendant l'animation
        duration = animDuration
    }

    -- Mise à jour des échelles
    if not card.scale then card.scale = { x = 1, y = 1 } end
    card.scale.x = CardTargetSelection.config.cardSelectScale.x
    card.scale.y = CardTargetSelection.config.cardSelectScale.y

    _logf("Animation définie: sx=%d sy=%d tx=%d ty=%d hop=%d",
        card.anim.sx, card.anim.sy, card.anim.tx, card.anim.ty, card.anim.hop)
end

-- Restaure la carte à sa position en main
function CardTargetSelection._restoreCardToHand(card)
    if not card then return end

    _logf("🔴 DEBUG: _restoreCardToHand DÉSACTIVÉE - carte: %s", card.name or "sans nom")
    _logf("🔴 DEBUG: La carte reste à sa position actuelle pour observation")

    -- DÉSACTIVÉ TEMPORAIREMENT POUR DEBUG
    --[[ FONCTIONNALITÉ ORIGINALE COMMENTÉE
    _logf("Restauration carte en main: %s", card.name or "sans nom")

    -- Vérifier si nous avons une position originale sauvée
    if card._originalSelectingPos then
        _logf("Restauration position originale: x=%d y=%d",
            card._originalSelectingPos.x, card._originalSelectingPos.y)

        -- Utiliser le système d'animation pour retourner à la position originale
        card.anim = {
            sx = card.vector2.x,
            sy = card.vector2.y,
            tx = card._originalSelectingPos.x,
            ty = card._originalSelectingPos.y,
            t = 0,
            hop = 10,      -- Petit saut de retour
            duration = 0.3 -- Animation plus rapide pour le retour
        }

        -- Restaurer échelle originale
        if card.scale then
            card.scale.x = card._originalSelectingPos.scaleX
            card.scale.y = card._originalSelectingPos.scaleY
        end

        -- Nettoyer les données de sélection
        card._originalSelectingPos = nil
    else
        -- Fallback : utiliser la position target existante si disponible
        if card.target then
            card.anim = {
                sx = card.vector2.x,
                sy = card.vector2.y,
                tx = card.target.x,
                ty = card.target.y,
                t = 0,
                hop = 10,
                duration = 0.3
            }
        end
    end

    -- Supprimer le marqueur de sélection
    card._selectingTarget = nil

    _logf("Carte configurée pour animation de retour")
    --]]
end

-- Système de mise à jour intégré au cycle d'animation des cartes
function CardTargetSelection.updateAnimations(dt)
    if not CardTargetSelection.isSelectingTarget then
        return
    end

    -- Mettre à jour la détection de survol
    CardTargetSelection.updateHoverDetection(dt)

    -- Vérifier si la carte en sélection a terminé son animation
    local card = CardTargetSelection.cardBeingPlayed
    if card and card._selectingTarget and not card.anim and not CardTargetSelection.animationCompleted then
        _logf("Animation carte vers position sélection terminée pour: %s", card.name or "?")
        CardTargetSelection.animationCompleted = true
        -- La carte est maintenant en position de sélection et prête pour le ciblage
    end
end

-- Exécute le jeu de la carte sur la cible sélectionnée
function CardTargetSelection._executeCardPlay()
    _logf("🚀 [_EXECUTECARDPLAY] Début exécution...")

    local card = CardTargetSelection.cardBeingPlayed
    local target = CardTargetSelection.selectedTarget

    _logf("📊 Carte: %s", card and card.name or "AUCUNE")
    _logf("📊 Cible: %s", target and target.name or "AUCUNE")

    if not card or not target then
        _logError("executeCardPlay: carte ou cible manquante")
        _logError("❌ [_EXECUTECARDPLAY] ÉCHEC: Carte ou cible manquante")
        return false
    end

    _logf("Exécution jeu carte '%s' sur cible '%s'", card.name or "?", target.name or "?")

    -- CRITIQUE: Assigner la cible sélectionnée à la carte avant de la jouer
    card.selectedTarget = target
    _logf("Target assignée à la carte: %s", target.name or "?")
    _logf("🎯 [_EXECUTECARDPLAY] Target assignée à carte.selectedTarget")

    -- NOUVEAU : Confirmer le jeu de la carte via CardStandbyPlay
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay and CardStandbyPlay.hasCardInStandby() then
        local standbyCard = CardStandbyPlay.getStandbyCard()
        _logf("📊 [_EXECUTECARDPLAY] Carte en standby: %s", standbyCard and standbyCard.name or "AUCUNE")

        if standbyCard == card then
            _logf("Confirmation du jeu via CardStandbyPlay")
            _logf("✅ [_EXECUTECARDPLAY] Carte correspondante en standby")

            -- CORRECTION: D'abord jouer les effets de la carte, PUIS l'envoyer au cimetière
            local Card = rawget(_G, "Card")
            if Card and Card.Play and Card.Play.tryPlay then
                _logf("Appel tryPlay AVANT confirmCardPlay")
                _logf("🎮 [_EXECUTECARDPLAY] APPEL Card.Play.tryPlay...")
                local playSuccess = Card.Play.tryPlay(card, false) -- false = coût normal
                _logf("📊 [_EXECUTECARDPLAY] Résultat tryPlay: %s", tostring(playSuccess))

                if playSuccess then
                    _logf("tryPlay réussi - maintenant confirmer CardStandbyPlay")
                    local success = CardStandbyPlay.confirmCardPlay()
                    if success then
                        _logf("Carte confirmée et envoyée au cimetière via CardStandbyPlay")
                        card.selectedTarget = nil
                        return true
                    else
                        _logError("Échec confirmation CardStandbyPlay après tryPlay réussi")
                        card.selectedTarget = nil
                        return false
                    end
                else
                    _logError("Échec tryPlay - pas de confirmation CardStandbyPlay")
                    card.selectedTarget = nil
                    return false
                end
            else
                _logError("Module Card.Play.tryPlay non disponible")
                card.selectedTarget = nil
                return false
            end
        else
            _logError("Carte en standby différente de la carte à jouer")
            card.selectedTarget = nil
            return false
        end
    end

    -- Fallback : ancien système en cas d'absence de CardStandbyPlay
    local Card = rawget(_G, "Card")
    if Card and Card.Play and Card.Play.tryPlay then
        local success = Card.Play.tryPlay(card, false) -- false = coût normal

        if success then
            _logf("Carte jouée avec succès via Card.Play.tryPlay (fallback)")
            -- Nettoyer la cible assignée
            card.selectedTarget = nil
            return true
        else
            _logError("Échec Card.Play.tryPlay (fallback)")
            -- Nettoyer la cible en cas d'échec
            card.selectedTarget = nil
            return false
        end
    else
        _logError("Module Card.Play.tryPlay non disponible")
        card.selectedTarget = nil
        return false
    end
end

-- ============================================================================
-- FONCTION D'UPDATE PRINCIPALE (À APPELER DANS LA BOUCLE PRINCIPALE)
-- ============================================================================

-- Fonction d'update principal du système de ciblage (doit être appelée chaque frame)
function CardTargetSelection.update(dt)
    -- SÉCURITÉ: Vérifier les ennemis seulement si on est en mode ciblage ET en standby
    local CardStandbyPlay = rawget(_G, "CardStandbyPlay")
    local isInStandbyMode = CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby()

    if CardTargetSelection.isSelectingTarget and isInStandbyMode then
        -- DIAGNOSTIC: Vérifier périodiquement la disponibilité des ennemis (seulement en verbose)
        if CardTargetSelection.DEBUG_VERBOSE then
            local enemies = CardTargetSelection.getEnemyList()
            if #enemies == 0 then
                _logf("🔍 DEBUG STANDBY: Aucun ennemi disponible pour ciblage (liste vide)")
            else
                _logf("🔍 DEBUG STANDBY: %d ennemis disponibles pour ciblage", #enemies)
            end
        end

        -- Mise à jour de la détection de survol pour vérifier les ennemis en continu
        CardTargetSelection.updateHoverDetection(dt)
    end

    -- Mise à jour des animations (toujours active)
    CardTargetSelection.updateAnimations(dt)
end

-- ============================================================================
-- EXPOSITION GLOBALE ET INITIALISATION
-- ============================================================================

-- Auto-initialisation du module
CardTargetSelection.init()

-- Module exporté via globals.lua, pas d'auto-enregistrement
-- rawset(_G, "CardTargetSelection", CardTargetSelection)

_logf("Module CardTargetSelection chargé et exposé globalement")

return CardTargetSelection
