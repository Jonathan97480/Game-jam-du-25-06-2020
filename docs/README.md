README — Game Jam (fork)

## Documentation Disponible

### 📚 Système HUD
- **[Documentation Complète HUD](HUD_Documentation.md)** - Guide détaillé du système d'interface utilisateur
- **[Référence Rapide HUD](HUD_Quick_Reference.md)** - API et patterns essentiels
- **[Exemples HUD](HUD_Examples.md)** - Implémentations pratiques complètes

### 🎮 Résumé des Changements Récents

- **HUD System** : Architecture modulaire en 5 couches avec composants réutilisables
- **Boutons Avancés** : États hover/click, centrage automatique, gestion des images
- **Responsive Design** : Adaptation automatique aux résolutions
- **Refactor** : consolidation des effets dans `my-librairie/card-librairie/effects/cardEffect_shim.lua`
- **Compat** : `my-librairie/card-librairie/core/common.lua` mis à jour pour charger le nouveau module d'effets
- **Debug** : logs détaillés et flags de debug pour le HUD et l'énergie

### 🏗️ Architecture Principale

#### Code Principal
- `main.lua` - Point d'entrée, gestion des globales
- `scene/` - Scènes du jeu avec lifecycle standard
- `my-librairie/globals.lua` - Système de globales centralisé

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
