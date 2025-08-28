# Input System - Exemples Pratiques

## 🎯 Exemples d'Implémentation Réelle

### 1. Menu Principal avec Support Manette

```lua
-- scene/menu/menu.lua
local scene = { name = "menu" }
local input = require("my-librairie/inputManager")
local inputInterface = require("my-librairie/inputInterface")

local buttons = {
    { text = "Jouer", x = 400, y = 300, w = 200, h = 60, action = "play" },
    { text = "Options", x = 400, y = 380, w = 200, h = 60, action = "options" },
    { text = "Quitter", x = 400, y = 460, w = 200, h = 60, action = "quit" }
}

local selectedButton = 1
local showGamepadCursor = false

function scene.load()
    -- Initialisation si nécessaire
end

function scene.enter()
    selectedButton = 1
end

function scene.update(dt)
    input.update(dt)
    
    -- Détection source d'entrée
    local cursor = inputInterface.getCursor()
    showGamepadCursor = (cursor.source == "gamepad")
    
    -- Navigation souris
    for i, button in ipairs(buttons) do
        if input.hover(button.x, button.y, button.w, button.h) then
            selectedButton = i
            
            if input.justPressed() then
                executeButtonAction(button.action)
            end
        end
    end
    
    -- Navigation manette (optionnel : touches directionnelles)
    if inputInterface.getActiveSource() == "gamepad" then
        -- Exemple de navigation avec d-pad
        -- (nécessiterait extension de inputInterface)
    end
end

function scene.draw()
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Titre
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Mon Jeu de Cartes", 0, 150, love.graphics.getWidth(), "center")
    
    -- Boutons
    love.graphics.setFont(buttonFont)
    for i, button in ipairs(buttons) do
        local isSelected = (i == selectedButton)
        
        -- Background bouton
        if isSelected then
            love.graphics.setColor(0.6, 0.6, 0.8)
        else
            love.graphics.setColor(0.4, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
        
        -- Bordure
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h)
        
        -- Texte
        love.graphics.printf(button.text, button.x, button.y + 20, button.w, "center")
    end
    
    -- Cursor virtuel pour manette
    if showGamepadCursor then
        local cursor = inputInterface.getCursor()
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", cursor.x, cursor.y, 8)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.circle("line", cursor.x, cursor.y, 8)
    end
end

function executeButtonAction(action)
    if action == "play" then
        scene:switch("gameplay")
    elseif action == "options" then
        scene:push("options")
    elseif action == "quit" then
        love.event.quit()
    end
end

return scene
```

---

### 2. Gameplay - Sélection et Jeu de Cartes

```lua
-- scene/gameplay/gameplay.lua
local scene = { name = "gameplay" }
local input = require("my-librairie/inputManager")

local playerHand = {}
local selectedCard = nil
local hoveredCard = nil
local cardPlayArea = { x = 300, y = 200, w = 400, h = 300 }

function scene.load()
    -- Charger les cartes
    playerHand = generateStartingHand()
end

function scene.update(dt)
    input.update(dt)
    
    -- Reset états temporaires
    hoveredCard = nil
    
    -- Interaction avec les cartes en main
    for i, card in ipairs(playerHand) do
        if input.hover(card.displayX, card.displayY, card.width, card.height) then
            hoveredCard = i
            
            -- Clic pour sélectionner
            if input.justPressed() then
                if selectedCard == i then
                    -- Double-clic : jouer la carte
                    if isValidPlay(card) then
                        playCard(i)
                    end
                else
                    -- Simple clic : sélectionner
                    selectedCard = i
                end
            end
        end
    end
    
    -- Zone de jeu pour déposer les cartes
    if selectedCard and input.hover(cardPlayArea.x, cardPlayArea.y, cardPlayArea.w, cardPlayArea.h) then
        if input.justPressed() then
            local card = playerHand[selectedCard]
            if isValidPlay(card) then
                playCard(selectedCard)
                selectedCard = nil
            end
        end
    end
    
    -- Annuler sélection avec clic dans le vide
    if input.justPressed() and not hoveredCard and not input.hover(cardPlayArea.x, cardPlayArea.y, cardPlayArea.w, cardPlayArea.h) then
        selectedCard = nil
    end
    
    -- Raccourcis fin de tour
    input.endTurnHotkeys()
end

function scene.draw()
    -- Background de jeu
    drawGameBackground()
    
    -- Zone de jeu
    love.graphics.setColor(0.3, 0.5, 0.3, 0.5)
    love.graphics.rectangle("fill", cardPlayArea.x, cardPlayArea.y, cardPlayArea.w, cardPlayArea.h)
    love.graphics.setColor(0.5, 0.8, 0.5)
    love.graphics.rectangle("line", cardPlayArea.x, cardPlayArea.y, cardPlayArea.w, cardPlayArea.h)
    
    -- Cartes en main
    for i, card in ipairs(playerHand) do
        local isSelected = (selectedCard == i)
        local isHovered = (hoveredCard == i)
        
        drawCard(card, isSelected, isHovered)
    end
    
    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Cliquez sur une carte pour la sélectionner", 10, 10)
    love.graphics.print("Double-cliquez ou glissez vers la zone verte pour jouer", 10, 30)
    love.graphics.print("E, Entrée ou Espace pour finir le tour", 10, 50)
    
    -- Cursor manette
    drawGamepadCursor()
end

function drawCard(card, isSelected, isHovered)
    local x, y = card.displayX, card.displayY
    local w, h = card.width, card.height
    
    -- Offset pour sélection/hover
    if isSelected then
        y = y - 20
    elseif isHovered then
        y = y - 10
    end
    
    -- Background carte
    if isSelected then
        love.graphics.setColor(1, 1, 0.5)
    elseif isHovered then
        love.graphics.setColor(0.8, 0.8, 1)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- Contenu carte
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(card.name, x + 5, y + 5, w - 10, "center")
    love.graphics.printf(tostring(card.cost), x + 5, y + h - 25, w - 10, "center")
end

function drawGamepadCursor()
    local cursor = inputInterface.getCursor()
    if cursor.source == "gamepad" then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", cursor.x, cursor.y, 6)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", cursor.x, cursor.y, 6)
    end
end

function playCard(cardIndex)
    local card = playerHand[cardIndex]
    print("Joue la carte:", card.name)
    
    -- Logique de jeu
    applyCardEffect(card)
    table.remove(playerHand, cardIndex)
    
    -- Reset sélection
    selectedCard = nil
end

return scene
```

