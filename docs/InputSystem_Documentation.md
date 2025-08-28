# Documentation du Système d'Input - LÖVE2D Game

## Vue d'ensemble

Le système d'input du jeu est composé de deux modules principaux qui travaillent ensemble pour fournir une interface unifiée pour les entrées souris et manette :

- **`inputInterface.lua`** : Interface bas niveau pour la capture unifiée souris/gamepad
- **`inputManager.lua`** : Manager haut niveau avec helpers et API simplifiée

## Architecture

```
┌─────────────────────┐
│   inputManager.lua  │ ← API haut niveau, helpers de jeu
│                     │
└─────────┬───────────┘
          │ délègue vers
┌─────────▼───────────┐
│  inputInterface.lua │ ← Interface bas niveau, gestion hardware
│                     │
└─────────────────────┘
```

---

## inputInterface.lua

### Responsabilités
- **Détection et basculement automatique** entre souris et manette
- **Cursor virtuel unifié** qui peut être contrôlé par les deux sources
- **Gestion des axes** de manette avec zone morte (deadzone)
- **État des boutons d'action** avec détection front-edge/release
- **Conversion d'espace de coordonnées** (window → game space)

### API Principale

#### Configuration
```lua
local I = require("my-librairie/inputInterface")
I.init() -- Initialise le cursor depuis la position actuelle de la souris
```

#### Mise à jour
```lua
I.update(dt) -- À appeler chaque frame dans love.update(dt)
```

#### État du Cursor
```lua
local cursor = I.getCursor()
-- Retourne: { x = number, y = number, source = "mouse"|"gamepad" }

local source = I.getActiveSource()
-- Retourne: "mouse" ou "gamepad"
```

#### État des Actions
```lua
local isDown = I.isActionDown()         -- Bouton maintenu
local justPressed = I.justPressedAction()  -- Front-edge (true une seule frame)
local justReleased = I.justReleasedAction() -- Release-edge (true une seule frame)
```

### Configuration Interne

#### Paramètres de la manette
```lua
local deadzone = 0.3        -- Zone morte des axes (0.0 à 1.0)
local sensitivity = 800     -- Pixels par seconde pour axe à fond
```

#### Sources d'entrée supportées
- **Souris** : Bouton gauche (love.mouse.isDown(1))
- **Manette** : Bouton A (gamepad:isGamepadDown('a'))

### Logique de Basculement

1. **Vers Gamepad** : Si les axes dépassent la deadzone
2. **Vers Souris** : Si la position souris change significativement

### Conversion d'Espace

Le système convertit automatiquement les coordonnées :
- **Window coords** → **Game coords** via `screen.ratioScreen`
- **Clamp** aux limites de `screen.gameReso` si disponible

---

## inputManager.lua

### Responsabilités
- **API simplifiée** pour les autres modules du jeu
- **Helpers spécialisés** (hover detection, état des clics)
- **Raccourcis de fin de tour** (E, Return, Space)
- **Abstraction** de l'interface bas niveau

### API Principale

#### Initialisation
```lua
local input = require("my-librairie/inputManager")
input.update(dt) -- À appeler chaque frame
```

#### Détection de Survol
```lua
local isHovering = input.hover(x, y, width, height, scale)
-- scale: table {x, y} ou {sx, sy} ou nombre
-- Retourne: true si le cursor est dans la zone
```

#### État des Clics
```lua
local clicked = input.click()        -- Front-edge click (true une frame)
local state = input.state()         -- "pressed"|"held"|"released"|"idle"
local justPressed = input.justPressed()   -- Front-edge (true une frame)
local justReleased = input.justReleased() -- Release-edge (true une frame)
```

#### Raccourcis de Jeu
```lua
input.endTurnHotkeys() -- Gère E/Return/Space pour fin de tour
-- Condition: _G.Tour == 'player'
-- Action: Transition.requestEndTurn()
```

### Machine à États pour les Clics

```
    justPressed()
   ┌─────────────┐
   │   pressed   │
   └─────┬───────┘
         │ maintien
   ┌─────▼───────┐    justReleased()
   │    held     │ ─────────────────► idle
   └─────────────┘
```

### Variables Internes

```lua
local lockClick = false  -- Évite les répétitions de "pressed"
```

---

## Patterns d'Usage

