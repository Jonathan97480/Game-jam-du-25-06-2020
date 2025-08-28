# Input System - Quick Reference

## API Référence Rapide

### inputManager.lua (API Principale)

```lua
local input = require("my-librairie/inputManager")

-- 🔄 Mise à jour (obligatoire chaque frame)
input.update(dt)

-- 🎯 Détection de survol
input.hover(x, y, width, height, scale) → boolean

-- 🖱️ État des clics
input.click()         → boolean|nil    -- Front-edge click
input.state()         → string         -- "pressed"|"held"|"released"|"idle"
input.justPressed()   → boolean        -- Front-edge detection
input.justReleased()  → boolean        -- Release-edge detection

-- ⌨️ Raccourcis de jeu
input.endTurnHotkeys()                 -- E/Return/Space → fin de tour
```

### inputInterface.lua (Interface Bas Niveau)

```lua
local I = require("my-librairie/inputInterface")

-- 🔧 Initialisation
I.init()
I.update(dt)

-- 📍 Position du cursor
I.getCursor()         → {x, y, source}  -- Position unifiée
I.getActiveSource()   → string          -- "mouse"|"gamepad"

-- 🎮 État des actions
I.isActionDown()      → boolean         -- Bouton maintenu
I.justPressedAction() → boolean         -- Front-edge
I.justReleasedAction()→ boolean         -- Release-edge
```

---

## Patterns d'Usage Courants

### 🎮 Pattern Menu/UI
```lua
-- Dans scene.update(dt)
input.update(dt)

if input.hover(buttonX, buttonY, buttonW, buttonH) then
    -- Highlight
    if input.justPressed() then
        -- Action
    end
end
```

### 🃏 Pattern Cartes/Gameplay
```lua
for i, card in ipairs(hand) do
    if input.hover(card.x, card.y, card.w, card.h) then
        card.highlighted = true
        if input.justPressed() then
            selectCard(i)
        end
    end
end

-- Fin de tour automatique
input.endTurnHotkeys()
```

### 🖱️ Pattern avec Cursor Virtuel
```lua
local cursor = inputInterface.getCursor()

-- Affichage cursor pour manette
if cursor.source == "gamepad" then
    love.graphics.circle("fill", cursor.x, cursor.y, 5)
end
```

---

## Configuration

### ⚙️ Paramètres inputInterface
```lua
-- Dans le code (constantes internes)
local deadzone = 0.3        -- Zone morte axes manette (0.0-1.0)
local sensitivity = 800     -- Pixels/sec pour axe à fond
```

### 🎯 Mapping des Boutons
```lua
-- Souris
love.mouse.isDown(1)        -- Bouton gauche

-- Manette  
joystick:isGamepadDown('a') -- Bouton A

-- Clavier (fin de tour)
love.keyboard.isDown('e')       -- E
love.keyboard.isDown('return')  -- Entrée
love.keyboard.isDown('space')   -- Espace
```

---

## Machine à États

### 🔄 États des Clics
```
idle → [click] → pressed → [hold] → held → [release] → idle
       ↑                                      ↓
   justPressed()                        justReleased()
```

### 🔀 Basculement Source
```
mouse ←→ gamepad
  ↑         ↓
position   axes > deadzone
changed
```

---

## Debugging

### 🐛 Vérifications Communes
```lua
-- Source active
print("Input source:", inputInterface.getActiveSource())

-- Position cursor
local cursor = inputInterface.getCursor()
print(string.format("Cursor: %.1f, %.1f (%s)", 
    cursor.x, cursor.y, cursor.source))

-- État action
print("Action state:", input.state())
```

### ⚠️ Problèmes Fréquents
- **Cursor immobile** → Vérifier deadzone manette
- **Clics ignorés** → S'assurer que `update()` est appelé
- **Basculement erratique** → Ajuster deadzone ou stabiliser souris
- **Scaling incorrect** → Vérifier `screen.ratioScreen`

---

## Intégration SceneManager

### 📋 Pattern Standard dans une Scène
```lua
local scene = { name = "example" }

function scene.update(dt)
    input.update(dt)  -- OBLIGATOIRE
    
    -- Logique d'interaction
    -- ...
    
    input.endTurnHotkeys()  -- Si applicable
end

function scene.mousepressed(x, y, button)
    -- Optionnel : gestion événements LÖVE2D directs
end

return scene
```

### 🔗 Globales Utilisées
```lua
_G.screen.ratioScreen     -- Scaling window→game
_G.screen.gameReso        -- Limites jeu
_G.Tour                   -- État tour joueur
_G.Transition             -- Fin de tour
```

---

## Exemples Complets

### 🎯 Bouton Simple
```lua
local buttonX, buttonY = 100, 100
local buttonW, buttonH = 200, 50

function scene.update(dt)
    input.update(dt)
    
    if input.hover(buttonX, buttonY, buttonW, buttonH) then
        -- Visual feedback
        buttonHighlighted = true
        
        if input.justPressed() then
            print("Bouton cliqué!")
            -- Action du bouton
        end
    else
        buttonHighlighted = false
    end
end
```

### 🃏 Sélection de Cartes
```lua
function scene.update(dt)
    input.update(dt)
    
    selectedCard = nil
    
    for i, card in ipairs(playerHand) do
        if input.hover(card.x, card.y, card.w, card.h) then
            card.hovered = true
            
            if input.justPressed() then
                selectedCard = i
                -- Jouer la carte
                playCard(card)
            end
        else
            card.hovered = false
        end
    end
    
    -- Raccourcis fin de tour
    input.endTurnHotkeys()
end
```

### 🎮 Support Manette avec Cursor
```lua
function scene.update(dt)
    input.update(dt)
    
    -- Logique normale...
end

function scene.draw()
    -- Affichage normal...
    
    -- Cursor virtuel pour manette
    local cursor = inputInterface.getCursor()
    if cursor.source == "gamepad" then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", cursor.x, cursor.y, 8)
        love.graphics.setColor(1, 1, 1, 1)
    end
end
```
