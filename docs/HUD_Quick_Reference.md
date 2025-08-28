# HUD Quick Reference Guide

## Setup Rapide

```lua
-- Dans love.load()
hud.load()

-- Dans love.update(dt)
hud.update(dt)

-- Dans love.draw()
hud.draw()
```

## API Essentielle

### Création d'Éléments

| Fonction | Usage | Exemple |
|----------|-------|---------|
| `hud.addIcon(id, opts)` | Images/icônes | `hud.addIcon("logo", {img="logo.png", x=100, y=50})` |
| `hud.addLabel(id, opts)` | Texte | `hud.addLabel("title", {text="Titre", x=200, y=20})` |
| `hud.addButton(id, opts)` | Boutons | `hud.addButton("play", {text="Jouer", x=300, y=400, onClick=startGame})` |
| `hud.addBar(id, opts)` | Barres progression | `hud.addBar("health", {x=50, y=100, current=80, max=100})` |
| `hud.setPanel(id, x, y, w, h, opts, options)` | Conteneurs | `hud.setPanel("bg", 0, 0, 800, 600, {}, {color={0,0,0,0.5}})` |

### Modification d'Éléments

| Fonction | Usage | Exemple |
|----------|-------|---------|
| `hud.setText(id, text)` | Change le texte | `hud.setText("score", "Score: 1500")` |
| `hud.setBar(id, cur, max)` | Met à jour barre | `hud.setBar("health", 60, 100)` |
| `hud.get(id)` | Récupère élément | `local btn = hud.get("my_button")` |
| `hud.remove(id)` | Supprime élément | `hud.remove("old_panel")` |

## Options Communes

```lua
{
    x = 100,           -- Position X
    y = 50,            -- Position Y
    w = 200,           -- Largeur
    h = 60,            -- Hauteur
    layer = "button",  -- Couche de rendu
    parent = "panel1", -- Élément parent (optionnel)
    img = "path.png",  -- Image (pour icônes/boutons)
    text = "Texte",    -- Texte affiché
    onClick = function() end  -- Callback (boutons)
}
```

## Couches de Rendu

```lua
"background"  -- Arrière-plans, overlays
"decor"       -- Décorations, titres  
"props"       -- Icônes, indicateurs
"card"        -- Cartes, éléments principaux
"button"      -- Boutons (toujours au premier plan)
```

## Boutons : Deux Modes

### Avec Image
```lua
hud.addButton("img_btn", {
    img = "button.png",
    text = "Cliquer",
    x = 100, y = 100,
    onClick = callback
    -- Pas de bgColor par défaut
})
```

### Avec Fond Coloré
```lua
hud.addButton("color_btn", {
    text = "Valider",
    x = 100, y = 100,
    bgColor = {0.2, 0.6, 0.2, 1},      -- Vert
    hoverColor = {0.3, 0.7, 0.3, 1},   -- Plus clair au survol
    clickColor = {0.1, 0.5, 0.1, 1},   -- Plus sombre au clic
    textColor = {1, 1, 1, 1},          -- Blanc
    borderColor = {0.1, 0.3, 0.1, 1},  -- Bordure
    cornerRadius = 8,                  -- Coins arrondis
    onClick = callback
})
```

## Patterns Courants

### HUD de Scène
```lua
local hud_scene = {}

function hud_scene.load()
    if hud.clear then hud.clear() end
    
    -- Background
    hud.setPanel("scene_bg", 0, 0, W(), H(), {}, {
        color = {0, 0, 0, 0.8}
    })
    
    -- Title
    hud.addLabel("title", {
        text = "Ma Scène",
        x = W()/2 - 100,
        y = 50,
        layer = "decor"
    })
    
    -- Back button
    hud.addButton("back", {
        text = "Retour",
        x = 50, y = H() - 100,
        w = 120, h = 40,
        onClick = function() scene:pop() end
    })
end

return hud_scene
```

### Mise à Jour Dynamique
```lua
function updateUI()
    local player = getPlayer()
    
    -- Santé
    hud.setBar("health", player.health, player.maxHealth)
    hud.setText("health_text", player.health .. "/" .. player.maxHealth)
    
    -- Score
    hud.setText("score", "Score: " .. player.score)
    
    -- Énergie
    hud.setText("energy", "Énergie: " .. player.energy)
end
```

### Responsive
```lua
local function W()
    return (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
end

local function H()
    return (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
end

-- Centrage automatique
local centerX = (W() - buttonWidth) / 2
local bottomY = H() - 100
```

## Débogage

```lua
-- Activer logs détaillés
hud.HUD_DEBUG_ENERGY = true

-- Inspecter élément
local el = hud.get("my_element")
if el then
    print("Type:", el.type, "Layer:", el.layer)
    print("Position:", el.x, el.y)
    print("Taille:", el.w, el.h)
end

-- Lister tous les éléments
for id, el in pairs(elements) do
    print(id, "->", el.type)
end
```

## Audio
```lua
-- Configuration
hud.setSfx({
    click = "sounds/click.wav",
    hover = "sounds/hover.wav"
})

-- Jouer son
hud.sfx("click")
```

## Erreurs Courantes

❌ **Mauvais**
```lua
-- Recréer constamment
function update()
    hud.remove("score")
    hud.addLabel("score", {text = "Score: " .. score})
end
```

✅ **Bon**
```lua
-- Mettre à jour
function update()
    hud.setText("score", "Score: " .. score)
end
```

❌ **Mauvais**
```lua
-- Oublier de nettoyer
function Scene:enter()
    hud.addButton("btn", ...)  -- S'accumule à chaque entrée
end
```

✅ **Bon**
```lua
function Scene:enter()
    if hud.clear then hud.clear() end  -- Nettoyer d'abord
    hud.addButton("btn", ...)
end
```

## Ordre d'Intégration

1. **love.load()** → `hud.load()`
2. **Scene:enter()** → Créer HUD spécifique
3. **Scene:update()** → `hud.update(dt)` + mise à jour données
4. **Scene:draw()** → `hud.draw()` (en dernier)
5. **Scene:leave()** → `hud.clear()` ou nettoyage sélectif
