# Exemples Pratiques - Contrôleur IA

## Exemples d'Intégration

### 1. Intégration Basique dans une Scène de Combat

```lua
-- scene/gameplay/gameplay.lua
local scene = { name = "scene.gameplay.gameplay" }
local AI = require("my-librairie/ai/controller")

function scene:load()
  -- Initialisation du contrôleur IA
  if EnemiesManager and EnemiesManager.curentEnemy then
    AI.load(EnemiesManager.curentEnemy)
    logf("[Gameplay] Contrôleur IA initialisé pour %s", EnemiesManager.curentEnemy.name)
  end
end

function scene:update(dt)
  -- Mise à jour IA pendant le tour ennemi
  if _G.Tour == "Enemy" and not AI:isTurnDone() then
    AI:update(dt)
  end
  
  -- Vérification fin de tour IA
  if _G.Tour == "Enemy" and AI:isTurnDone() then
    -- Transition automatique vers tour joueur
    _G.Tour = "player"
    logf("[Gameplay] Tour IA terminé, passage au joueur")
  end
end

function scene:draw()
  -- Rendu du télégraphe IA
  AI.draw()
end

return scene
```

### 2. Intégration avec Template Combat Transition

```lua
-- my-librairie/transition/templateCombatTransition.lua
local Transition = require("my-librairie/transitionManager")
local AI = require("my-librairie/ai/controller")

local TemplateCombat = {}

function TemplateCombat.startEnemyTurn()
  logf("[Transition] Début tour ennemi")
  
  -- Préparation de l'ennemi courant
  local enemy = EnemiesManager.curentEnemy
  if not enemy or not enemy.state then
    logf("[Transition] Aucun ennemi valide, fin de tour immédiate")
    TemplateCombat.endEnemyTurn()
    return
  end
  
  -- Démarrage du contrôleur IA
  AI:startTurn(enemy)
  _G.Tour = "Enemy"
  
  logf("[Transition] Tour IA démarré pour %s (power: %d)", 
       enemy.name or "?", enemy.state.power or 0)
end

function TemplateCombat.updateCombat(dt)
  if _G.Tour == "Enemy" then
    -- Mise à jour du contrôleur IA
    AI:update(dt)
    
    -- Vérification fin de tour automatique
    if AI:isTurnDone() then
      TemplateCombat.endEnemyTurn()
    end
  end
end

function TemplateCombat.endEnemyTurn()
  logf("[Transition] Fin tour ennemi")
  
  -- Nettoyage et passage au tour suivant
  _G.Tour = "player"
  
  -- Vérification victoire/défaite
  TemplateCombat.checkVictoryConditions()
end

function TemplateCombat.requestEndTurn()
  -- Appelé par le contrôleur IA pour demander la fin de tour
  logf("[Transition] Demande fin de tour reçue de l'IA")
  TemplateCombat.endEnemyTurn()
end

return TemplateCombat
```

### 3. Configuration Avancée avec Télégraphe

```lua
-- Initialisation dans main.lua ou dans une scène
local AI = require("my-librairie/ai/controller")
local Telegraph = require("my-librairie/ai/telegraph")

-- Configuration du système visuel
function setupAIVisual()
  -- Télégraphe avec délai personnalisé
  Telegraph:setDelay(1.2)
  Telegraph:setEnabled(true)
  
  -- Connexion au contrôleur
  AI.setListener(Telegraph)
  
  -- Configuration du contrôleur
  AI.setConfig({
    telegraphMin = 1.2  -- Correspond au délai du télégraphe
  })
  
  -- Mode debug pour développement
  if _G.DEBUG_MODE then
    AI.DEBUG = true
    Telegraph:setDebug(true)
  end
  
  logf("[Setup] Système visuel IA configuré (délai: %.1fs)", 1.2)
end

-- Gestion des événements de télégraphe personnalisés
local customListener = {
  onCardChosen = function(self, ai, card, index, power)
    logf("[Visual] IA choisit '%s' (index: %d, power: %d)", 
         card.name or "?", index, power)
    
    -- Effet visuel personnalisé
    if card.rarity == "legendary" then
      -- Animation spéciale pour cartes légendaires
      showSpecialEffect(card)
    end
  end,
  
  onTelegraphStart = function(self, ai, card)
    -- Son personnalisé selon le type de carte
    local cardType = getCardType(card)
    playCardSound(cardType)
  end,
  
  onResolveDone = function(self, ai, card)
    -- Feedback visuel après résolution
    showCardEffect(card)
  end
}

AI.setListener(customListener)
```

