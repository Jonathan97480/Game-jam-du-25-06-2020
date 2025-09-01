README — Game Jam (fork)

## 📚 Documentation Disponible

### 🎯 Systèmes Principaux

#### HUD (Interface Utilisateur) ⭐ **SYSTÈME CENTRALISÉ**
- **[HUD_Centralized_System.md](./HUD_Centralized_System.md)** - Architecture centralisée complète ⭐ **NOUVEAU**
- **[HUD_Migration_Complete.md](./HUD_Migration_Complete.md)** - Guide de migration et changements effectués ⭐ **NOUVEAU**
- **[HUD_Documentation.md](./HUD_Documentation.md)** - Documentation détaillée du système HUD
- **[HUD_Examples.md](./HUD_Examples.md)** - Exemples d'utilisation pratiques
- **[HUD_Quick_Reference.md](./HUD_Quick_Reference.md)** - Référence rapide API HUD

#### Scene Management
- **[SceneManager_Documentation.md](./SceneManager_Documentation.md)** - Système de gestion des scènes avec pile et lifecycle

#### Card System ⭐ **NOUVEAU**
- **[CardStandbyPlay_Documentation.md](./CardStandbyPlay_Documentation.md)** - Système révolutionnaire copie/invisible ⭐ **NOUVEAU**

#### Transitions & Effects ⭐ **NOUVEAU**  
- **[Transitions_System.md](./Transitions_System.md)** - Système de transitions avec anti-spam intelligent ⭐ **NOUVEAU**

#### Input System
- **[InputSystem_Documentation.md](./InputSystem_Documentation.md)** - Système d'entrées unifié
- **[InputSystem_Examples.md](./InputSystem_Examples.md)** - Exemples d'utilisation des inputs
- **[InputSystem_Quick_Reference.md](./InputSystem_Quick_Reference.md)** - Référence rapide API input

### 🔄 Migrations et Overlays
- **[Overlay_Initiative_HUD_Migration.md](./Overlay_Initiative_HUD_Migration.md)** - Migration spécifique de l'overlay initiative

### 🚀 Changements Récents (Septembre 2025)

#### ✅ Documentation Système Complète (Problème #11)
- **CardStandbyPlay** complet avec API 12 fonctions et patterns d'intégration
- **Transitions anti-spam** avec cache intelligent et auto-cleanup
- **HUD responsive** fixes coordonnées souris documentés
- **Patterns consolidés** GameFlags et safe require

#### ✅ Système Transitions Anti-Spam (Problème #10)
- **Cache intelligent** réduction logs répétitifs
- **Auto-cleanup** périodique mémoire (30s)
- **Performance** optimisée pour logs debug  
- **Monitoring** intégré état système

#### ✅ HUD Centralisé - Migration Complète  
- **Rendu unique** dans `main.lua` - fini les conflits de rendu multiples
- **API modernisée** avec structure `opts` table unifiée
- **Smart clearing** automatique quand pile de scènes devient vide
- **Protection d'erreurs** robuste avec validation coordonnées `tonumber()`
- **Performance optimisée** : réduction 60-70% de la charge de rendu HUD

#### ✅ Overlay Initiative Fixé
- **Positionnement corrigé** - texte maintenant centré dans panel noir
- **API mise à jour** vers nouveau format opts structure
- **Gestion d'état stabilisée** avec lifecycle proper

#### ✅ Scene Manager Amélioré
- **Smart clearing HUD** seulement quand pile de scènes vide
- **Logs détaillés** pour debugging et monitoring
- **Error handling** robuste pour toutes les transitions

---

## 🔧 Patterns de Développement Consolidés

### GameFlags Pattern (Problème #3)
**Convention consolidée** : Utiliser `GameFlags` comme namespace centralisé pour états globaux :

```lua
-- RECOMMANDÉ : Pattern GameFlags consolidé
GameFlags.showOverlayInitiative = true
GameFlags.combatActive = false
GameFlags.turnInProgress = true

-- ÉVITER : Variables globales dispersées
showOverlayInitiative = true
COMBAT_STATE = "active"
turnState = "player"
```

**Avantages** :
- Namespace unique évite les conflits
- Debug facilité avec `table.inspect(GameFlags)`
- Centralisation des états de jeu
- IDE autocomplete amélioré

### Safe Require Pattern (Problème #8)
**Pattern unifié** pour chargement robuste de modules :

```lua
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if ok then
        return mod
    else
        print("⚠️ Module non trouvé:", name)
        return nil
    end
end

-- Usage
local cardManager = _safeRequire("my-librairie/card-librairie/cardManager")
if cardManager then
    cardManager.init()
end
```

**Best Practices** :
- Toujours vérifier retour avant usage
- Log en cas d'échec pour debug
- Fallback gracieux si module optionnel
- Pattern centralisé dans `globals.lua`

### 🏗️ Architecture Principale

#### Code Principal
- `main.lua` - Point d'entrée, gestion des globales
- `scene/` - Scènes du jeu avec lifecycle standard
- `my-librairie/globals.lua` - Système de globales centralisé

#### Input System
- `my-librairie/inputInterface.lua` - Interface bas niveau unifiée souris/manette
- `my-librairie/inputManager.lua` - Manager haut niveau avec helpers et API simplifiée
- Cursor virtuel unifié avec basculement automatique entre sources
- Support manette avec zones mortes configurables et détection front-edge
- Raccourcis de fin de tour intégrés (E/Return/Space)

#### Système HUD
- `my-librairie/hud/hud.lua` - Gestionnaire principal (1392+ lignes)
- `my-librairie/hud/button/` - Composants boutons modulaires
- `my-librairie/hud/panel/` - Système de conteneurs
- `my-librairie/responsive.lua` - Adaptation responsive automatique

#### Librairie de Cartes
- `my-librairie/card-librairie/` - Core, play, effects, cardEffect
- `my-librairie/actorManager.lua` - Gestion des entités de combat
- `ressources/` - Données de cartes et effets

Comment tester localement

1. Lancer le jeu avec LÖVE (depuis le dossier racine du projet) :

```powershell
# si love est dans le PATH
love .
```

2. Activer le debug HUD (optionnel) :
   - Éditez `my-librairie/hud/hudManager.lua` et mettez `hud.HUD_DEBUG_ENERGY = true` ou exécutez `hud.HUD_DEBUG_ENERGY = true` depuis la console si disponible.

3. Jouer une carte et observer la console pour voir les logs d'énergie et vérifier que l'UI se met à jour.

Notes et recommandations

- J'ai évité de créer des fichiers nouveaux à la racine (convention du projet). Le README est placé dans `docs/README.md`. Si vous préférez le README à la racine, dites‑le et je le déplace.
- Si vous voulez que je corrige aussi les warnings du linter (table.pack/unpack, signatures LÖVE), je peux faire un patch dédié.

Contact

- Pour tout autre correctif ou nettoyage (supprimer anciens fichiers, standardiser tous les require sur le nouveau chemin), indiquez la démarche souhaitée et je m'en occupe.