---

### 3. Overlay avec Timer et Interaction

```lua
-- scene/overlay_pause/overlay_pause.lua
local scene = { name = "overlay_pause" }
local input = require("my-librairie/inputManager")

local buttons = {
    { text = "Reprendre", x = 350, y = 300, w = 150, h = 50, action = "resume" },
    { text = "Options", x = 350, y = 370, w = 150, h = 50, action = "options" },
    { text = "Menu Principal", x = 350, y = 440, w = 150, h = 50, action = "menu" }
}

local selectedButton = 1
local backgroundAlpha = 0

function scene.enter()
    selectedButton = 1
    backgroundAlpha = 0
end

function scene.update(dt)
    input.update(dt)
    
    -- Animation d'apparition
    backgroundAlpha = math.min(0.8, backgroundAlpha + dt * 3)
    
    -- Interaction avec boutons
    for i, button in ipairs(buttons) do
        if input.hover(button.x, button.y, button.w, button.h) then
            selectedButton = i
            
            if input.justPressed() then
                executeAction(button.action)
            end
        end
    end
    
    -- Raccourci Échap pour reprendre (exemple)
    if love.keyboard.isDown("escape") then
        scene:pop()
    end
end

function scene.draw()
    -- Background semi-transparent
    love.graphics.setColor(0, 0, 0, backgroundAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Panel principal
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", 250, 200, 300, 350)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 250, 200, 300, 350)
    
    -- Titre
    love.graphics.setFont(titleFont)
    love.graphics.printf("PAUSE", 250, 230, 300, "center")
    
    -- Boutons
    love.graphics.setFont(buttonFont)
    for i, button in ipairs(buttons) do
        local isSelected = (i == selectedButton)
        
        if isSelected then
            love.graphics.setColor(0.6, 0.6, 0.8)
        else
            love.graphics.setColor(0.4, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h)
        love.graphics.printf(button.text, button.x, button.y + 15, button.w, "center")
    end
    
    -- Cursor manette
    drawGamepadCursor()
end

function executeAction(action)
    if action == "resume" then
        scene:pop()
    elseif action == "options" then
        scene:push("options")
    elseif action == "menu" then
        scene:switch("menu")
    end
end

return scene
```

---

### 4. HUD Intégré avec Input