## Exemples de Cartes IA Personnalisées

### 1. Carte avec Logique onPlay Complexe

```lua
-- ressources/cards_data_enemy.lua
local fireballCard = {
  name = "Boule de Feu",
  cost = 2,
  texture = "cards/fireball.png",
  
  -- Effets de base pour le système de priorité
  Effect = {
    hero = { attack = 3 },
    enemy = { heal = 1 }  -- Auto-soin mineur
  },
  
  -- Logique avancée avec le contrôleur IA
  onPlay = function(self, ctx)
    local enemy = ctx.enemy or ctx.source
    local hero = ctx.hero or ctx.target
    
    -- Dégâts de base
    local damage = 3
    
    -- Bonus si l'ennemi a peu de vie (désespoir)
    if enemy.state.life <= enemy.state.maxLife * 0.3 then
      damage = damage + 2
      logf("[Card] Boule de Feu désespérée ! +2 dégâts")
    end
    
    -- Bonus si le héros a un bouclier (perce-armure)
    if hero.state.shield > 0 then
      damage = damage + 1
      hero.state.shield = math.max(0, hero.state.shield - 1)
      logf("[Card] Perce-armure ! Shield réduit")
    end
    
    -- Application des dégâts
    attack.applique(self, enemy, hero, damage)
    
    -- Auto-soin de l'ennemi
    heal.give(self, enemy, 1)
    
    logf("[Card] Boule de Feu: %d dégâts infligés", damage)
    return true
  end
}
```

### 2. Carte de Soin Tactique avec Ciblage Intelligent

```lua
local healingWaveCard = {
  name = "Vague de Soin",
  cost = 3,
  texture = "cards/healing_wave.png",
  
  -- Le contrôleur IA détectera automatiquement le type "heal"
  Effect = {
    enemy = { heal = 4 }
  },
  
  -- Logique avancée qui utilise le ciblage intelligent
  onPlay = function(self, ctx)
    local caster = ctx.enemy or ctx.source
    local target = ctx.target  -- Défini par selectTargetForCard()
    
    -- Soin de base
    local healing = 4
    
    -- Bonus selon l'état de la cible
    if target.state.life <= target.state.maxLife * 0.25 then
      healing = healing + 3  -- Bonus sur cible critique
      logf("[Card] Soin d'urgence ! +3 HP")
    elseif target.state.life <= target.state.maxLife * 0.5 then
      healing = healing + 1  -- Bonus mineur sur cible blessée
    end
    
    -- Application du soin
    heal.give(self, target, healing)
    
    -- Effet secondaire : petit boost de power pour la cible
    if target ~= caster then
      target.state.power = (target.state.power or 0) + 1
      logf("[Card] Boost de power accordé à l'allié")
    end
    
    logf("[Card] Vague de Soin: %d HP restaurés sur %s", 
         healing, target.name or "?")
    return true
  end
}
```

### 3. Carte de Bouclier Collectif

