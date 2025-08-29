# Guide de Référence Rapide - Contrôleur IA

## Démarrage Rapide

### Configuration Minimale
```lua
local AI = require("my-librairie/ai/controller")

-- Initialisation
AI.load(enemyActor)

-- Dans la boucle principale
function love.update(dt)
  if _G.Tour == "Enemy" then
    AI:update(dt)
  end
end
```

### Configuration Complète
```lua
local AI = require("my-librairie/ai/controller")

-- Configuration avancée
AI.DEBUG = true
AI.setConfig({ telegraphMin = 0.8 })

-- Auto-câblage télégraphe (optionnel)
AI.AUTO_WIRE_TELEGRAPH = true

-- Initialisation
AI.load(enemyActor)
```

## API Essentielle

| Méthode | Description | Usage |
|---------|-------------|-------|
| `AI.load(enemy)` | Initialise le contrôleur | Obligatoire au début |
| `AI:startTurn(enemy)` | Démarre le tour IA | Appelé par Transition |
| `AI:update(dt)` | Mise à jour principale | Dans love.update |
| `AI:isTurnDone()` | Vérifie fin de tour | Pour synchronisation |
| `AI.draw()` | Rendu visuel | Dans love.draw |

## Variables de Configuration

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `AI.DEBUG` | boolean | true | Active les logs |
| `AI.telegraphMin` | number | 0.3 | Délai d'affichage (sec) |
| `AI.AUTO_WIRE_TELEGRAPH` | boolean | true | Auto-câblage visuel |

## États du Contrôleur

| État | Description | Transitions |
|------|-------------|-------------|
| `"idle"` | En attente | → choose |
| `"choose"` | Sélection carte | → telegraph/resolve |
| `"telegraph"` | Affichage visuel | → resolve |
| `"resolve"` | Application effets | → endturn |
| `"endturn"` | Fin de tour | → waiting_end |
| `"waiting_end"` | Attente changement | → idle |

## Priorités Tactiques

### Ordre de Priorité
1. **Survie critique** (HP ≤ 35%) → Soin
2. **Allié blessé** (HP ≤ 50%) → Soin d'allié  
3. **Protection faible** (Shield ≤ 2) → Bouclier
4. **Allié vulnérable** (Shield ≤ 1) → Bouclier d'allié
5. **Opportunité** (Hero HP ≤ 40%) → Attaque
6. **Défaut** → Attaque > Bouclier > Soin > Contrôle

### Types de Cartes
- `"heal"` : Cartes de soin (enemy.heal > 0)
- `"shield"` : Cartes de protection (enemy.shield > 0)
- `"attack"` : Cartes d'attaque (hero.attack > 0)
- `"control"` : Cartes de contrôle (hero.skip > 0)
- `"other"` : Autres effets

## Ciblage Intelligent

### Algorithmes de Ciblage
```lua
-- Soin : Allié le plus blessé
local ratio = ally.life / ally.maxLife
if ratio < lowestRatio then target = ally end

-- Bouclier : Allié le moins protégé  
if ally.shield < lowestShield then target = ally end

-- Épines : Allié le plus offensif
if ally.attack > bestAttack then target = ally end
```

### Cibles par Défaut
- **Cartes d'attaque** → Héros
- **Cartes de support** → Soi-même
- **Cartes d'allié** → Allié optimal

## APIs Modernes vs Legacy

### Système Moderne (Priorité)
```lua
-- 1. Card.tryPlay() - API unifiée
Card.tryPlay(card, false)  -- coût normal

-- 2. Common.playCard() - Avec ciblage
Common.playCard(card, enemy, target)
```

### Système Legacy (Fallback)
```lua
-- 3 tentatives optimisées :
Card.tryPlay(card, "Enemy", true)
Card.tryPlay(card, {tag="Enemy", free=true})
Card.revealEnemyCard(card)  -- visuel uniquement
```

## Logs de Debug

### Logs Principaux
```lua
"[AI] status enemy: ..." -- État de l'ennemi
"[AI] alliés disponibles: N" -- Détection multi-ennemi
"[AI] choose -> CardName" -- Carte sélectionnée
"[AI] priorité: TYPE (raison)" -- Logique de décision
"[AI] Ciblage intelligent: ..." -- Cible choisie
"[AI] MODERN-SYS OK/FAIL: ..." -- Succès/échec API
"[AI] Δ life=+X, shield=+Y" -- Changements d'état
```

