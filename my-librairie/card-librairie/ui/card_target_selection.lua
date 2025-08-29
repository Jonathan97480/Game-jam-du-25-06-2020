-- my-librairie/card-librairie/ui/card_target_selection.lua
-- Module de gestion de sélection de cibles pour le système de ciblage multi-ennemis
-- Permet au joueur de sélectionner manuellement l'ennemi cible lors du jeu d'une carte

-- Chargement sécurisé pour éviter les boucles circulaires
local function _safeRequire(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

-- Dependencies
local globalFunction = _G.globalFunction or rawget(_G, 'globalFunction')

-- Module principal
local CardTargetSelection = {}

-- ============================================================================
-- VARIABLES D'ÉTAT GLOBALES
-- ============================================================================

-- État principal du système de sélection
CardTargetSelection.isSelectingTarget = false    -- Mode sélection actif
CardTargetSelection.selectedTarget = nil         -- Ennemi sélectionné
CardTargetSelection.hoveredEnemy = nil          -- Ennemi actuellement survolé
CardTargetSelection.cardBeingPlayed = nil       -- Carte en cours de jeu

-- Configuration visuelle
CardTargetSelection.config = {
  -- Couleurs des contours (RGBA)
  hoverColor = {1, 1, 0, 0.8},        -- Jaune pour survol
  selectableColor = {1, 1, 1, 0.5},   -- Blanc transparent pour sélectionnable
  selectedColor = {0, 1, 0, 1},       -- Vert pour confirmé
  
  -- Épaisseurs des contours
  hoverLineWidth = 3,
  selectableLineWidth = 2,
  selectedLineWidth = 4,
  
  -- Animation carte
  cardTargetPosition = {x = 100, y = nil}, -- Position à gauche (y calculé dynamiquement)
  cardSelectScale = {x = 1.2, y = 1.2},    -- Échelle pendant sélection
  animationSpeed = 10,                      -- Vitesse lerp animation
}

-- Debug et logging
CardTargetSelection.DEBUG = rawget(_G, "DEBUG_TARGET_SELECTION") or false
CardTargetSelection.stats = {
  selectionsStarted = 0,
  selectionsCompleted = 0,
  selectionsCancelled = 0,
  hoversDetected = 0
}

-- ============================================================================
-- UTILITAIRES ET LOGGING
-- ============================================================================

local function _logf(fmt, ...)
  if not CardTargetSelection.DEBUG then return end
  local text = string.format("[CardTargetSelection] " .. fmt, ...)
  if globalFunction and globalFunction.log and globalFunction.log.info then 
    globalFunction.log.info(text) 
  else 
    print(text) 
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
  if love and love.mouse and love.mouse.getPosition then
    return love.mouse.getPosition()
  end
  -- Fallback pour tests
  return 0, 0
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
function CardTargetSelection.reset()
  _logf("Reset état module")
  CardTargetSelection.isSelectingTarget = false
  CardTargetSelection.selectedTarget = nil
  CardTargetSelection.hoveredEnemy = nil
  CardTargetSelection.cardBeingPlayed = nil
end

-- Nettoyage complet (pour transitions de scène)
function CardTargetSelection.cleanup()
  _logf("Cleanup module pour transition scène")
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
  CardTargetSelection.stats.selectionsStarted = CardTargetSelection.stats.selectionsStarted + 1
  
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
  
  -- Restaurer la carte en main
  if CardTargetSelection.cardBeingPlayed then
    CardTargetSelection._restoreCardToHand(CardTargetSelection.cardBeingPlayed)
  end
  
  CardTargetSelection.stats.selectionsCancelled = CardTargetSelection.stats.selectionsCancelled + 1
  CardTargetSelection.reset()
  
  _logf("Sélection annulée avec succès")
  return true
end

-- Sélectionne une cible et finalise le processus
function CardTargetSelection.selectTarget(enemy)
  if not CardTargetSelection.isSelectingTarget then
    _logError("selectTarget appelé mais aucune sélection en cours")
    return false
  end
  
  if not enemy then
    _logError("selectTarget appelé sans ennemi")
    return false
  end
  
  _logf("Sélection cible confirmée: %s pour carte: %s", 
    enemy.name or "ennemi sans nom",
    CardTargetSelection.cardBeingPlayed and CardTargetSelection.cardBeingPlayed.name or "carte sans nom")
  
  CardTargetSelection.selectedTarget = enemy
  CardTargetSelection.stats.selectionsCompleted = CardTargetSelection.stats.selectionsCompleted + 1
  
  -- Déclencher le jeu de la carte avec la cible sélectionnée
  local success = CardTargetSelection._executeCardPlay()
  
  if success then
    _logf("Carte jouée avec succès sur cible sélectionnée")
    CardTargetSelection.reset()
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
function CardTargetSelection.getEnemyList()
  -- Tenter d'accéder à EnemiesG d'abord (singleton global)
  local enemiesManager = rawget(_G, "EnemiesG")
  if enemiesManager and enemiesManager.listeEnemies then
    return enemiesManager.listeEnemies
  end
  
  -- Fallback sur Enemies (autre pattern)
  local enemiesModule = rawget(_G, "Enemies")
  if enemiesModule and enemiesModule.listeEnemies then
    return enemiesModule.listeEnemies
  end
  
  _logError("Aucun gestionnaire d'ennemis trouvé (EnemiesG/Enemies)")
  return {}
end

-- Détecte si la souris survole un ennemi spécifique
function CardTargetSelection.detectEnemyHover(enemy, mouseX, mouseY)
  if not enemy or not enemy.vector2 then 
    return false 
  end
  
  local x = enemy.vector2.x or 0
  local y = enemy.vector2.y or 0 
  local w = enemy.width or 100
  local h = enemy.height or 100
  
  return CardTargetSelection.isPointInEnemy(mouseX, mouseY, x, y, w, h)
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
  
  -- Obtient la liste des ennemis
  local enemyList = CardTargetSelection.getEnemyList()
  if not enemyList or #enemyList == 0 then 
    return nil 
  end
  
  -- Parcourt la liste des ennemis pour détecter la collision
  for i, enemy in ipairs(enemyList) do
    if CardTargetSelection.detectEnemyHover(enemy, mouseX, mouseY) then
      if CardTargetSelection.config.debug.enabled then
        _logf("Ennemi survolé: %s à (%d,%d)", enemy.name or "Inconnu", mouseX, mouseY)
      end
      return enemy, i
    end
  end
  
  return nil
end

-- Système de mise à jour des survols avec debouncing
function CardTargetSelection.updateHoverDetection(dt)
  if not CardTargetSelection.isSelectingTarget then 
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
    if previousHover and CardTargetSelection.config.debug.enabled then
      _logf("Fin survol: %s", previousHover.name or "Inconnu")
    end
    if hoveredEnemy and CardTargetSelection.config.debug.enabled then
      _logf("Début survol: %s", hoveredEnemy.name or "Inconnu")
    end
    
    -- Met à jour les statistiques
    if hoveredEnemy then
      CardTargetSelection.stats.hoversDetected = CardTargetSelection.stats.hoversDetected + 1
    end
  end
end

-- Gestion de l'événement clic souris pour sélection cible
function CardTargetSelection.handleMouseClick(x, y, button)
  if not CardTargetSelection.isSelectingTarget then
    return false
  end
  
  if button ~= 1 then -- Seul clic gauche accepté
    return false
  end
  
  -- Vérifier si un ennemi est survolé au moment du clic
  local targetEnemy = CardTargetSelection.findHoveredEnemy()
  if targetEnemy then
    _logf("Clic détecté sur ennemi: %s", targetEnemy.name or "Inconnu")
    return CardTargetSelection.selectTarget(targetEnemy)
  else
    _logf("Clic détecté mais aucun ennemi survolé - annulation sélection")
    return CardTargetSelection.cancelSelection()
  end
end

-- ============================================================================
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
      hop = 10, -- Petit saut de retour
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
  if card and card._selectingTarget and not card.anim then
    _logf("Animation carte vers position sélection terminée pour: %s", card.name or "?")
    -- La carte est maintenant en position de sélection et prête pour le ciblage
  end
end

-- Exécute le jeu de la carte sur la cible sélectionnée
function CardTargetSelection._executeCardPlay()
  local card = CardTargetSelection.cardBeingPlayed
  local target = CardTargetSelection.selectedTarget
  
  if not card or not target then
    _logError("executeCardPlay: carte ou cible manquante")
    return false
  end
  
  _logf("Exécution jeu carte '%s' sur cible '%s'", card.name or "?", target.name or "?")
  
  -- Tenter de jouer la carte via le système existant
  local Card = rawget(_G, "Card")
  if Card and Card.Play and Card.Play.tryPlay then
    -- Temporairement assigner la cible sélectionnée pour le système
    local oldSelectedTarget = CardTargetSelection.selectedTarget
    
    local success = Card.Play.tryPlay(card, false) -- false = coût normal
    
    if success then
      _logf("Carte jouée avec succès via Card.Play.tryPlay")
      return true
    else
      _logError("Échec Card.Play.tryPlay")
      CardTargetSelection.selectedTarget = oldSelectedTarget -- Restaurer
      return false
    end
  else
    _logError("Module Card.Play.tryPlay non disponible")
    return false
  end
end

-- ============================================================================
-- FONCTION D'UPDATE PRINCIPALE (À APPELER DANS LA BOUCLE PRINCIPALE)
-- ============================================================================

-- Fonction d'update principal du système de ciblage (doit être appelée chaque frame)
function CardTargetSelection.update(dt)
  -- Mise à jour des animations et détection de survol
  CardTargetSelection.updateAnimations(dt)
end

-- ============================================================================
-- EXPOSITION GLOBALE ET INITIALISATION
-- ============================================================================

-- Auto-initialisation du module
CardTargetSelection.init()

-- Exposition globale pour accès depuis autres modules
rawset(_G, "CardTargetSelection", CardTargetSelection)

_logf("Module CardTargetSelection chargé et exposé globalement")

return CardTargetSelection