```lua
local shieldWallCard = {
  name = "Mur de Boucliers",
  cost = 4,
  texture = "cards/shield_wall.png",
  
  -- Détecté comme carte de bouclier par le contrôleur
  Effect = {
    enemy = { shield = 2 }
  },
  
  onPlay = function(self, ctx)
    local caster = ctx.enemy or ctx.source
    
    -- Récupération de tous les alliés (même logique que l'IA)
    local allies = {}
    if EnemiesManager and EnemiesManager.listeEnemies then
      for _, enemy in ipairs(EnemiesManager.listeEnemies) do
        if enemy.state and not enemy.state.dead and (enemy.state.life or 0) > 0 then
          table.insert(allies, enemy)
        end
      end
    end
    
    -- Ajouter l'ennemi courant s'il n'est pas dans la liste
    local current = EnemiesManager.curentEnemy
    if current and current.state and not current.state.dead then
      local found = false
      for _, ally in ipairs(allies) do
        if ally == current then found = true; break end
      end
      if not found then table.insert(allies, current) end
    end
    
    -- Application du bouclier à tous les alliés
    local shieldAmount = 2
    local totalAllies = 0
    
    for _, ally in ipairs(allies) do
      shield.applique(self, ally, shieldAmount)
      totalAllies = totalAllies + 1
    end
    
    logf("[Card] Mur de Boucliers: +%d shield sur %d alliés", 
         shieldAmount, totalAllies)
    return true
  end
}
```

## Exemples de Configurations Spécialisées

### 1. Mode Boss avec IA Agressive

```lua
-- Configuration pour un boss agressif
function setupBossAI(bossEnemy)
  AI.load(bossEnemy)
  
  -- Configuration agressive
  AI.setConfig({
    telegraphMin = 0.5  -- Télégraphe plus rapide
  })
  
  -- Modification temporaire des priorités
  local originalChoose = AI.chooseDeterministic
  AI.chooseDeterministic = function(deck, powerNow)
    -- Logique boss : priorité absolue à l'attaque
    local playable = {}
    for i, c in ipairs(deck) do
      local cardType = getCardType(c)
      table.insert(playable, { i = i, c = c, type = cardType })
    end
    
    -- Trier par priorité boss : attack > control > shield > heal
    local priority = { attack = 4, control = 3, shield = 2, heal = 1 }
    table.sort(playable, function(a, b)
      return (priority[a.type] or 0) > (priority[b.type] or 0)
    end)
    
    if #playable > 0 then
      local choice = playable[1]
      logf("[Boss AI] Choix agressif: %s (%s)", choice.c.name, choice.type)
      return choice.i, choice.c
    end
    
    return nil, nil
  end
  
  logf("[Boss] IA agressive configurée pour %s", bossEnemy.name)
end
```

### 2. Mode Tutorial avec IA Prévisible

```lua
-- Configuration pour un tutorial avec IA prévisible
function setupTutorialAI(tutorialEnemy)
  AI.load(tutorialEnemy)
  
  -- Configuration pédagogique
  AI.setConfig({
    telegraphMin = 2.0  -- Télégraphe lent pour apprentissage
  })
  
  -- Sequence prédéfinie pour le tutorial
  local tutorialSequence = {
    "Attaque Basique",
    "Soin Mineur", 
    "Bouclier",
    "Attaque Basique",
    "Attaque Forte"
  }
  local sequenceIndex = 1
  
  -- Override du choix de carte pour suivre la séquence
  AI.chooseDeterministic = function(deck, powerNow)
    if sequenceIndex > #tutorialSequence then
      -- Retour au comportement normal après la séquence
      return originalChoose(deck, powerNow)
    end
    
    local targetCard = tutorialSequence[sequenceIndex]
    
    -- Chercher la carte dans le deck
    for i, card in ipairs(deck) do
      if card.name == targetCard then
        sequenceIndex = sequenceIndex + 1
        logf("[Tutorial AI] Séquence: jouant %s (%d/%d)", 
             targetCard, sequenceIndex-1, #tutorialSequence)
        return i, card
      end
    end
    
    -- Si carte non trouvée, prendre la première disponible
    if #deck > 0 then
      sequenceIndex = sequenceIndex + 1
      return 1, deck[1]
    end
    
    return nil, nil
  end
  
  logf("[Tutorial] IA pédagogique configurée avec séquence de %d cartes", 
       #tutorialSequence)
end
```