### Activation du Debug
```lua
AI.DEBUG = true  -- Active tous les logs

-- Ou conditionnel :
AI.DEBUG = _G.DEBUG_MODE or false
```

## Intégrations Système

### SceneManager
```lua
-- Auto-reset si pas le tour ennemi
if _G.Tour ~= "Enemy" then
  AI.state = "idle"
end
```

### Transition Manager
```lua
-- Demande de fin de tour automatique
if Transition and Transition.requestEndTurn then
  Transition.requestEndTurn()
end
```

### EnemiesManager
```lua
-- Récupération ennemi courant
local enemy = EnemiesManager.curentEnemy or currentEnemy
```

## Gestion d'Erreurs

### Vérifications Automatiques
```lua
-- Protection contre nil
if not actor or not actor.state then return end

-- APIs sécurisées
local ok = pcall(function() return Card.tryPlay(card) end)

-- Fallbacks robustes
Card = Card or rawget(_G, "Card") or require("...")
```

### Messages d'Erreur Courants
- `"Card=nil"` → Problème chargement module Card
- `"deck IA vide"` → Pas de cartes disponibles
- `"pas d'ennemi valide"` → getCurrentEnemy() retourne nil
- `"aucune API ne fonctionne"` → Toutes les tentatives échouent

## Télégraphe Visuel

### Configuration
```lua
local Telegraph = require("my-librairie/ai/telegraph")
AI.setListener(Telegraph)
AI.setConfig({ telegraphMin = 1.0 })
```

### Events Disponibles
- `onTurnStart(enemy)`
- `onCardChosen(card, index, power)`
- `onTelegraphStart(card)`
- `onResolveStart(card)`
- `onResolveDone(card)`
- `onTurnEnd()`

## Performance

### Optimisations Intégrées
- ✅ Cache des modules globaux
- ✅ Validation précoce (early return)
- ✅ pcall sélectif uniquement si nécessaire
- ✅ Logging conditionnel (AI.DEBUG)

### Métriques Trackées
- Temps de choix de carte
- Nombre d'APIs tentées
- Taux de succès/échec
- Détection de changements d'état

## Troubleshooting Express

### Problème : IA ne joue pas
**Vérifications :**
1. `_G.Tour == "Enemy"` ?
2. `Card.deckAi.cards` non vide ?
3. `enemy.state.power > 0` ?
4. `getCurrentEnemy()` valide ?

### Problème : Cartes sans effet
**Le système essaie automatiquement :**
1. modernCardSystem()
2. callCardSystemLegacy()  
3. runOnPlay()
4. applyGeneric()

### Problème : Erreurs de nil
**Solutions :**
```lua
-- Vérifier ordre de chargement
Card = Card or rawget(_G, "Card")

-- Vérifier état des acteurs
if actor and actor.state then ... end

-- Activer debug
AI.DEBUG = true
```

## Exemples Complets

### Usage Standard
```lua
-- main.lua ou scene gameplay
local AI = require("my-librairie/ai/controller")

function love.load()
  -- Chargement initial (fait par EnemiesManager)
  AI.load(currentEnemy)
end

function love.update(dt)
  if _G.Tour == "Enemy" and not AI:isTurnDone() then
    AI:update(dt)
  end
end

function love.draw()
  AI.draw()  -- Télégraphe + debug
end
```

### Usage avec Transition
```lua
-- Dans Template Combat Transition
function startEnemyTurn()
  AI:startTurn(EnemiesManager.curentEnemy)
end

function updateCombat(dt)
  if currentPhase == "enemy_turn" then
    AI:update(dt)
    if AI:isTurnDone() then
      nextPhase = "player_turn" 
    end
  end
end
```

### Debug et Monitoring
```lua
-- Debug complet
AI.DEBUG = true
AI.setConfig({ telegraphMin = 2.0 })  -- Preview lent

-- Monitoring en temps réel
function printAIStatus()
  print("État:", AI.state)
  print("Occupé:", AI.busy)
  print("Tour fini:", AI:isTurnDone())
  print("Ennemi:", getCurrentEnemy() and getCurrentEnemy().name)
end
```

Cette documentation de référence rapide complète la documentation principale et permet une prise en main immédiate du contrôleur IA ! 🚀
