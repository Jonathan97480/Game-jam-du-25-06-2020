# Copilot Instructions – Jeu de Cartes Tactique LÖVE2D

## Architecture du Projet MISE À JOUR (03/09/2025)
Ce projet LÖVE2D suit une architecture modulaire complète avec système multilingue et menus modulaires :

- **`main.lua`** : Point d'entrée, initialise les modules globaux et gère le débogage
- **`my-librairie/`** : Core du framework, contient tous les managers et systèmes
- **`scene/`** : Scènes du jeu (menu modulaire, gameplay, overlays) avec lifecycle standard
- **`localization/`** : Système multilingue FR/EN complet avec fichiers JSON
- **`ressources/`** : Données de configuration (cartes, effets, IA)
- **`test/`** : Tests unitaires avec mocks LÖVE2D intégrés

### Structure my-librairie/ Réorganisée :
```
my-librairie/
├── config.lua                   # Configuration générale du jeu
├── inputInterface.lua            # Interface input unifiée (souris/clavier) 
├── inputManager.lua              # Gestionnaire input avancé (gamepad)
├── love_stubs.lua               # Stubs LÖVE2D pour tests
├── core/                        # Modules centraux
│   └── globals.lua              # Système de globales centralisé + alias localisation
├── utils/                       # Utilitaires généraux
│   ├── globalFunction.lua       # Fonctions utilitaires globales
│   └── responsive.lua           # Adaptation écrans/résolutions
├── tools/                       # Outils autonomes
│   └── json.lua                 # Parser JSON intégré
├── managers/                    # Gestionnaires de ressources
│   └── resource_cache.lua       # Cache images/fonts optimisé
├── entities/                    # Scripts d'entités (anciennement ActorScripts/)
├── ai/                          # IA controller et stratégies
│   ├── controller.lua           # Contrôleur IA principal  
│   └── card_selection_strategy.lua
├── card-librairie/              # Système de cartes complet
│   ├── cardStandbyPlay.lua      # Système standby copie/invisible
│   ├── card.lua                 # API unifiée cartes
│   ├── core/                    # Modules de base
│   ├── effects/                 # Effets de cartes
│   ├── play/                    # Animations et rendu
│   └── ui/                      # Interface utilisateur
├── hud/                         # Système HUD modulaire
│   ├── hud.lua                  # Gestionnaire principal 5 couches
│   ├── button/                  # Composants boutons
│   ├── panel/                   # Composants panels
│   └── text/                    # Composants texte
├── localization-system/         # Système multilingue COMPLET (NOUVEAU)
│   ├── localizationManager.lua  # Gestionnaire principal FR/EN
│   ├── textFormatter.lua        # Formatage avec variables {damage}
│   └── textLoader.lua           # Chargement fichiers JSON
└── transitions/                 # Système de transitions
    ├── transitionManager.lua    # Gestionnaire principal
    ├── templateCombatTransition.lua
    └── focus.lua
```

