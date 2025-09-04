# Guide du Positionnement Automatique HUD

## Vue d'ensemble

Le système HUD intègre des fonctionnalités de positionnement automatique permettant d'organiser dynamiquement les éléments UI basés sur leur contenu.

## Fonctionnalités Clés

### ✅ Calcul Automatique des Tailles
- Dimensions basées sur le contenu textuel
- Padding automatique configurable
- Support multilingue natif

### ✅ Organisation Intelligente
- Espacement uniforme entre éléments
- Respect de la visibilité des composants
- Largeur maximale automatique

### ✅ Intégration HUD
- Compatible avec l'architecture centralisée
- Respect du système de couches
- Logs détaillés pour debugging

---

## API Rapide

### Fonction de Base

```lua
local function organizeButtonsInPanel()
    local fontSize = 20        -- Taille de police
    local spacing = 15         -- Espacement entre éléments
    local startX = 10          -- Marge gauche
    local startY = 10          -- Marge haute
    
    local currentY = startY
    local maxWidth = 0

    -- Liste d'éléments à organiser
    local elementOrder = { "element1", "element2", "element3" }

    for _, elementId in ipairs(elementOrder) do
        local elementData = elements[elementId]
        
        if elementData and isVisible(elementData) then
            -- Calcul automatique des dimensions
            local text = getElementText(elementData)
            local textWidth, textHeight = getTextDimensions(text, fontSize)
            
            -- Attribution des propriétés
            elementData.width = textWidth + 40
            elementData.height = textHeight + 20
            elementData.vector2 = {
                x = containerX + startX,
                y = containerY + currentY
            }
            
            maxWidth = math.max(maxWidth, elementData.width)
            currentY = currentY + elementData.height + spacing
        end
    end
    
    return maxWidth, currentY - startY
end
```

### Calcul de Dimensions Textuelles

```lua
local function getTextDimensions(text, fontSize)
    if not text then return 0, 0 end
    
    local textStr = tostring(text)
    local size = fontSize or 20
    
    -- Estimation fiable basée sur ratio caractères
    local charWidth = size * 0.6
    local width = #textStr * charWidth
    local height = size
    
    return width, height
end
```

---

## Patterns d'Usage

### Menu Principal

```lua
-- Configuration des boutons sans positions manuelles
mainMenu.buttons = {
    play = {
        texte = function() return _G.t("ui.menu.play") or "Jouer" end,
        action = function(btn) startGame() end
    },
    continue = {
        texte = function() return _G.t("ui.menu.continue") or "Continuer" end,
        visible = function() return hasSaves() end,
        action = function(btn) loadGame() end
    }
}

-- Dans load() - organisation automatique
function mainMenu:load()
    createButtonPanel()
    local totalWidth, totalHeight = organizeButtonsInPanel()
    _log("Espace utilisé: " .. totalWidth .. "x" .. totalHeight)
end
```

### Panel de Configuration

```lua
-- Organisation d'options avec différentes tailles
local options = {
    { id = "volume", text = "Volume: 50%" },
    { id = "fullscreen", text = "Plein Écran: OUI" },
    { id = "language", text = "Langue: Français" }
}

function organizeOptionsPanel()
    local currentY = 20
    for _, option in ipairs(options) do
        local width, height = getTextDimensions(option.text, 18)
        
        setupElement(option.id, {
            x = 50, y = currentY,
            width = width + 30, height = height + 15
        })
        
        currentY = currentY + height + 25
    end
end
```

---

## Gestion de la Visibilité

### Fonction de Vérification

```lua
local function isElementVisible(elementData)
    if not elementData then return false end
    
    if elementData.visible and type(elementData.visible) == "function" then
        return elementData.visible()
    end
    
    return elementData.visible ~= false
end
```

### Intégration dans l'Organisation

```lua
for _, elementId in ipairs(elementOrder) do
    local elementData = elements[elementId]
    
    if elementData and isElementVisible(elementData) then
        -- Positionner seulement les éléments visibles
        organizeElement(elementData)
    end
end
```