### 3. Système de Difficulté Adaptative

```lua
-- Adaptation de la difficulté selon les performances du joueur
local DifficultyManager = {
  playerWinRate = 0.5,  -- Ratio de victoires du joueur
  gameCount = 0,
  adjustmentFactor = 1.0
}

function DifficultyManager.updateStats(playerWon)
  DifficultyManager.gameCount = DifficultyManager.gameCount + 1
  
  -- Mise à jour du taux de victoire (moyenne mobile)
  local alpha = 0.1  -- Facteur de lissage
  if playerWon then
    DifficultyManager.playerWinRate = DifficultyManager.playerWinRate * (1 - alpha) + 1 * alpha
  else
    DifficultyManager.playerWinRate = DifficultyManager.playerWinRate * (1 - alpha) + 0 * alpha
  end
  
  -- Ajustement du facteur de difficulté
  if DifficultyManager.playerWinRate > 0.7 then
    DifficultyManager.adjustmentFactor = math.min(1.5, DifficultyManager.adjustmentFactor + 0.1)
  elseif DifficultyManager.playerWinRate < 0.3 then
    DifficultyManager.adjustmentFactor = math.max(0.5, DifficultyManager.adjustmentFactor - 0.1)
  end
  
  logf("[Difficulty] Taux victoire: %.1f%%, Facteur: %.2f", 
       DifficultyManager.playerWinRate * 100, DifficultyManager.adjustmentFactor)
end

function DifficultyManager.setupAdaptiveAI(enemy)
  AI.load(enemy)
  
  local factor = DifficultyManager.adjustmentFactor
  
  -- Modification des priorités selon la difficulté
  local originalChoose = AI.chooseDeterministic
  AI.chooseDeterministic = function(deck, powerNow)
    local idx, card = originalChoose(deck, powerNow)
    
    if not card then return nil, nil end
    
    -- Si difficulté élevée, l'IA peut "tricher" légèrement
    if factor > 1.2 and math.random() < 0.3 then
      -- Chercher une carte plus agressive
      for i, c in ipairs(deck) do
        local cardType = getCardType(c)
        if cardType == "attack" and c ~= card then
          logf("[Adaptive AI] Boost difficulté: choisit attaque")
          return i, c
        end
      end
    end
    
    -- Si difficulté faible, l'IA peut faire des choix sub-optimaux
    if factor < 0.8 and math.random() < 0.2 then
      -- Chercher une carte moins optimale
      for i, c in ipairs(deck) do
        local cardType = getCardType(c)
        if cardType == "heal" and getCurrentEnemy().state.life > getCurrentEnemy().state.maxLife * 0.8 then
          logf("[Adaptive AI] Réduction difficulté: soin inutile")
          return i, c
        end
      end
    end
    
    return idx, card
  end
  
  -- Ajustement de la vitesse selon la difficulté
  AI.setConfig({
    telegraphMin = math.max(0.2, 1.0 / factor)  -- Plus rapide = plus difficile
  })
  
  logf("[Adaptive] IA configurée avec facteur %.2f", factor)
end
```

## Exemples de Debug et Monitoring

### 1. Console de Debug en Temps Réel