### Pattern Standard dans une Scène
```lua
-- Dans scene.update(dt)
local input = require("my-librairie/inputManager")
input.update(dt)

-- Détection de hover sur un bouton
if input.hover(buttonX, buttonY, buttonW, buttonH) then
    -- Highlight du bouton
    if input.justPressed() then
        -- Action du bouton
    end
end

-- Raccourcis de fin de tour (si applicable)
input.endTurnHotkeys()
```

### Pattern avec Support Manette
```lua
local inputInterface = require("my-librairie/inputInterface")
local cursor = inputInterface.getCursor()

-- Affichage du cursor (optionnel pour gamepad)
if cursor.source == "gamepad" then
    love.graphics.circle("fill", cursor.x, cursor.y, 5)
end
```

### Pattern pour UI Responsive
```lua
local scale = screen.ratioScreen or {x = 1, y = 1}
if input.hover(uiX, uiY, uiW, uiH, scale) then
    -- Interaction UI avec scaling automatique
end
```

---

## Intégration avec le Système Global

### Globales Utilisées
```lua
_G.screen.ratioScreen     -- Conversion window→game coords
_G.screen.gameReso        -- Limites de l'espace de jeu
_G.Tour                   -- État du tour pour raccourcis
_G.Transition             -- Pour requestEndTurn()
```

### Dépendances LÖVE2D
```lua
love.joystick.getJoysticks()   -- Détection manettes
love.mouse.getPosition()       -- Position souris
love.mouse.isDown(1)           -- Bouton souris
love.keyboard.isDown()         -- Raccourcis clavier
```

---

## Avantages du Système

### ✅ Unification
- **Une seule API** pour souris et manette
- **Basculement automatique** transparent pour le développeur
- **Cursor virtuel** cohérent indépendamment de la source

### ✅ Robustesse
- **Safe requires** avec fallbacks
- **Gestion des échelles** automatique
- **Zones mortes** configurables pour les manettes

### ✅ Performance
- **État persistant** évite les recalculs
- **Front-edge detection** optimisée
- **Lazy loading** de l'interface

### ✅ Flexibilité
- **API à deux niveaux** (bas niveau + helpers)
- **Extensible** pour nouveaux types d'entrée
- **Configuration** centralisée

---

## Cas d'Usage Typiques

### 1. Menu Principal
```lua
-- Détection de clic sur boutons
if input.hover(playButtonX, playButtonY, playButtonW, playButtonH) then
    if input.justPressed() then
        scene:switch("gameplay")
    end
end
```

### 2. Gameplay avec Cartes
```lua
-- Sélection de carte avec souris ou manette
for i, card in ipairs(hand) do
    if input.hover(card.x, card.y, card.w, card.h) then
        card.highlighted = true
        if input.justPressed() then
            selectCard(i)
        end
    end
end
```

### 3. Combat avec Raccourcis
```lua
-- Fin de tour avec E/Return/Space
input.endTurnHotkeys() -- Automatique si Tour == 'player'
```

---

## Debugging et Logs

### Informations de Debug Utiles
```lua
-- Source active d'entrée
local source = inputInterface.getActiveSource()
print("Input source:", source)

-- Position du cursor virtuel
local cursor = inputInterface.getCursor()
print("Cursor:", cursor.x, cursor.y, cursor.source)

-- État détaillé des actions
local state = input.state()
print("Action state:", state)
```

### Problèmes Courants

#### Cursor ne bouge pas avec la manette
- Vérifier que la manette est détectée : `love.joystick.getJoysticks()`
- Ajuster `deadzone` si les axes sont trop sensibles
- Vérifier `sensitivity` pour la vitesse de déplacement

#### Clics non détectés
- Vérifier que `input.update(dt)` est appelé chaque frame
- S'assurer que `inputInterface.update(dt)` est également appelé
- Vérifier les coordonnées avec scaling si `screen.ratioScreen` est utilisé

#### Basculement intempestif souris/manette
- Augmenter `deadzone` pour éviter le bruit des axes
- Vérifier que la souris ne bouge pas involontairement

---

## Notes de Maintenance

### Évolution Future
- Support de manettes multiples
- Gestures tactiles
- Configurabilité des touches
- Profils d'entrée sauvegardés

### Bonnes Pratiques
- Toujours appeler `update()` avant utilisation
- Utiliser `justPressed()` pour les actions one-shot
- Préférer `hover()` avec scaling pour l'UI responsive
- Tester avec les deux sources d'entrée (souris ET manette)