### Fichiers Supprimés (Ne plus créer) :
❌ **my-librairie/transitionManager.lua** → Déplacé vers `transitions/`
❌ **my-librairie/ActorScripts/** → Déplacé vers `entities/`
❌ **my-librairie/globalFunction.lua** → Déplacé vers `utils/`
❌ **my-librairie/responsive.lua** → Déplacé vers `utils/`
❌ **test_*.lua** → Fichiers tests temporaires
❌ **overlay_initiative_*.lua** → Versions dupliquées
❌ **controller_modern.lua** → Version obsolète
❌ **card-libraarie/** → Typo dans nom (double 'a')

### Nouveautés Majeures :
🆕 **Système Multilingue Complet** : `my-librairie/localization-system/`
🆕 **Menu Modulaire** : `scene/menu/HUD/` avec 3 panneaux
🆕 **Configuration Centralisée** : `scene/menu/config.lua` positions UI
🆕 **Notifications Système** : Sauvegardes et changements langue
🆕 **Drapeaux Graphiques** : `img/flag/` pour sélection visuelle

## Patterns de Code Critiques

### 1. Système de Globales Centralisé
**NOUVEAU** : Toutes les globales sont définies dans `my-librairie/core/globals.lua` :
```lua
-- main.lua (UNIQUEMENT)
local globals = require("my-librairie/core/globals")

-- Tous les autres fichiers
local Card = _G.Card
local scene = _G.scene
local hud = _G.hud
local localizationManager = _G.localizationManager
local t = _G.t  -- Fonction de traduction
```

**ANCIEN** (à éviter) : `rawget(_G, "nom")` dispersé partout

### 2. Système de Localisation Multilingue COMPLET
**NOUVEAU** : Système multilingue FR/EN avec `LocalizationManager` :
```lua
-- Configuration et initialisation (my-librairie/core/globals.lua)
local localizationManager = _G.localizationManager
local success = localizationManager.initialize()

-- Alias global pour traduction rapide
_G.t = function(key, variables)
    return localizationManager.t(key, variables)
end

-- Alias compatibilité pour menus
_G.localization = {
    get = function(key, variables) return _G.t(key, variables) end,
    setLanguage = function(lang) return localizationManager.setLanguage(lang) end,
    getCurrentLanguage = function() return localizationManager.getCurrentLanguage() end
}
```

**Utilisation dans le code** :
```lua
-- Traduction simple
local text = _G.t("ui.menu.play")  -- "Jouer" ou "Play"

-- Traduction avec variables
local damage = _G.t("cards.descriptions.carte_001", {damage = 5})

-- Dans les menus (compatibilité)
self.buttons.play.texte = _G.localization.get("ui.menu.play") or "Jouer"
```

### 3. Menu Modulaire COMPLET
**Architecture** : Menu divisé en 3 panneaux autonomes dans `scene/menu/HUD/` :
- **`mainMenu.lua`** : Menu principal (5 boutons : Play, Options, Langues, Crédits, Quitter)
- **`MultiLangue.lua`** : Sélection de langue avec drapeaux et sauvegarde automatique
- **`options.lua`** : Paramètres (volume, plein écran, debug) avec sauvegarde automatique

**Navigation** :
```lua
-- Changer de panneau depuis n'importe quel panneau
if self.onSwitchPanel then
    self.onSwitchPanel("options")     -- Vers options
    self.onSwitchPanel("multilangue") -- Vers langues
    self.onSwitchPanel("main")        -- Vers menu principal
end
```

**Configuration Centralisée** : `scene/menu/config.lua`
```lua
-- Positions UI configurables pour tous les panneaux
MAIN_MENU = {
    buttons = {
        play = { x = 60, y = 400, width = 200, height = 60 },
        options = { x = 60, y = 480, width = 200, height = 60 }
    }
},
MULTILANGUE = {
    buttons = {
        francais = { 
            clickZone = { x = 60, y = 400, width = 300, height = 80 },
            flag = { x = 60, y = 440, scaleX = 0.2, scaleY = 0.15 }
        }
    }
}
```

### 4. Système de Sauvegarde et Notifications
**Sauvegarde JSON automatique** :
```lua
-- Sauvegarde settings.json automatique
function saveSettings()
    local settings = {
        language = currentLanguage,
        volume = volumeLevel,
        fullscreen = isFullscreen,
        debug = debugMode
    }
    local success = love.filesystem.write("settings.json", _G.json.encode(settings))
end

-- Chargement au démarrage
function loadSettings()
    local content = love.filesystem.read("settings.json")
    if content then
        local settings = _G.json.decode(content)
        -- Appliquer les paramètres...
    end
end
```

**Notifications visuelles** :
```lua
-- Afficher notification temporaire
function showNotification(text, color)
    self.notification = {
        text = text,
        timer = 3.0,     -- 3 secondes
        alpha = 1.0,
        color = color or {0, 1, 0}  -- Vert par défaut
    }
end

-- Dans update() : gérer fadeout
if self.notification then
    self.notification.timer = self.notification.timer - dt
    if self.notification.timer <= 0.5 then
        self.notification.alpha = self.notification.timer / 0.5
    end
    if self.notification.timer <= 0 then
        self.notification = nil
    end
end
```

### 5. Système de Require Robuste
Pour les modules non-globaux, utiliser `_safeRequire` :
```lua
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end
```

### 6. SceneManager - Navigation avec Pile
**Documentation complète** : Voir `docs/SceneManager_Documentation.md`

Le système SceneManager (`my-librairie/sceneManager.lua`) gère la navigation avec une pile de scènes :
- **API** : `scene:push()`, `scene:pop()`, `scene:switch()`
- **Lifecycle** : `load`, `enter`, `update`, `draw`, `pause`, `resume`, `leave`, `unload`
- **Modes** : `stackMode=false` (broadcast) / `stackMode=true` (top-only)
- **Events** : Dispatch automatique des événements LÖVE2D vers les scènes

### 7. Système de Cartes Façade & Standby
`Card` expose une API unifiée qui délègue aux sous-modules :
- `Card.hand`, `Card.deck`, `Card.graveyard` : états principaux
- Génération : `Card.loadCards()`
- Tirage : `Card.tirage(n)`

**CardStandbyPlay** (`card-librairie/cardStandbyPlay.lua`) : Système révolutionnaire copie/invisible
- **Pattern copie/invisible** : Carte originale reste en main (invisible), copie affichée en position standby
- **Protection anti-repositionnement** : Évite les conflits avec le système LERP de `interaction.lua`
- **API** : `putCardInStandby()`, `getStandbyCopy()`, `cancelStandby()`, `playStandbyCard()`
- **Intégration** : Se coordonne avec `CardTargetSelection` pour ciblage ennemi
- **Rendu** : `anim.lua` filtre les cartes invisibles et affiche les copies standby

### 8. HUD Système Modulaire & Responsive
Le système HUD (`my-librairie/hud/`) offre une architecture en couches avec composants réutilisables.

**Gestionnaire Principal** : `hud.lua` (1259+ lignes)
- **5 couches de rendu** : `background` → `decor` → `props` → `card` → `button`
- **API unifiée** : 20+ fonctions add/set/get pour tous types d'éléments
- **Responsive intégré** : Adaptation automatique aux résolutions
- **Cache de ressources** : Optimisation chargement fonts/images

**Composants Disponibles** :
- **Button** (`button/button.lua`) : Boutons cliquables avec états hover/click
- **Panel** (`panel/panel.lua`) : Conteneurs avec enfants et couleurs de fond
- **Text** (`text/text.lua`) : Texte avec fonts variables et couleurs
- **Slider/Checkbox** : Composants d'interface avancés
- **Draw** (`draw.lua`) : Wrapper LÖVE2D sécurisé pour tests/mocks

**API Principale** :
```lua
-- Éléments simples avec opts table structure
hud.addIcon(id, {layer = "background", x = 100, y = 50, texture = "icon.png"})
hud.addLabel(id, {layer = "props", x = 200, y = 100, text = "Score:", font = 20, color = {1,1,1}})
hud.addBar(id, {layer = "props", x = 50, y = 150, w = 200, h = 20, color = {0,1,0}, progress = 0.7})

-- Interactions avec callbacks
hud.addButton(id, {layer = "button", x = 300, y = 200, w = 100, h = 40, callback = function() end})
hud.setButtonCallback(id, callback)

-- Panels & Layout avec enfants
hud.setPanel(id, {x = 100, y = 100, w = 300, h = 200, bg = {0,0,0,0.8}, children = {}})
hud.addChild(parentId, childElement)

-- Gestion états et animations
hud.setVisible(id, visible)
hud.setValue(id, value)
hud.animateProgress(id, targetProgress, duration)

-- Rendu centralisé (UNIQUEMENT dans main.lua)
function love.draw()
    -- Rendu des scènes d'abord
    scene:draw()
    
    -- Puis rendu HUD centralisé
    if _G.hud and type(_G.hud.draw) == 'function' then
        _G.hud.draw()
    end
end
```

## Workflow de Développement

### Lancement & Debug
```powershell
# Lancement standard
love .

# Debug avec VS Code (breakpoints)
# Utilise la task "Debug LÖVE2D (debulove)" ou F5
```

### Tests
Tous les tests incluent des mocks LÖVE2D intégrés. Exécuter depuis la racine :
```lua
lua test/nom_du_test.lua
```

### Logging
- Runtime : `globalFunction.log` (F12 pour affichage)
- Export : logs sauvés dans `gameLogs/` à la fermeture
- Debug HUD : `hud.HUD_DEBUG_ENERGY = true`

## Conventions de Fichiers

### Structure Obligatoire
- **Scripts de logique** → `my-librairie/` (ex: `card-librairie/`, `ai/`, `hud/`)
- **Scènes** → `scene/` (avec sous-dossier `HUD/` si nécessaire)
- **Localization** → `localization/` (fichiers JSON FR/EN)
- **Données** → `ressources/` (cartes, effets, config IA)
- **Tests** → `test/` (avec suffix `_test.lua`)
- **Assets** → `img/`, `fonts/`

### Patterns de Require
- **Globales** : Utiliser `_G.nom` directement (définies dans `my-librairie/core/globals.lua`)
- **Modules locaux** : Préférer slash `/` : `require("my-librairie/sceneManager")`
- **Legacy** : Fallback automatique point/slash dans `sceneManager`
- **ÉVITER** : `rawget(_G, "nom")` - utiliser le système centralisé

### Patterns HUD Centralisé
- **Rendu Unique** : `hud.draw()` appelé UNIQUEMENT dans `main.lua`, jamais dans les scènes
- **API Opts** : Toutes les fonctions HUD utilisent maintenant une table `opts` : `hud.addIcon(id, {layer, x, y, texture})`
- **Composants** : `require("my-librairie.hud.button.button").new(...)` pour instances
- **Manager** : `_G.hud` pour API globale (add/set/get functions)
- **Couches** : Utiliser constantes `"background"/"decor"/"props"/"card"/"button"`
- **Smart Clear** : HUD vidé automatiquement quand pile de scènes vide (plus de duplication)
- **Protection** : Coordination de protection contre les erreurs de rendu multi-scènes
- **Draw Safe** : `require("my-librairie.hud.draw")` pour wrapper LÖVE2D testable
- **Responsive** : Positions automatiquement adaptées via `responsive.lua`

### Patterns SceneManager
**Documentation complète** : Voir `docs/SceneManager_Documentation.md`
- **Structure** : Toujours définir `{ name = "scene_name" }` en premier
- **Lifecycle** : Implémenter `load`, `enter`, `update`, `draw`, `leave`, `unload`
- **Navigation** : `scene:push()` pour overlays, `scene:switch()` pour changement complet
- **Debug** : `scene.debug = true` pour logs détaillés
- **Error handling** : Toutes les méthodes de scène doivent gérer les erreurs gracieusement

## Points d'Intégration Clés

1. **SceneManager Architecture** : Système central de navigation avec pile et lifecycle
   - **Documentation complète** : Voir `docs/SceneManager_Documentation.md`
   - **Stack Management** : `push/pop/switch` pour navigation et overlays
   - **Lifecycle Hooks** : `load→enter→update/draw→pause/resume→leave→unload`
   - **Event Dispatching** : Propagation automatique des events LÖVE2D
   - **Debug Integration** : Logs détaillés dans `gameLogs/`

2. **Scene Lifecycle** : Toute nouvelle scène doit implémenter les méthodes standard
3. **Card Effects** : Centralisation dans `card-librairie/effects/`
4. **Actor System** : `actorManager.lua` pour gestion entités de combat
5. **HUD Architecture Centralisée** : Système unifiée avec rendu centralisé dans `main.lua`
   - **Rendu Centralisé** : `hud.draw()` appelé UNIQUEMENT dans `main.lua` après le rendu des scènes
   - **Couches** : Respect de l'ordre background→decor→props→card→button (5 couches)
   - **API Unifiée** : 20+ fonctions (addIcon, addLabel, addBar, addButton, setPanel, etc.)
   - **Responsive** : Adaptation automatique via `my-librairie/responsive.lua` 
   - **Composants** : Button/Panel/Text réutilisables avec opts table structure
   - **Smart Clearing** : HUD vidé automatiquement quand la pile de scènes devient vide
   - **Error Prevention** : Protection contre conflits de rendu multi-scènes
   - **Overlays Support** : Gestion intelligente des overlays sans duplication HUD
6. **Transitions System** : `my-librairie/transitions/` pour effets visuels
   - **TransitionManager** : Gestionnaire principal des transitions entre scènes
   - **Combat Transitions** : Templates spécialisés pour combats
   - **Focus Effects** : Effets de mise en avant et zoom
7. **Responsive Global** : `my-librairie/responsive.lua` pour adaptation écrans
8. **Input Unifié** : `inputManager.lua` unifie souris/gamepad

## Utilitaires GlobalFunction (Éviter les Duplications)

**Accès** : `_G.globalFunction` (ou `_G.myFunction`, `_G.myFonction`)

### Animation & Math
- `globalFunction.lerp(a, b, speed)` : Interpolation stable avec anti-jitter
- `globalFunction.lerpNum(a, b, t)` : Interpolation pour nombres simples
- `globalFunction.clamp(val, min, max)` : Force valeur dans intervalle
- `globalFunction.clampDt(dt)` : Protège contre dt nil et limite les gros sauts temporels (>0.05s)
- `globalFunction.mapRange(val, inMin, inMax, outMin, outMax)` : Conversion d'échelle
- `globalFunction.progress(current, max)` : Ratio sécurisé (évite /0)
- `globalFunction.distSqr(x1, y1, x2, y2)` : Distance² pour comparaisons
- `globalFunction.clone(table)` : Deep copy sécurisé de tables

### Table & Data Manipulation
- `globalFunction.contains(tbl, value)` : Vérifie présence dans table
- `globalFunction.indexOf(tbl, value)` : Index d'une valeur
- `globalFunction.filter(tbl, predicate)` : Filtre avec condition
- `globalFunction.map(tbl, transform)` : Transforme tous les éléments

### String Processing
- `globalFunction.split(str, delimiter)` : Découpe chaîne
- `globalFunction.trim(str)` : Supprime espaces début/fin
- `globalFunction.pad(str, length, char, right)` : Complète avec caractères

### Validation & Safety
- `globalFunction.isNumber(val)` : Vérifie nombre valide (pas NaN)
- `globalFunction.hasFields(tbl, fields)` : Vérifie champs requis
- `globalFunction.default(val, defaultVal)` : Valeur par défaut si nil

### Input Handling  
- `globalFunction.mouse.hover(x, y, w, h, scale)` : Détection survol robuste
- `globalFunction.mouse.click()` : Front-edge click (true uniquement au premier clic)
- `globalFunction.mouse.state()` : États "pressed"/"held"/"released"/"idle"
- `globalFunction.endTurnHotkeys()` : Raccourcis E/Return/Space pour fin de tour

### Logging Centralisé
- `globalFunction.log.info/warn/error(text)` : Logs colorés avec stack trace
- `globalFunction.drawLogs()` : Affichage overlay logs (F12)
- `globalFunction.log.toggle()` : Active/désactive l'affichage
- `globalFunction.log.exportToFile()` : Export automatique vers `gameLogs/`

### Rendu Spécialisé
- `globalFunction.drawLifeBarStatus(actor, "red"|"bleu")` : Barres de vie avec bonus
- Icônes bonus automatiques : shield, épines, bonus d'attaque

### Utilities
- `globalFunction.safecall(fn, ...)` : Appel sécurisé avec log d'erreur
- `globalFunction.tstr(table)` : Debug rapide pour afficher contenu table

**Pattern d'usage** :
```lua
local gf = _G.globalFunction
if gf and gf.log then gf.log.info("Message") end
```

## Débogage Spécialisé
- **lldebugger** : Intégré, activé via `vsc_debug` argument
- **Scene debugging** : Logs stack dans `gameLogs/scene_list.log`
- **HUD debugging** : Traces énergie/santé avec flag dédié

## MISE À JOUR : Vision d'architecture et comportement Standby (03/09/2025)
Cette section synthétise les décisions récentes prises lors de la refactorisation :

- **Système Multilingue Complet** :
    - LocalizationManager (`my-librairie/localization-system/localizationManager.lua`) : Gestionnaire principal FR/EN avec cache intelligent
    - Fichiers JSON (`localization/fr.json`, `localization/en.json`) : Structure complète avec meta, ui, cards, system
    - Alias globaux : `_G.t()` pour traduction rapide, `_G.localization` pour compatibilité menu
    - Initialisation centralisée dans `my-librairie/core/globals.lua`
    - Fallback automatique français si traduction manquante
    - Variables dans traductions : `{damage}`, `{level}`, etc.

- **Menu Modulaire Architecture** :
    - `scene/menu/HUD/mainMenu.lua` : Menu principal avec 5 boutons (248 lignes)
    - `scene/menu/HUD/MultiLangue.lua` : Sélection langue + drapeaux + sauvegarde (420+ lignes)
    - `scene/menu/HUD/options.lua` : Paramètres volume/écran/debug + sauvegarde automatique (470+ lignes)
    - `scene/menu/config.lua` : Configuration centralisée positions UI pour tous panneaux
    - `scene/menu/menu.lua` : Contrôleur principal avec callbacks navigation
    - `scene/menu/resources.json` : Chemins assets (drapeaux, audio)

- **Sauvegarde et Notifications** :
    - Système `settings.json` pour persistance (langue, volume, fullscreen, debug)
    - Notifications visuelles avec timer 3s et fadeout dernières 0.5s
    - Sauvegarde automatique : changement langue immédiat, volume en temps réel
    - Chargement au démarrage avec fallbacks sécurisés

- Standby / CardStandbyPlay :
    - Quand le joueur joue une carte, l'originale reste dans la main en mode "invisible" et une copie visible est placée en position de standby (généralement à gauche).
    - Le joueur sélectionne une cible en interagissant avec la copie standby ; lors de la confirmation, la copie est détruite et l'originale (invisible) est **confirmée** pour exécution (envoyée au cimetière via le système de cartes).
    - API principale exposée : `putCardInStandby(card, index)`, `getStandbyCopy()`, `hasCardInStandby()`, `returnCardToHand()`, `confirmCardPlay()`.
    - Le système doit coordonner `CardStandbyPlay`, `CardTargetSelection`, `CardManager` et `Card.Play.tryPlay` pour garantir absence de désynchronisation d'état.

- Emplacement des modules et conventions récentes :
    - `my-librairie/core/globals.lua` : point unique d'initialisation des globals (requêté depuis `main.lua`).
    - `my-librairie/utils/` : bibliothèque d'utilitaires (ex : `globalFunction.lua`, `responsive.lua`).
    - `my-librairie/tools/` : utilitaires autonomes (ex : `json.lua`).
    - `my-librairie/entities/` : contient les scripts d'acteurs (anciennement `ActorScripts/`) — respecter le nouveau namespace lors des `require`.
    - `inputInterface` est la source d'input canonique (remplace l'ancien `core/cursor`), `inputManager` reste optionnel.

- Recommandations opérationnelles :
    - Toujours vérifier `CardStandbyPlay.hasCardInStandby()` avant d'agir sur la standby.
    - Lors de changements de nom/deplacement, privilégier `pcall(require, ...)` et exposer la valeur via `_G` depuis `globals.lua`.
    - Ajouter des assertions/logs au niveau de `CardTargetSelection` et `CardStandbyPlay` pour détecter désyncs (ex : `card.selectedTarget` vs `CardTargetSelection.selectedTarget`).
    - Utiliser `_G.t(key, variables)` pour traductions avec variables, `_G.localization.get()` pour compatibilité menus.
    - Configurer positions UI via `scene/menu/config.lua` plutôt que hard-code dans panneaux.

Cette mise à jour formalise la vision actuelle et doit être synchronisée avec le code (références dans `my-librairie/card-librairie/cardStandbyPlay.lua`, `my-librairie/card-librairie/ui/card_target_selection.lua`, et `my-librairie/core/globals.lua`).
