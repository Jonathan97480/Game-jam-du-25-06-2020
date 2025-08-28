# Copilot Instructions – Jeu de Cartes Tactique LÖVE2D

## Architecture du Projet
Ce projet LÖVE2D suit une architecture modulaire avec séparation claire des responsabilités :

- **`main.lua`** : Point d'entrée, initialise les modules globaux et gère le débogage
- **`my-librairie/`** : Core du framework, contient tous les managers et systèmes
- **`scene/`** : Scènes du jeu (menu, gameplay, overlays) avec lifecycle standard
- **`ressources/`** : Données de configuration (cartes, effets, IA)
- **`test/`** : Tests unitaires avec mocks LÖVE2D intégrés

## Patterns de Code Critiques

### 1. Système de Globales Centralisé
**NOUVEAU** : Toutes les globales sont définies dans `my-librairie/globals.lua` :
```lua
-- main.lua (UNIQUEMENT)
local globals = require("my-librairie/globals")

-- Tous les autres fichiers
local Card = _G.Card
local scene = _G.scene
local hud = _G.hud
```

**ANCIEN** (à éviter) : `rawget(_G, "nom")` dispersé partout

### 2. Système de Require Robuste
Pour les modules non-globaux, utiliser `_safeRequire` :
```lua
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end
```

### 2. Scene Manager avec Stack
- Les scènes supportent les méthodes : `load`, `enter`, `update`, `draw`, `leave`, `unload`, `resume`
- Mode stack (`stackMode=true`) : seule la scène au sommet reçoit les events
- Usage : `scene:push("scene.menu.menu")`, `scene:pop()`

### 3. Système de Cartes Façade
`Card` expose une API unifiée qui délègue aux sous-modules :
- `Card.hand`, `Card.deck`, `Card.graveyard` : états principaux
- Génération : `Card.loadCards()`
- Tirage : `Card.tirage(n)`

### 4. HUD Système Modulaire & Responsive
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
-- Éléments simples
hud.addIcon(id, layer, position, texture, opts)
hud.addLabel(id, layer, position, text, font, color)
hud.addBar(id, layer, position, w, h, color, progress)

-- Interactions
hud.addButton(id, layer, position, w, h, callback, opts)
hud.setButtonCallback(id, callback)

-- Panels & Layout
hud.setPanel(id, position, w, h, bg, children)
hud.addChild(parentId, childElement)

-- Gestion états
hud.setVisible(id, visible)
hud.setValue(id, value)
hud.animateProgress(id, targetProgress, duration)
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
- **Données** → `ressources/` (cartes, effets, config IA)
- **Tests** → `test/` (avec suffix `_test.lua`)
- **Assets** → `img/`, `fonts/`

### Patterns de Require
- **Globales** : Utiliser `_G.nom` directement (définies dans `my-librairie/globals.lua`)
- **Modules locaux** : Préférer slash `/` : `require("my-librairie/sceneManager")`
- **Legacy** : Fallback automatique point/slash dans `sceneManager`
- **ÉVITER** : `rawget(_G, "nom")` - utiliser le système centralisé

### Patterns HUD Modulaires
- **Composants** : `require("my-librairie.hud.button.button").new(...)` pour instances
- **Manager** : `_G.hud` pour API globale (add/set/get functions)
- **Couches** : Utiliser constantes `"background"/"decor"/"props"/"card"/"button"`
- **Draw Safe** : `require("my-librairie.hud.draw")` pour wrapper LÖVE2D testable
- **Responsive** : Positions automatiquement adaptées via `responsive.lua`

## Points d'Intégration Clés

1. **Scene Lifecycle** : Toute nouvelle scène doit implémenter les méthodes standard
2. **Card Effects** : Centralisation dans `card-librairie/effects/`
3. **Actor System** : `actorManager.lua` pour gestion entités de combat
4. **HUD Architecture** : Système en couches avec composants modulaires
   - **Couches** : Respect de l'ordre background→decor→props→card→button
   - **Responsive** : Utilise `my-librairie/responsive.lua` pour adaptation automatique
   - **Composants** : Button/Panel/Text réutilisables avec API consistante
   - **Integration** : `hud.update(dt)` et `hud.draw()` dans scene lifecycle
5. **Responsive Global** : `my-librairie/responsive.lua` pour adaptation écrans
6. **Input Unifié** : `inputManager.lua` unifie souris/gamepad

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
