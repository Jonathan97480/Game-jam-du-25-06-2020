# Système de Globales Centralisé

## Problème Résolu

Avant cette migration, les globales étaient déclarées de manière dispersée :
- Déclarations sauvages dans `main.lua`
- `rawget(_G, "nom")` partout dans le code
- Chargements redondants avec fallbacks complexes
- Difficile de savoir quelles globales existent

## Solution : `my-librairie/globals.lua`

Un seul fichier centralise **toutes** les globales du projet :

```lua
-- Dans main.lua (UNIQUEMENT)
local globals = require("my-librairie/globals")

-- Dans tous les autres fichiers
local Card = _G.Card
local scene = _G.scene  
local hud = _G.hud
-- etc.
```

## Globales Disponibles

### Modules Core (toujours chargés)
- `_G.json` - Librairie JSON
- `_G.hud` - Système HUD
- `_G.Card` - API façade des cartes  
- `_G.screen` - Responsive manager
- `_G.scene` - Scene manager
- `_G.effect` - Système d'effets
- `_G.Transition` - Manager de transitions

### Modules Optionnels (avec fallback nil)
- `_G.inputManager` - Gestion unified input
- `_G.actorManager` - Gestion entités combat
- `_G.globalFunction` - Utilitaires legacy
- `_G.myFunction` - Alias de globalFunction
- `_G.myFonction` - Alias typo legacy

### Scripts Actors (chargés à la demande)
- `_G.Hero` - Script joueur
- `_G.Enemies` - Scripts ennemis

### Configuration
- `_G.GameFlags` - Flags d'état du jeu
- `_G.HUD_BOTTOM_BG_PATH` - Chemin assets HUD

## Migration des Fichiers Existants

### Avant (dispersé)
```lua
local Card = rawget(_G, "Card") or rawget(_G, "card") 
local Hero = rawget(_G, "Hero")
local scene = rawget(_G, "scene") or require("my-librairie/sceneManager")
```

### Après (centralisé)
```lua
local Card = _G.Card
local Hero = _G.Hero  
local scene = _G.scene
```

### Script de Migration Automatique

Utilisez `my-librairie/migration_cleanup.lua` pour migrer automatiquement :

```bash
lua my-librairie/migration_cleanup.lua
```

## Avantages

1. **Visibilité** : Une seule source de vérité pour toutes les globales
2. **Maintenabilité** : Modifications centralisées
3. **Performance** : Plus de `rawget()` répétés
4. **Lisibilité** : Code plus propre sans fallbacks complexes
5. **Débogage** : `globals.status()` pour diagnostics

## API de Diagnostic

```lua
local globals = require("my-librairie/globals")

-- Lister toutes les globales définies
print(table.concat(globals.list(), ", "))

-- Vérifier l'état de chargement
local status = globals.status()
for name, info in pairs(status) do
    print(name .. ": " .. (info.loaded and "✓" or "✗"))
end

-- Accès sécurisé (legacy)
local Card = globals.get("Card")
```

## Règles de Migration

1. **main.lua** : Charge `globals.lua` en premier
2. **Autres fichiers** : Utilisent `_G.nom` directement  
3. **Pas de nouveaux rawget** : Ajoutez dans `globals.lua`
4. **Tests** : Vérifiez `globals.status()` avant les tests

## Fichiers Impactés

- ✅ `main.lua` - Migration complète
- ✅ `scene/menu/menu.lua` - Migration exemple  
- 🔄 `my-librairie/ai/controller.lua` - En cours
- 🔄 `scene/overlay_start/overlay_start.lua` - À migrer
- 🔄 `scene/gameplay/HUD/hud_gameplay.lua` - À migrer  
- 🔄 Plus de 15 autres fichiers...

## Notes Techniques

- Les globales sont chargées **une seule fois** au démarrage
- Les modules optionnels peuvent être `nil` (vérifiez avant usage)
- Compatible avec le système de tests existant
- Fallback gracieux si `globals.lua` n'est pas chargé
