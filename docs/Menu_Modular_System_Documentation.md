# Documentation du Système de Menu Modulaire

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Panneaux Disponibles](#panneaux-disponibles)
4. [Configuration et Positions](#configuration-et-positions)
5. [Navigation Inter-Panneaux](#navigation-inter-panneaux)
6. [Sauvegarde Automatique](#sauvegarde-automatique)
7. [Système de Notifications](#système-de-notifications)
8. [Ressources et Assets](#ressources-et-assets)
9. [Exemples d'Usage](#exemples-dusage)
10. [Debug et Logging](#debug-et-logging)

---

## Vue d'ensemble

Le système de menu modulaire (`scene/menu/`) fournit une architecture flexible et réutilisable pour les interfaces de menu. Il divise les fonctionnalités en panneaux autonomes avec navigation fluide et sauvegarde automatique des paramètres.

### Caractéristiques principales

- **Architecture modulaire** : 3 panneaux autonomes (Main, Langues, Options)
- **Configuration centralisée** : Positions UI dans `config.lua`
- **Navigation fluide** : Callbacks pour changement de panneau
- **Sauvegarde automatique** : Paramètres dans `settings.json`
- **Système de notifications** : Feedback visuel avec fadeout
- **Assets graphiques** : Drapeaux, boutons, polices
- **Responsive design** : Adaptation automatique aux résolutions

---

## Architecture

### Structure des Fichiers

```
scene/menu/
├── menu.lua                  # Contrôleur principal (200+ lignes)
├── config.lua               # Configuration positions UI (100+ lignes)
├── resources.json           # Chemins assets (drapeaux, audio)
└── HUD/
    ├── mainMenu.lua         # Menu principal (250+ lignes)
    ├── MultiLangue.lua      # Sélection langue (420+ lignes)
    └── options.lua          # Paramètres (470+ lignes)

img/flag/
├── fr.png                   # Drapeau français
└── en.png                   # Drapeau anglais
```

### Contrôleur Principal

Le fichier `menu.lua` orchestre les panneaux :

```lua
local menu = {}
menu.name = "menu"

-- Panneaux modulaires
menu.panels = {
    main = require("scene.menu.HUD.mainMenu"),
    multilangue = require("scene.menu.HUD.MultiLangue"),
    options = require("scene.menu.HUD.options")
}

-- État actuel
menu.currentPanel = "main"  -- Panneau affiché

-- Configuration des callbacks de navigation
local function setupPanelCallbacks()
    local function switchPanel(panelName)
        menu.currentPanel = panelName or "main"
    end
    
    -- Assigner callbacks à tous les panneaux
    for _, panel in pairs(menu.panels) do
        panel.onSwitchPanel = switchPanel
        panel.onLanguageChanged = onLanguageChanged
    end
end
```

---

## Panneaux Disponibles

### 1. Menu Principal (`mainMenu.lua`)

**Responsabilités** :
- Point d'entrée principal du jeu
- Navigation vers autres panneaux et scènes
- Textes multilingues automatiques

**Boutons disponibles** :
```lua
menu.panels.main.buttons = {
    play = {
        texte = t("ui.menu.play"),  -- "Jouer" / "Play"
        action = function() 
            -- Lancer le jeu (GameStartRouter recommandé)
            scene:push("scene/gameplay/gameplay")
        end
    },
    options = {
        texte = t("ui.menu.options"),
        action = function()
            -- Basculer vers panneau options
            mainMenu.onSwitchPanel("options")
        end
    },
    multilingual = {
        texte = t("ui.options.language"),
        action = function()
            -- Basculer vers panneau langues
            mainMenu.onSwitchPanel("multilangue")
        end
    },
    credit = {
        texte = t("ui.menu.credits"),
        action = function()
            scene:push("scene/credit/credit")
        end
    },
    quit = {
        texte = t("ui.menu.quit"),
        action = function()
            love.window.close()
        end
    }
}
```

### 2. Sélection Langue (`MultiLangue.lua`)

**Responsabilités** :
- Interface graphique de sélection de langue
- Affichage des drapeaux et boutons
- Sauvegarde automatique des préférences
- Notifications de confirmation

**Fonctionnalités** :
```lua
multiLangue.buttons = {
    francais = {
        texte = "Français",
        langue = "fr",
        action = function()
            _G.localization.setLanguage('fr')
            multiLangue:saveLanguagePreference('fr')
            multiLangue:updateTexts()
            multiLangue:notifyLanguageChange()
            multiLangue:showLanguageSavedNotification('fr')
        end
    },
    english = {
        texte = "English", 
        langue = "en",
        action = function()
            _G.localization.setLanguage('en')
            -- ... même logique
        end
    },
    retour = {
        texte = t("ui.menu.back"),
        action = function()
            multiLangue.onSwitchPanel("main")
        end
    }
}
```

**Affichage graphique** :
- Drapeaux : Images 200x120px chargées depuis `img/flag/`
- Textes : Positionnés à côté des drapeaux
- Zone cliquable : Rectangle englobant drapeau + texte
- États visuels : Normal, hover (vert), click (rouge)

### 3. Panneau Options (`options.lua`)

**Responsabilités** :
- Configuration volume, plein écran, debug
- Sauvegarde automatique des paramètres
- Interface de réglage temps réel

**Paramètres disponibles** :
```lua
options.buttons = {
    volume_down = {
        texte = "Volume -",
        action = function()
            options:adjustVolume(-0.1)  -- Diminuer de 10%
            options:applyVolumeSettings()
            options:autoSave()
        end
    },
    volume_up = {
        texte = "Volume +", 
        action = function()
            options:adjustVolume(0.1)   -- Augmenter de 10%
            options:applyVolumeSettings()
            options:autoSave()
        end
    },
    fullscreen_toggle = {
        texte = t("ui.options.fullscreen") .. ": " .. (fullscreen and "ON" or "OFF"),
        action = function()
            options:toggleFullscreen()
            options:autoSave()
        end
    },
    debug_toggle = {
        texte = t("ui.options.debug") .. ": " .. (debug and "ON" or "OFF"),
        action = function()
            options:toggleDebug()
            options:autoSave()
        end
    },
    sauvegarder = {
        texte = t("ui.options.save"),
        action = function()
            options:saveSettings()
            options:showSaveNotification()
        end
    },
    retour = {
        texte = t("ui.menu.back"),
        action = function()
            options.onSwitchPanel("main")
        end
    }
}
```

---

## Configuration et Positions

### Fichier de Configuration (`config.lua`)

Toutes les positions UI sont centralisées et paramétrables :

```lua
local config = {}

function config.load()
    local gameReso = _G.screen.gameReso
    
    return {
        -- Menu Principal
        MAIN_MENU = {
            title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
            buttons = {
                play = { x = 60, y = gameReso.height / 2 + 80, width = 200, height = 60 },
                options = { x = 60, y = gameReso.height / 2 + 160, width = 200, height = 60 },
                languages = { x = 60, y = gameReso.height / 2 + 240, width = 200, height = 60 },
                credits = { x = 60, y = gameReso.height / 2 + 320, width = 200, height = 60 },
                quit = { x = 60, y = gameReso.height / 2 + 400, width = 200, height = 60 }
            }
        },
        
        -- Panneau Multilingue  
        MULTILANGUE = {
            title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
            buttons = {
                francais = {
                    clickZone = { x = 60, y = gameReso.height / 2 + 120, width = 300, height = 80 },
                    flag = { x = 60, y = gameReso.height / 2 + 160, scaleX = 0.2, scaleY = 0.15 },
                    text = { x = 60, y = gameReso.height / 2 + 130 }
                },
                english = {
                    clickZone = { x = 60, y = gameReso.height / 2 + 240, width = 300, height = 80 },
                    flag = { x = 60, y = gameReso.height / 2 + 280, scaleX = 0.2, scaleY = 0.15 },
                    text = { x = 60, y = gameReso.height / 2 + 250 }
                },
                retour = {
                    clickZone = { x = 60, y = gameReso.height / 2 + 400, width = 180, height = 60 }
                }
            }
        },
        
        -- Panneau Options
        OPTIONS = {
            title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
            buttons = {
                volume_down = { x = 60, y = gameReso.height / 2 + 80, width = 120, height = 60 },
                volume_display = { x = 200, y = gameReso.height / 2 + 80, width = 200, height = 60 },
                volume_up = { x = 420, y = gameReso.height / 2 + 80, width = 120, height = 60 },
                
                fullscreen_toggle = { x = 60, y = gameReso.height / 2 + 160, width = 300, height = 60 },
                debug_toggle = { x = 60, y = gameReso.height / 2 + 240, width = 300, height = 60 },
                
                sauvegarder = { x = 60, y = gameReso.height / 2 + 320, width = 200, height = 60 },
                retour = { x = 60, y = gameReso.height / 2 + 400, width = 180, height = 60 }
            }
        }
    }
end
```

### Adaptation Responsive

```lua
-- Les positions s'adaptent automatiquement à la résolution
local positions = config.load()  -- Recalcul selon screen.gameReso

-- Utilisation dans les panneaux
local buttonPos = positions.MAIN_MENU.buttons.play
self.buttons.play.vector2 = { x = buttonPos.x, y = buttonPos.y }
self.buttons.play.width = buttonPos.width
self.buttons.play.height = buttonPos.height
```

---

## Navigation Inter-Panneaux

### Système de Callbacks

Chaque panneau peut naviguer vers les autres via des callbacks :

```lua
-- Configuration dans menu.lua
local function setupPanelCallbacks()
    local function switchPanel(panelName)
        menu.currentPanel = panelName or "main"
    end
    
    local function onLanguageChanged()
        -- Mettre à jour tous les panneaux
        for _, panel in pairs(menu.panels) do
            if panel.updateTexts then
                panel:updateTexts()
            end
        end
    end
    
    -- Assigner à tous les panneaux
    for _, panel in pairs(menu.panels) do
        panel.onSwitchPanel = switchPanel
        panel.onLanguageChanged = onLanguageChanged
    end
end
```

### Utilisation dans les Panneaux

```lua
-- Depuis mainMenu.lua
self.buttons.options.action = function()
    if mainMenu.onSwitchPanel then
        mainMenu.onSwitchPanel("options")
    end
end

-- Depuis MultiLangue.lua  
self.buttons.retour.action = function()
    if multiLangue.onSwitchPanel then
        multiLangue.onSwitchPanel("main")
    end
end

-- Depuis options.lua
self.buttons.retour.action = function()
    if options.onSwitchPanel then
        options.onSwitchPanel("main")
    end
end
```

### Navigation Clavier

```lua
-- Support Echap pour retour rapide (dans MultiLangue et Options)
function multiLangue:handleInput()
    if love.keyboard.isDown("escape") then
        if self.onSwitchPanel then
            self.onSwitchPanel("main")
        end
        return
    end
    -- ... traitement souris
end
```

---

## Sauvegarde Automatique

### Format settings.json

```json
{
  "language": "en",
  "volume": 0.7,
  "fullscreen": false,
  "debug": true
}
```

### Système de Sauvegarde

```lua
-- Dans options.lua
function options:saveSettings()
    local settings = {
        language = _G.localization.getCurrentLanguage(),
        volume = self.settings.volume,
        fullscreen = self.settings.fullscreen,
        debug = self.settings.debug
    }
    
    -- Via saveManager si disponible
    if _G.saveManager and _G.saveManager.saveSettings then
        _G.saveManager.saveSettings(settings)
    else
        -- Fallback direct
        local success = love.filesystem.write("settings.json", _G.json.encode(settings))
        if success then
            print("Paramètres sauvegardés")
        end
    end
end

-- Sauvegarde automatique sur changement
function options:adjustVolume(delta)
    self.settings.volume = math.max(0, math.min(1, self.settings.volume + delta))
    self:updateButtonTexts()
    self:applyVolumeSettings()
    self:autoSave()  -- Sauvegarde immédiate
end

function options:autoSave()
    -- Délai pour éviter spam I/O
    if not self.saveTimer then
        self.saveTimer = 0.5  -- Sauvegarder dans 0.5s
    end
end

function options:update(dt)
    if self.saveTimer then
        self.saveTimer = self.saveTimer - dt
        if self.saveTimer <= 0 then
            self:saveSettings()
            self.saveTimer = nil
        end
    end
end
```

### Chargement au Démarrage

```lua
-- Dans options.lua
function options:loadSettings()
    local settings = {}
    
    -- Chargement depuis saveManager ou fichier direct
    if _G.saveManager and _G.saveManager.loadSettings then
        settings = _G.saveManager.loadSettings() or {}
    else
        local content = love.filesystem.read("settings.json")
        if content then
            local ok, data = pcall(_G.json.decode, content)
            if ok then settings = data end
        end
    end
    
    -- Appliquer avec fallbacks
    self.settings.volume = settings.volume or 0.8
    self.settings.fullscreen = settings.fullscreen or false
    self.settings.debug = settings.debug or false
    
    -- Appliquer immédiatement
    self:applyVolumeSettings()
    if self.settings.fullscreen then
        love.window.setFullscreen(true)
    end
end
```

---

## Système de Notifications

### Notifications Visuelles

```lua
-- Dans MultiLangue.lua
function multiLangue:showLanguageSavedNotification(language)
    self.notification = {
        text = t("system.language_saved") or "Langue sauvegardée !",
        timer = 3.0,    -- Afficher 3 secondes
        alpha = 1.0,    -- Opacité initiale
        color = {0, 1, 0}  -- Vert
    }
end

-- Dans options.lua  
function options:showSaveNotification()
    self.notification = {
        text = t("system.settings_saved") or "Paramètres sauvegardés !",
        timer = 2.5,
        alpha = 1.0,
        color = {0, 0.8, 1}  -- Bleu
    }
end
```

### Rendu des Notifications

```lua
function multiLangue:update(dt)
    -- Gestion fadeout notification
    if self.notification then
        self.notification.timer = self.notification.timer - dt
        
        -- Fadeout dernières 0.5 secondes
        if self.notification.timer <= 0.5 then
            self.notification.alpha = self.notification.timer / 0.5
        end
        
        -- Supprimer quand expirée
        if self.notification.timer <= 0 then
            self.notification = nil
        end
    end
end

function multiLangue:draw()
    -- ... rendu normal des boutons
    
    -- Notification par-dessus
    if self.notification then
        local notifW, notifH = 300, 60
        local notifX = screen.gameReso.width / 2 - notifW / 2
        local notifY = screen.gameReso.height - 120
        
        -- Fond notification avec alpha
        love.graphics.setColor(0, 0, 0, 0.7 * self.notification.alpha)
        love.graphics.rectangle("fill", notifX, notifY, notifW, notifH)
        
        -- Texte notification
        love.graphics.setColor(self.notification.color[1], 
                              self.notification.color[2], 
                              self.notification.color[3], 
                              self.notification.alpha)
        local textW = love.graphics.getFont():getWidth(self.notification.text)
        local textX = notifX + (notifW - textW) / 2
        local textY = notifY + (notifH - love.graphics.getFont():getHeight()) / 2
        love.graphics.print(self.notification.text, textX, textY)
    end
end
```

---

## Ressources et Assets

### Fichier resources.json

```json
{
  "flags": {
    "fr": "img/flag/fr.png",
    "en": "img/flag/en.png"
  },
  "fonts": {
    "title": "fonts/PANICKO.ttf",
    "button": "fonts/Cambria.ttc"
  },
  "audio": {
    "click": "audio/menu_click.wav",
    "hover": "audio/menu_hover.wav"
  }
}
```

### Chargement des Ressources

```lua
-- Dans MultiLangue.lua
function multiLangue:loadFlags()
    local resources = config.load() or {}
    
    if resources and resources.flags then
        -- Drapeaux avec gestion d'erreur
        if resources.flags.fr then
            self.flags.fr = res.image(resources.flags.fr)
        else
            print("Drapeau français non trouvé")
        end
        
        if resources.flags.en then
            self.flags.en = res.image(resources.flags.en)
        else
            print("Drapeau anglais non trouvé")
        end
    end
end
```

### Specifications Assets

**Drapeaux** :
- Format : PNG avec transparence
- Taille recommandée : 200x120px (ratio 5:3)
- Échelle dans interface : 0.2x (40x24px affiché)
- Nom fichiers : `fr.png`, `en.png`, etc.

**Polices** :
- Titre : `PANICKO.ttf` taille 80
- Boutons : `Cambria.ttc` taille 60  
- Notifications : taille 24

---

## Exemples d'Usage

### 1. Ajouter un Nouveau Panneau

```lua
-- 1. Créer le fichier scene/menu/HUD/myPanel.lua
local myPanel = {}

myPanel.buttons = {
    button1 = {
        texte = "Mon Bouton",
        action = function()
            print("Bouton cliqué !")
        end
    },
    retour = {
        texte = "Retour",
        action = function()
            if myPanel.onSwitchPanel then
                myPanel.onSwitchPanel("main")
            end
        end
    }
}

function myPanel:load()
    print("Mon panneau chargé")
end

function myPanel:updateTexts()
    self.buttons.button1.texte = t("ui.my.button")
    self.buttons.retour.texte = t("ui.menu.back")
end

return myPanel

-- 2. Ajouter dans menu.lua
menu.panels.myPanel = require("scene.menu.HUD.myPanel")

-- 3. Ajouter bouton navigation dans mainMenu.lua
myPanelButton = {
    texte = "Mon Panneau",
    action = function()
        mainMenu.onSwitchPanel("myPanel")
    end
}

-- 4. Ajouter positions dans config.lua
MY_PANEL = {
    title = { x = 60, y = gameReso.height / 2 - 150 },
    buttons = {
        button1 = { x = 60, y = gameReso.height / 2 + 80, width = 200, height = 60 }
    }
}
```

### 2. Personnaliser un Panneau Existant

```lua
-- Modifier options.lua pour ajouter un paramètre
function options:load()
    -- ... paramètres existants
    
    -- Nouveau paramètre personnalisé
    self.buttons.myOption = {
        texte = "Mon Option: " .. (self.settings.myOption and "ON" or "OFF"),
        action = function()
            self.settings.myOption = not self.settings.myOption
            self:updateButtonTexts()
            self:autoSave()
        end
    }
end
```

### 3. Intégrer un Asset Personnalisé

```lua
-- Dans resources.json
{
  "flags": {
    "fr": "img/flag/fr.png",
    "en": "img/flag/en.png",
    "es": "img/flag/es.png"  // Nouveau drapeau espagnol
  }
}

-- Dans MultiLangue.lua  
multiLangue.buttons.spanish = {
    texte = "Español",
    langue = "es",
    action = function()
        _G.localization.setLanguage('es')
        -- ... logique standard
    end
}
```

---

## Debug et Logging

### Logs Intégrés

Chaque panneau génère des logs détaillés :

```lua
-- Helper de log dans chaque panneau
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Exemples de logs
_log("[mainMenu] Panneau principal chargé")
_log("[multiLangue] Langue changée vers: fr")
_log("[options] Volume ajusté: 0.7")
_log("[menu] Changement de panneau vers: options")
```

### Debug Visuel

```lua
-- Dans menu.lua, ajouter debug overlay
function menu:draw()
    -- ... rendu normal
    
    if _G.debug or love.keyboard.isDown("f3") then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.print("Panneau actuel: " .. self.currentPanel, 10, 10)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)
        
        -- Afficher zones cliquables
        local currentPanelObj = self.panels[self.currentPanel]
        if currentPanelObj and currentPanelObj.buttons then
            love.graphics.setColor(1, 0, 0, 0.3)
            for _, button in pairs(currentPanelObj.buttons) do
                if button.vector2 and button.width and button.height then
                    love.graphics.rectangle("line", 
                        button.vector2.x, button.vector2.y, 
                        button.width, button.height)
                end
            end
        end
    end
end
```

### Validation État

```lua
-- Test d'intégrité du système
function menu:validate()
    local errors = {}
    
    -- Vérifier que tous les panneaux ont les callbacks requis
    for name, panel in pairs(self.panels) do
        if not panel.onSwitchPanel then
            table.insert(errors, "Panneau " .. name .. " manque onSwitchPanel")
        end
        if not panel.updateTexts then
            table.insert(errors, "Panneau " .. name .. " manque updateTexts")
        end
    end
    
    -- Vérifier configuration
    local config = require("scene.menu.config").load()
    if not config.MAIN_MENU then
        table.insert(errors, "Configuration MAIN_MENU manquante")
    end
    
    return #errors == 0, errors
end
```

---

## Performance et Optimisation

### Cache des Ressources

```lua
-- Les ressources sont chargées une seule fois
local resourceCache = {}

function loadCachedResource(path)
    if not resourceCache[path] then
        resourceCache[path] = res.image(path)
    end
    return resourceCache[path]
end
```

### Optimisation Rendu

```lua
-- Éviter redraw inutiles
function multiLangue:needsRedraw()
    return self.lastMouseX ~= mx or self.lastMouseY ~= my or self.notification
end

function multiLangue:draw()
    if not self:needsRedraw() and not self.forceRedraw then
        return  -- Skip rendu si pas de changement
    end
    
    -- ... rendu normal
    self.lastMouseX, self.lastMouseY = mx, my
    self.forceRedraw = false
end
```

### Métriques Typiques

- **Temps chargement** : < 100ms pour tous les panneaux
- **Mémoire** : ~2MB pour assets (drapeaux, polices)
- **Changement panneau** : < 16ms (1 frame à 60fps)
- **Sauvegarde settings** : < 5ms

---

*Dernière mise à jour : 4 septembre 2025*