---

## Configuration et Personnalisation

### Paramètres par Défaut

```lua
local layoutConfig = {
    fontSize = 20,
    spacing = 15,
    paddingX = 40,    -- 20px de chaque côté
    paddingY = 20,    -- 10px haut/bas
    marginX = 10,     -- Marge gauche du conteneur
    marginY = 10      -- Marge haute du conteneur
}
```

### Adaptation Responsive

```lua
-- Ajustement basé sur la résolution
local screenScale = _G.screen and _G.screen.scale or 1
layoutConfig.fontSize = math.floor(layoutConfig.fontSize * screenScale)
layoutConfig.spacing = math.floor(layoutConfig.spacing * screenScale)
```

---

## Logs et Debugging

### Logs Typiques

```
[mainMenu] Panel conteneur créé à position: 60, 490
[mainMenu] Bouton 'play' positionné à: 70, 500 (taille: 100x40)
[mainMenu] Bouton 'continue' positionné à: 70, 555 (taille: 148x40)
[mainMenu] Bouton 'loadSave' positionné à: 70, 610 (taille: 208x40)
[mainMenu] Boutons organisés automatiquement - espace utilisé: 208x385
```

### Fonction de Debug

```lua
local function debugLayoutInfo(elements, totalWidth, totalHeight)
    _log("[Layout] Organisation terminée:")
    _log("  Éléments traités: " .. #elements)
    _log("  Largeur maximale: " .. totalWidth)
    _log("  Hauteur totale: " .. totalHeight)
    
    for id, data in pairs(elements) do
        if data.vector2 then
            _log("  " .. id .. ": " .. data.vector2.x .. "," .. data.vector2.y .. 
                 " (" .. data.width .. "x" .. data.height .. ")")
        end
    end
end
```

---

## Bonnes Pratiques

### ✅ À Faire

1. **Organiser au chargement** : Appeler l'organisation dans `load()`
2. **Respecter la visibilité** : Vérifier `visible()` avant positionnement
3. **Logger les résultats** : Garder des traces pour debugging
4. **Configurer les espaces** : Utiliser des constantes pour les spacings

### ❌ À Éviter

1. **Positions hard-codées** : Laisser le système calculer
2. **Réorganisation fréquente** : Optimiser les appels
3. **Ignorer la visibilité** : Respecter les conditions d'affichage
4. **Pas de logs** : Garder la traçabilité

---

## Exemples Complets

### Menu Adaptatif Complet

```lua
local menu = {
    buttons = {
        newGame = { text = "Nouvelle Partie", action = startNewGame },
        continue = { text = "Continuer", visible = hasSaves, action = loadGame },
        options = { text = "Options", action = showOptions },
        quit = { text = "Quitter", action = quitGame }
    }
}

function menu:load()
    -- Créer le conteneur
    hud.setPanel("menu_container", 100, 200, 300, 400, 
        { layer = "background" }, { type = "container" })
    
    -- Organisation automatique
    local totalW, totalH = self:organizeButtons()
    
    -- Ajuster la taille du conteneur si nécessaire
    if totalH > 400 then
        hud.setPanel("menu_container", 100, 200, 300, totalH + 40)
    end
end

function menu:organizeButtons()
    local config = { fontSize = 22, spacing = 18, startY = 20 }
    local currentY = config.startY
    local maxWidth = 0
    
    for _, buttonData in pairs(self.buttons) do
        if isVisible(buttonData) then
            local w, h = calculateButtonSize(buttonData.text, config.fontSize)
            positionButton(buttonData, 20, currentY, w, h)
            
            maxWidth = math.max(maxWidth, w)
            currentY = currentY + h + config.spacing
        end
    end
    
    return maxWidth, currentY - config.startY
end
```

Ce guide fournit tout le nécessaire pour implémenter et utiliser efficacement le système de positionnement automatique du HUD.
