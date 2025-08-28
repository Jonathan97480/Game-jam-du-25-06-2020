# Documentation du Système HUD

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [API de Base](#api-de-base)
4. [Composants](#composants)
5. [Système de Couches](#système-de-couches)
6. [Boutons Avancés](#boutons-avancés)
7. [Responsive Design](#responsive-design)
8. [Patterns d'Usage](#patterns-dusage)
9. [Exemples Pratiques](#exemples-pratiques)
10. [Débogage](#débogage)

---

## Vue d'ensemble

Le système HUD (`my-librairie/hud/hud.lua`) est un gestionnaire d'interface utilisateur modulaire et responsive pour LÖVE2D. Il fournit une architecture en couches avec des composants réutilisables et une API unifiée.

### Caractéristiques principales

- **Architecture en 5 couches** : Rendu ordonné et prévisible
- **Composants modulaires** : Boutons, labels, icônes, barres, panels
- **Responsive automatique** : Adaptation aux différentes résolutions
- **Cache de ressources** : Optimisation des images et fonts
- **Système d'événements** : Gestion unifiée des interactions
- **Boutons avancés** : États hover/click avec effets visuels

---

## Architecture

### Structure des Fichiers

```
my-librairie/hud/
├── hud.lua              # Gestionnaire principal (1392+ lignes)
├── button/
│   └── button.lua       # Composant bouton modulaire
├── panel/
│   └── panel.lua        # Composant panel/conteneur
├── text/
│   └── text.lua         # Composant texte avancé
└── draw.lua            # Wrapper LÖVE2D sécurisé
```

### Système de Couches

```lua
-- Ordre de rendu (arrière-plan vers premier plan)
LAYERS = { "background", "decor", "props", "card", "button" }
```

1. **background** : Arrière-plans, overlays de base
2. **decor** : Éléments décoratifs, titres
3. **props** : Icônes, indicateurs de statut
4. **card** : Cartes de jeu, éléments principaux
5. **button** : Boutons interactifs (toujours au premier plan)

---

## API de Base

### Initialisation et Cycle de Vie

```lua
-- Initialisation (appeler au démarrage)
hud.load()

-- Mise à jour (appeler dans love.update)
hud.update(dt)

-- Rendu (appeler dans love.draw)
hud.draw()
```

### Fonctions Core

#### `hud.get(id)`
Récupère un élément par son ID.

```lua
local button = hud.get("my_button")
if button then
    print("Bouton trouvé:", button.text)
end
```

#### `hud.remove(id)`
Supprime un élément et tous ses enfants.

```lua
hud.remove("old_panel")  -- Supprime le panel et ses enfants
```

---

## Composants

### 1. Icônes et Images

#### `hud.addIcon(id, opts)`
Ajoute une icône ou image simple.

```lua
hud.addIcon("health_icon", {
    img = "img/icons/health.png",
    x = 100,
    y = 50,
    w = 32,
    h = 32,
    layer = "props"
})
```

#### `hud.addImage(id, opts)`
Version alternative pour images (alias de addIcon).

### 2. Texte et Labels

#### `hud.addLabel(id, opts)`
Ajoute un label de texte.

```lua
hud.addLabel("score_label", {
    text = "Score: 1000",
    x = 200,
    y = 20,
    layer = "decor",
    color = {1, 1, 1, 1}  -- Blanc
})
```

#### `hud.setText(id, text)`
Met à jour le texte d'un label existant.

```lua
hud.setText("score_label", "Score: 1500")
```

### 3. Barres de Progression

#### `hud.addBar(id, opts)`
Ajoute une barre de progression.

```lua
hud.addBar("health_bar", {
    x = 50,
    y = 100,
    w = 200,
    h = 20,
    current = 80,
    max = 100,
    layer = "props",
    fg = "img/ui/health_bar_fill.png",  -- Image de remplissage
    bg = "img/ui/health_bar_bg.png",    -- Image de fond
    border = {0.5, 0.5, 0.5, 1}         -- Couleur de bordure
})
```

#### `hud.setBar(id, current, max)`
Met à jour les valeurs d'une barre.

```lua
hud.setBar("health_bar", 60, 100)  -- 60% de santé
```

---

## Boutons Avancés

### `hud.addButton(id, opts)`

Le système de boutons supporte deux modes :
1. **Boutons avec images** : Pas de fond par défaut, effets par teinture
2. **Boutons avec fond coloré** : États hover/click complets

#### Bouton avec Image

```lua
hud.addButton("play_btn", {
    img = "img/ui/play_button.png",
    x = 400,
    y = 300,
    w = 200,
    h = 60,
    text = "Jouer",
    layer = "button",
    -- Effets optionnels par teinture
    hoverColor = {1.1, 1.1, 1.1, 1},    -- Éclaircissement au survol
    clickColor = {0.9, 0.9, 0.9, 1},    -- Assombrissement au clic
    textColor = {1, 1, 1, 1},           -- Texte blanc
    onClick = function()
        scene:push("scene.gameplay.gameplay")
    end
})
```

#### Bouton avec Fond Coloré

```lua
hud.addButton("continue_btn", {
    x = 300,
    y = 400,
    w = 200,
    h = 50,
    text = "Continuer",
    layer = "button",
    -- Style complet avec fond
    bgColor = {0.2, 0.6, 0.2, 1},       -- Vert foncé
    hoverColor = {0.3, 0.7, 0.3, 1},    -- Vert plus clair au survol
    clickColor = {0.1, 0.5, 0.1, 1},    -- Vert plus sombre au clic
    textColor = {1, 1, 1, 1},           -- Texte blanc
    borderColor = {0.1, 0.3, 0.1, 1},   -- Bordure vert foncé
    cornerRadius = 8,                   -- Coins arrondis
    onClick = function()
        print("Continuer cliqué!")
    end
})
```

### États Automatiques

- **Centrage du texte** : Automatique basé sur les dimensions réelles
- **Effet de clic** : Décalage de 2px pour feedback visuel
- **Détection hover** : États visuels automatiques
- **Position personnalisée** : `tx`, `ty` pour placement manuel du texte

---

## Système de Panels

### `hud.setPanel(id, x, y, w, h, opts, options)`

Les panels sont des conteneurs qui peuvent avoir des enfants et un rendu.

#### Panel Conteneur (invisible)

```lua
hud.setPanel("game_ui", 0, 0, 1920, 1080, {
    children = {
        {type = "label", id = "title", opts = {text = "Mon Jeu", x = 50, y = 50}},
        {type = "button", id = "btn1", opts = {text = "Option 1", x = 50, y = 100}}
    }
}, {
    type = "container"  -- Pas de rendu, enfants seulement
})
```

#### Panel avec Rendu

```lua
-- Panel avec couleur de fond
hud.setPanel("dialog_bg", 200, 150, 400, 300, {}, {
    type = "panel",
    color = {0, 0, 0, 0.8}  -- Fond semi-transparent
})

-- Panel avec image de fond
hud.setPanel("menu_bg", 0, 0, 1920, 1080, {}, {
    type = "panel",
    bg = "img/backgrounds/main_menu.jpg",
    typeRender = "cover"  -- Modes: contain, cover, native
})
```

### `hud.clearPanel(id)`
Supprime tous les enfants d'un panel.

```lua
hud.clearPanel("game_ui")  -- Vide le panel mais le garde
```

---

## Responsive Design

Le système s'adapte automatiquement aux différentes résolutions via `responsive.lua`.

### Fonctions Utilitaires

```lua
-- Obtenir les dimensions de jeu
local function W()
    return (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
end

local function H()
    return (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
end

-- Centrage automatique
local btnX = (W() - 200) / 2  -- Centrer un bouton de 200px de large
local btnY = H() - 100        -- 100px du bas
```

### Mise à l'échelle des Fonts

```lua
-- La fonction fixeSizeFontByResolotionGame() ajuste automatiquement
-- la taille des fonts selon la résolution
```

---

## Patterns d'Usage

### Pattern: Scene HUD Modulaire

```lua
-- scene/mon_scene/HUD/hud_mon_scene.lua
local hud_mon_scene = {}

function hud_mon_scene.load()
    -- Effacer HUD précédent
    if hud.clear then hud.clear() end
    
    -- Créer interface pour cette scène
    hud.setPanel("scene_bg", 0, 0, W(), H(), {}, {
        color = {0.1, 0.1, 0.2, 0.9}
    })
    
    hud.addLabel("title", {
        text = "Ma Scène",
        x = W()/2 - 100,
        y = 50,
        layer = "decor"
    })
    
    hud.addButton("back_btn", {
        text = "Retour",
        x = 50,
        y = H() - 100,
        w = 120,
        h = 40,
        layer = "button",
        onClick = function()
            scene:pop()  -- Retour à la scène précédente
        end
    })
end

function hud_mon_scene.update(dt)
    -- Mise à jour spécifique à la scène
    hud.update(dt)
end

function hud_mon_scene.draw()
    hud.draw()
end

return hud_mon_scene
```

### Pattern: HUD de Jeu Dynamique

```lua
-- Mise à jour d'éléments en temps réel
function updateGameHUD()
    -- Santé du joueur
    local player = getPlayer()
    hud.setBar("health_bar", player.health, player.maxHealth)
    hud.setText("health_text", string.format("%d/%d", player.health, player.maxHealth))
    
    -- Score
    hud.setText("score", "Score: " .. player.score)
    
    -- Énergie avec changement de couleur
    local energy = player.energy
    local energyColor = energy > 3 and {0, 1, 0, 1} or {1, 1, 0, 1}
    hud.setText("energy_text", tostring(energy))
    -- Note: Changement de couleur nécessite recréation du label
end
```

---

## Débogage

### Flags de Debug

```lua
-- Activer les logs d'énergie
hud.HUD_DEBUG_ENERGY = true

-- Logs détaillés dans gameLogs/
-- - hud_elements_snapshot.log : État des éléments
-- - hud_presence.log : Présence des composants
-- - hud_scaled_snapshot.log : Éléments avec mise à l'échelle
```

### Inspection d'Éléments

```lua
-- Lister tous les éléments
for id, el in pairs(hud.get()) do
    print(id, el.type, el.layer)
end

-- Vérifier un élément spécifique
local btn = hud.get("my_button")
if btn then
    print("Type:", btn.type)
    print("Position:", btn.x, btn.y)
    print("Taille:", btn.w, btn.h)
    print("Interactif:", btn.interactive)
else
    print("Élément non trouvé")
end
```

### Commandes de Debug Utiles

```lua
-- Effacer tout le HUD
if hud.clear then hud.clear() end

-- Recharger les ressources
res.clearCache()  -- Vide le cache de ressources

-- Forcer la mise à jour responsive
responsive.updateWindowSize()
```

---

## Fonctions Audio et Effets

### Sons d'Interface

```lua
-- Configuration des sons
hud.setSfx({
    click = "sounds/ui/click.wav",
    hover = "sounds/ui/hover.wav",
    error = "sounds/ui/error.wav"
})

-- Déclencher un son
hud.sfx("click")

-- Sons de drag & drop
hud.drag("start")  -- dragStart
hud.drag("move")   -- dragMove  
hud.drag("end")    -- dragEnd
```

---

## Intégration avec les Scènes

### Dans love.load()

```lua
function love.load()
    -- Initialiser le HUD
    hud.load()
    
    -- Charger la scène avec son HUD
    scene:push("scene.menu.menu")
end
```

### Dans Scene:enter()

```lua
function MenuScene:enter()
    -- Charger HUD spécifique à cette scène
    local hud_menu = require("scene.menu.HUD.hud_menu")
    hud_menu.load()
end
```

### Dans Scene:update()

```lua
function MenuScene:update(dt)
    -- Mise à jour HUD
    hud.update(dt)
    
    -- Logique spécifique à la scène
    -- ...
end
```

### Dans Scene:draw()

```lua
function MenuScene:draw()
    -- Rendu de la scène
    -- ...
    
    -- Rendu HUD (toujours en dernier)
    hud.draw()
end
```

---

## Meilleures Pratiques

### 1. Nommage des IDs

```lua
-- Utiliser des préfixes pour éviter les conflits
hud.addButton("menu_play_btn", ...)     -- Bouton du menu
hud.addButton("game_pause_btn", ...)    -- Bouton du jeu
hud.addLabel("combat_health_label", ...)  -- Label de combat
```

### 2. Gestion des Couches

```lua
-- Respecter l'ordre logique
"background" -- Fonds, overlays
"decor"      -- Titres, décorations
"props"      -- Icônes, indicateurs
"card"       -- Éléments de jeu principaux
"button"     -- Interactions (toujours visible)
```

### 3. Nettoyage

```lua
-- Nettoyer lors des transitions
function Scene:leave()
    if hud.clear then hud.clear() end
end

-- Ou supprimer sélectivement
function Scene:leave()
    hud.remove("scene_specific_panel")
end
```

### 4. Performance

```lua
-- Éviter de recréer constamment
-- Au lieu de:
function update(dt)
    hud.remove("score")
    hud.addLabel("score", {text = "Score: " .. score})
end

-- Faire:
function update(dt)
    hud.setText("score", "Score: " .. score)
end
```

---

## Fonctions Avancées

### Bottom Bar Management

```lua
-- Définir la barre de footer
hud.setBottomBarBg("img/hud/footer.jpg", 0, nil, 65)

-- La barre sert d'ancrage pour autres éléments
local footer_el = hud.get("bottom_bar_bg")
local footer_y = footer_el and footer_el.y or (H() - 65)
```

### Hover Detection

```lua
-- Méthode alternative de détection hover
if hud.hover(x, y, w, h) then
    -- Souris sur zone spécifiée
end
```

### Background Drawing

```lua
-- Rendu de fond séparé
hud.drawBackground()  -- Seulement couche background
```

---

Cette documentation couvre l'ensemble du système HUD. Pour des cas d'usage spécifiques ou des questions avancées, consultez le code source dans `my-librairie/hud/hud.lua` ou les exemples dans `scene/*/HUD/`.