```lua
-- scene/hud_overlay/game_hud.lua
local scene = { name = "game_hud" }
local input = require("my-librairie/inputManager")

local hudElements = {
    pauseButton = { x = 750, y = 20, w = 50, h = 30 },
    menuButton = { x = 700, y = 20, w = 40, h = 30 },
    endTurnButton = { x = 600, y = 500, w = 120, h = 40 }
}

function scene.update(dt)
    input.update(dt)
    
    -- Bouton pause
    if input.hover(hudElements.pauseButton.x, hudElements.pauseButton.y, 
                   hudElements.pauseButton.w, hudElements.pauseButton.h) then
        if input.justPressed() then
            scene:push("overlay_pause")
        end
    end
    
    -- Bouton menu
    if input.hover(hudElements.menuButton.x, hudElements.menuButton.y,
                   hudElements.menuButton.w, hudElements.menuButton.h) then
        if input.justPressed() then
            scene:switch("menu")
        end
    end
    
    -- Bouton fin de tour
    if _G.Tour == 'player' then
        if input.hover(hudElements.endTurnButton.x, hudElements.endTurnButton.y,
                       hudElements.endTurnButton.w, hudElements.endTurnButton.h) then
            if input.justPressed() then
                if _G.Transition and _G.Transition.requestEndTurn then
                    _G.Transition.requestEndTurn()
                end
            end
        end
    end
    
    -- Raccourcis automatiques
    input.endTurnHotkeys()
end

function scene.draw()
    -- Panel HUD
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 60)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 80, love.graphics.getWidth(), 80)
    
    -- Boutons HUD
    drawHudButton(hudElements.pauseButton, "||", input.hover(
        hudElements.pauseButton.x, hudElements.pauseButton.y,
        hudElements.pauseButton.w, hudElements.pauseButton.h))
    
    drawHudButton(hudElements.menuButton, "☰", input.hover(
        hudElements.menuButton.x, hudElements.menuButton.y,
        hudElements.menuButton.w, hudElements.menuButton.h))
    
    if _G.Tour == 'player' then
        drawHudButton(hudElements.endTurnButton, "Fin de Tour", input.hover(
            hudElements.endTurnButton.x, hudElements.endTurnButton.y,
            hudElements.endTurnButton.w, hudElements.endTurnButton.h))
    end
    
    -- Informations de jeu
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Tour: " .. (_G.Tour or "?"), 20, 20)
    love.graphics.print("E/Entrée/Espace: Fin de tour", 20, love.graphics.getHeight() - 60)
end

function drawHudButton(button, text, isHovered)
    if isHovered then
        love.graphics.setColor(0.6, 0.6, 0.8)
    else
        love.graphics.setColor(0.3, 0.3, 0.4)
    end
    
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", button.x, button.y, button.w, button.h)
    love.graphics.printf(text, button.x, button.y + 8, button.w, "center")
end

return scene
```

---

### 5. Configuration Avancée avec Personnalisation

```lua
-- my-librairie/inputConfig.lua
local config = {}

-- Configuration personnalisable
config.gamepad = {
    deadzone = 0.25,        -- Zone morte des axes
    sensitivity = 600,      -- Vitesse cursor (pixels/sec)
    actionButton = 'a',     -- Bouton d'action principal
    menuButton = 'start',   -- Bouton menu
    backButton = 'b'        -- Bouton retour
}

config.mouse = {
    primaryButton = 1,      -- Bouton principal (gauche)
    secondaryButton = 2     -- Bouton secondaire (droit)
}

config.keyboard = {
    endTurnKeys = {'e', 'return', 'space'},
    pauseKey = 'escape',
    menuKey = 'tab'
}

-- Extension de inputInterface pour configuration
function config.applyToInputInterface(inputInterface)
    if inputInterface.setDeadzone then
        inputInterface.setDeadzone(config.gamepad.deadzone)
    end
    if inputInterface.setSensitivity then
        inputInterface.setSensitivity(config.gamepad.sensitivity)
    end
end

-- Helper pour vérifier les touches personnalisées
function config.isEndTurnPressed()
    for _, key in ipairs(config.keyboard.endTurnKeys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end

function config.isPausePressed()
    return love.keyboard.isDown(config.keyboard.pauseKey)
end

-- Sauvegarde/Chargement configuration
function config.save()
    local data = love.filesystem.write("input_config.json", json.encode(config))
    return data
end

function config.load()
    if love.filesystem.getInfo("input_config.json") then
        local data = love.filesystem.read("input_config.json")
        if data then
            local loaded = json.decode(data)
            if loaded then
                for k, v in pairs(loaded) do
                    config[k] = v
                end
            end
        end
    end
end

return config
```

---

## 🎮 Conseils d'Implémentation

### Performance
- Toujours appeler `input.update(dt)` **une seule fois** par frame
- Utiliser `justPressed()` pour les actions one-shot plutôt que de gérer manuellement les états
- Éviter les appels multiples à `getCursor()` - stocker le résultat

### UX Manette
- Toujours afficher un cursor virtuel quand la manette est active
- Prévoir une navigation alternative au hover (touches directionnelles)
- Tester les zones mortes selon les manettes utilisées

### Debug
- Afficher la source d'entrée active pour debug
- Logger les changements de source pour détecter les basculements intempestifs
- Utiliser des rectangles de debug pour visualiser les zones de clic

### Accessibilité
- Permettre la personnalisation des touches
- Supporter plusieurs manettes pour le multijoueur
- Prévoir des retours visuels clairs pour les interactions
