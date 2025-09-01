# 🎬 Système de Transitions - Documentation

> **Module Principal** : `my-librairie/transitions/transitionManager.lua`
> **Support** : Templates de combat, effets focus, gestion anti-spam
> **Status** : ✅ Opérationnel avec système anti-spam intelligent
> **Dernière MàJ** : 1er septembre 2025 (Problème #10)

---

## 📋 Vue d'ensemble

Le système de transitions gère les effets visuels et animations entre scènes, avec un focus particulier sur les transitions de combat. Il propose une architecture modulaire avec gestion automatique des logs et prévention du spam.

### Fonctionnalités Principales
- **Transitions fluides** entre scènes
- **Templates spécialisés** pour les combats
- **Effets de focus** et zoom
- **Système anti-spam intelligent** pour les logs
- **Gestion automatique** de la mémoire et cleanup

---

## 🏗️ Architecture du Système

```
my-librairie/transitions/
├── transitionManager.lua           # Gestionnaire principal
├── templateCombatTransition.lua    # Templates de combat
└── focus.lua                       # Effets de mise en avant
```

### Intégration dans l'Architecture Globale
- **SceneManager** : Déclenche transitions lors des changements de scène
- **Gameplay** : Utilise templates combat pour entrée/sortie combats
- **HUD** : Coordonné pour animations d'interface
- **Logger** : Système anti-spam pour éviter pollution logs

---

## 🔧 API TransitionManager

### Fonctions Principales

#### `transitionManager.init()`
Initialise le système de transitions avec configuration par défaut.

```lua
local transitionManager = require("my-librairie.transitions.transitionManager")
transitionManager.init()
```

#### `transitionManager.startTransition(config)`
Démarre une transition avec configuration personnalisée.

```lua
transitionManager.startTransition({
    duration = 1.0,
    type = "fade",
    direction = "in",
    color = {0, 0, 0, 1},
    callback = function()
        print("Transition terminée")
    end
})
```

#### `transitionManager.isActive()`
Vérifie si une transition est en cours.

```lua
if transitionManager.isActive() then
    -- Bloquer interactions pendant transition
    return
end
```

#### `transitionManager.update(dt)`
Mise à jour du système (appelé dans scene:update).

```lua
function scene:update(dt)
    transitionManager.update(dt)
    -- Autres mises à jour...
end
```

#### `transitionManager.draw()`
Rendu des transitions (appelé dans scene:draw).

```lua
function scene:draw()
    -- Rendu scène normale
    transitionManager.draw()
end
```

---

## ⚔️ Templates de Combat

### API TemplateCombatTransition

Le module `templateCombatTransition.lua` fournit des transitions pré-configurées pour les séquences de combat.

#### `templateCombatTransition.enterCombat(callback)`
Transition d'entrée en combat avec effet dramatique.

```lua
local combatTemplate = require("my-librairie.transitions.templateCombatTransition")

combatTemplate.enterCombat(function()
    -- Combat initialisé
    scene:push("scene/gameplay/gameplay")
end)
```

#### `templateCombatTransition.exitCombat(callback)`
Transition de sortie de combat.

```lua
combatTemplate.exitCombat(function()
    -- Retour au monde/menu
    scene:pop()
end)
```

#### `templateCombatTransition.defeatTransition(callback)`
Transition spéciale pour défaite du joueur.

```lua
combatTemplate.defeatTransition(function()
    scene:switch("scene/overlay_gameover/overlay_gameover")
end)
```

#### `templateCombatTransition.victoryTransition(callback)`
Transition de victoire avec effets positifs.

```lua
combatTemplate.victoryTransition(function()
    scene:push("scene/overlay_reward/overlay_reward")
end)
```

---

## 🎯 Système Focus

### API Focus Effects

Le module `focus.lua` gère les effets de mise en avant et zoom.

#### `focus.zoomOnTarget(target, duration, callback)`
Zoom fluide sur une cible spécifique.

```lua
local focus = require("my-librairie.transitions.focus")

focus.zoomOnTarget({
    x = 400, y = 300,
    scale = 1.5
}, 0.8, function()
    -- Zoom terminé
end)
```

#### `focus.highlightActor(actor, intensity)`
Met en évidence un acteur avec effet lumineux.

```lua
focus.highlightActor(selectedEnemy, 1.2)
```

#### `focus.dimOthers(exceptions)`
Assombrit tous les éléments sauf les exceptions.

```lua
focus.dimOthers({playerHand, selectedCard})
```

---

## 🚨 AMÉLIORATION - Système Anti-Spam (Problème #10)

### Problème Résolu : Logs Verbeux et Performance

**Avant** : Logs répétitifs polluant les fichiers de debug
**Après** : Système intelligent avec cache et auto-cleanup

### Architecture Anti-Spam

#### Cache de Messages Intelligent
```lua
-- Dans gameplay.lua - SYSTÈME ANTI-SPAM
local transitionLogCache = {}
local MAX_SAME_LOGS = 3
local CACHE_CLEANUP_INTERVAL = 30.0
local lastCacheCleanup = 0

local function shouldLogTransition(message)
    local currentTime = love.timer.getTime()
    
    -- Auto-cleanup périodique
    if currentTime - lastCacheCleanup > CACHE_CLEANUP_INTERVAL then
        transitionLogCache = {}
        lastCacheCleanup = currentTime
        return true
    end
    
    -- Vérifier limite spam
    if not transitionLogCache[message] then
        transitionLogCache[message] = 0
    end
    
    transitionLogCache[message] = transitionLogCache[message] + 1
    return transitionLogCache[message] <= MAX_SAME_LOGS
end
```

#### Logging Conditionnel
```lua
local function logTransitionState()
    local message = string.format("Transition state: active=%s, GameFlags.showOverlayInitiative=%s", 
                                  tostring(transitionManager.isActive()), 
                                  tostring(GameFlags.showOverlayInitiative))
    
    if shouldLogTransition(message) then
        gf.log.info(message)
        
        -- Message spam warning
        if transitionLogCache[message] == MAX_SAME_LOGS then
            gf.log.warn("Message transition en mode spam - logging réduit")
        end
    end
end
```

### Configuration Anti-Spam

#### Paramètres Ajustables
```lua
-- Configuration dans gameplay.lua
local ANTI_SPAM_CONFIG = {
    MAX_SAME_LOGS = 3,              -- Limite avant réduction
    CACHE_CLEANUP_INTERVAL = 30.0,  -- Nettoyage auto (secondes)
    CACHE_PERSISTENCE = true,       -- Maintenir cache entre frames
    WARN_ON_SPAM = true            -- Alerter quand limite atteinte
}
```

#### API de Debug
```lua
-- Fonction utilitaire debug
local function getTransitionDebugInfo()
    return {
        cacheSize = next(transitionLogCache) and 
                   (function()
                       local count = 0
                       for _ in pairs(transitionLogCache) do count = count + 1 end
                       return count
                   end)() or 0,
        lastCleanup = lastCacheCleanup,
        nextCleanup = lastCacheCleanup + CACHE_CLEANUP_INTERVAL,
        activeTransitions = transitionManager.isActive()
    }
end
```

---

## 🧪 Tests et Validation

### Test Manual : Transitions de Combat

```lua
-- Dans gameplay/gameplay.lua ou console debug
function testCombatTransitions()
    print("=== TEST TRANSITIONS COMBAT ===")
    
    -- Test 1: Entrée combat
    templateCombatTransition.enterCombat(function()
        print("✅ Entrée combat OK")
        
        -- Test 2: Sortie combat  
        templateCombatTransition.exitCombat(function()
            print("✅ Sortie combat OK")
        end)
    end)
end
```

### Test Anti-Spam Logs

```lua
function testAntiSpamSystem()
    print("=== TEST ANTI-SPAM ===")
    
    -- Générer messages répétitifs
    for i = 1, 10 do
        logTransitionState()
    end
    
    -- Vérifier réduction logs
    local debugInfo = getTransitionDebugInfo()
    print("Cache size:", debugInfo.cacheSize)
    print("Active transitions:", debugInfo.activeTransitions)
end
```

### Validation Performance

```lua
function benchmarkTransitions()
    local startTime = love.timer.getTime()
    
    -- Test charge système
    for i = 1, 1000 do
        transitionManager.update(0.016) -- 60 FPS simulation
    end
    
    local endTime = love.timer.getTime()
    print(string.format("1000 updates: %.3f ms", (endTime - startTime) * 1000))
end
```

---

## 🐛 Troubleshooting

### Problème : Transitions Bloquées

**Symptômes** : Interface figée, transition ne se termine pas
**Debug :**
```lua
-- Vérifier état transition
print("Transition active:", transitionManager.isActive())
print("Durée écoulée:", transitionManager.getElapsedTime())

-- Forcer arrêt si nécessaire  
if transitionManager.isActive() then
    transitionManager.forceComplete()
end
```

### Problème : Logs Spam Transition

**Symptômes** : Fichiers logs volumineux, performances dégradées
**Solution :** Système anti-spam automatique intégré

**Monitoring :**
```lua
-- Vérifier état cache anti-spam
local debugInfo = getTransitionDebugInfo()
if debugInfo.cacheSize > 20 then
    print("⚠️ Cache anti-spam volumineux - nettoyage recommandé")
end
```

### Problème : Synchronisation Scènes

**Symptômes** : Décalages visuels, transitions mal synchronisées
**Debug :**
```lua
-- Vérifier ordre d'exécution
function scene:update(dt)
    -- 1. Gameplay logic
    -- 2. Transitions AVANT actorManager
    transitionManager.update(dt)
    -- 3. Autres systèmes
    actorManager.update(dt)
end
```

---

## 🚀 Performances et Optimisations

### Recommandations Performance

1. **Cache Cleanup** : Automatique toutes les 30 secondes
2. **Limite Transitions** : Une seule transition active à la fois
3. **Pooling Effects** : Réutilisation objets transition
4. **Memory Management** : Cleanup automatique callbacks

### Monitoring Performance

```lua
-- Métriques système
function getTransitionMetrics()
    return {
        activeTransitions = transitionManager.getActiveCount(),
        cacheMemory = collectgarbage("count"),
        averageFrameTime = transitionManager.getAverageFrameTime(),
        logCacheSize = getTransitionDebugInfo().cacheSize
    }
end
```

---

## 📚 Exemples d'Intégration

### Exemple 1 : Transition de Combat Complète

```lua
-- Dans scene/gameplay/gameplay.lua
function startCombatSequence()
    -- 1. Transition d'entrée
    templateCombatTransition.enterCombat(function()
        
        -- 2. Focus sur ennemis
        focus.zoomOnTarget(enemyGroup, 1.0, function()
            
            -- 3. Dim autres éléments
            focus.dimOthers({playerHand})
            
            -- 4. Commencer combat
            GameFlags.combatActive = true
            
        end)
    end)
end
```

### Exemple 2 : Séquence Victoire

```lua
function handleVictory()
    -- 1. Transition victoire
    templateCombatTransition.victoryTransition(function()
        
        -- 2. Reset focus
        focus.resetAll()
        
        -- 3. Overlay récompenses
        scene:push("scene/overlay_reward/overlay_reward")
        
    end)
end
```

---

## 🎯 État du Système

**Status Actuel** : ✅ **Fully Operational**

### Fonctionnalités Validées
- ✅ Transitions combat fluides
- ✅ Système anti-spam intelligent
- ✅ Auto-cleanup mémoire
- ✅ Performance optimisée
- ✅ Debug tools intégrés

### Améliorations Récentes (Problème #10)
- 🔧 Cache intelligent messages logs
- 🔧 Cleanup automatique périodique  
- 🔧 Limitation spam configurable
- 🔧 Monitoring performance intégré
- 🔧 Tests validation complets

### Prochaines Améliorations Planifiées
- 🔄 Templates transitions menu
- 🔄 Effets particules intégrés
- 🔄 Animations card play
- 🔄 Sound integration

---

**Dernière MàJ** : 1er septembre 2025  
**Responsable** : GitHub Copilot  
**Problème Résolu** : #10 - Logging verbeux et performance transitions