```lua
-- Console de debug pour monitorer l'IA en temps réel
local AIDebugConsole = {
  enabled = false,
  updateTimer = 0,
  updateInterval = 1.0  -- Mise à jour chaque seconde
}

function AIDebugConsole.toggle()
  AIDebugConsole.enabled = not AIDebugConsole.enabled
  logf("[Debug] Console IA: %s", AIDebugConsole.enabled and "activée" or "désactivée")
end

function AIDebugConsole.update(dt)
  if not AIDebugConsole.enabled then return end
  
  AIDebugConsole.updateTimer = AIDebugConsole.updateTimer + dt
  if AIDebugConsole.updateTimer >= AIDebugConsole.updateInterval then
    AIDebugConsole.updateTimer = 0
    AIDebugConsole.printStatus()
  end
end

function AIDebugConsole.printStatus()
  local enemy = getCurrentEnemy()
  if not enemy then
    print("[Debug AI] Aucun ennemi courant")
    return
  end
  
  print("=== STATUS IA ===")
  print("État:", AI.state)
  print("Occupé:", AI.busy)
  print("Tour fini:", AI:isTurnDone())
  print("Timer:", string.format("%.2f", AI.timer or 0))
  
  if enemy.state then
    print("Ennemi:", enemy.name or "?")
    print("Vie:", string.format("%d/%d (%.1f%%)", 
          enemy.state.life or 0, 
          enemy.state.maxLife or 1,
          ((enemy.state.life or 0) / (enemy.state.maxLife or 1)) * 100))
    print("Power:", enemy.state.power or 0)
    print("Shield:", enemy.state.shield or 0)
  end
  
  if Card and Card.deckAi and Card.deckAi.cards then
    print("Cartes IA:", #Card.deckAi.cards)
    if AI.currentCard then
      print("Carte actuelle:", AI.currentCard.name or "?")
    end
  end
  
  print("================")
end

-- Activation avec F1 par exemple
function love.keypressed(key)
  if key == "f1" then
    AIDebugConsole.toggle()
  end
end
```

### 2. Profiler de Performance IA

```lua
-- Profiler pour mesurer les performances du contrôleur IA
local AIProfiler = {
  enabled = false,
  metrics = {},
  currentFrame = {},
  frameCount = 0
}

function AIProfiler.start(label)
  if not AIProfiler.enabled then return end
  AIProfiler.currentFrame[label] = love.timer.getTime()
end

function AIProfiler.stop(label)
  if not AIProfiler.enabled then return end
  if not AIProfiler.currentFrame[label] then return end
  
  local duration = love.timer.getTime() - AIProfiler.currentFrame[label]
  
  if not AIProfiler.metrics[label] then
    AIProfiler.metrics[label] = {
      totalTime = 0,
      callCount = 0,
      maxTime = 0,
      minTime = math.huge
    }
  end
  
  local metric = AIProfiler.metrics[label]
  metric.totalTime = metric.totalTime + duration
  metric.callCount = metric.callCount + 1
  metric.maxTime = math.max(metric.maxTime, duration)
  metric.minTime = math.min(metric.minTime, duration)
  
  AIProfiler.currentFrame[label] = nil
end

function AIProfiler.printReport()
  if not AIProfiler.enabled then return end
  
  print("=== PROFILER IA ===")
  for label, metric in pairs(AIProfiler.metrics) do
    local avgTime = metric.totalTime / metric.callCount
    print(string.format("%s: %.3fms avg (%.3f-%.3f) x%d", 
          label, 
          avgTime * 1000,
          metric.minTime * 1000,
          metric.maxTime * 1000,
          metric.callCount))
  end
  print("==================")
end

-- Intégration dans le contrôleur IA
local originalUpdate = AI.update
AI.update = function(self, dt)
  AIProfiler.start("ai_update")
  originalUpdate(self, dt)
  AIProfiler.stop("ai_update")
end

local originalChoose = AI.chooseDeterministic
AI.chooseDeterministic = function(deck, powerNow)
  AIProfiler.start("card_choice")
  local result1, result2 = originalChoose(deck, powerNow)
  AIProfiler.stop("card_choice")
  return result1, result2
end
```

Ces exemples montrent l'utilisation pratique du contrôleur IA dans différents contextes : intégration système, cartes personnalisées, configurations spécialisées, et outils de debug. Le système est suffisamment flexible pour s'adapter à tous ces cas d'usage ! 🎮
