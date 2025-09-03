# Organisation de la Documentation

Ce dossier `docs/` centralise toute la documentation du projet LÖVE2D Game-jam.

## Structure

### 📋 Documentation Principale
- `README.md` - Index général de la documentation
- `SceneManager_Documentation.md` - Système de gestion des scènes
- `HUD_Documentation.md` - Système HUD centralisé  
- `AI_Controller_Documentation.md` - Contrôleur IA et stratégies
- `InputSystem_Documentation.md` - Gestion input unifié
- `CardStandbyPlay_Documentation.md` - Système de cartes standby
- `Transitions_System.md` - Système de transitions

### 📚 Guides et Références
- `Card_Development_Guide.md` - Guide développement cartes
- `Card_Effects_Reference.md` - Référence effets de cartes
- `HUD_Quick_Reference.md` - Référence rapide HUD
- `AI_Controller_Quick_Reference.md` - Référence rapide IA
- `InputSystem_Quick_Reference.md` - Référence rapide Input

### 📖 Exemples et Tutoriels
- `HUD_Examples.md` - Exemples d'usage HUD
- `AI_Controller_Examples.md` - Exemples d'usage IA
- `InputSystem_Examples.md` - Exemples d'usage Input
- `examples/` - Code d'exemple réutilisable
  - `globalFunction.lua` - Exemples fonctions utilitaires
  - `refactor.lua` - Exemples de refactoring

### 🔧 Templates et Outils
- `templates/` - Modèles de documentation
  - `script_template.md` - Template pour documenter un module Lua
- `modules/` - Documentation spécifique par module
  - `my-librairie_sceneManager.md` - Doc détaillée SceneManager
- `my-librairie-README.md` - Documentation héritée my-librairie

### 📋 Migrations et Résolutions
- `migrations/` - Guides de migration
  - `globals.md` - Migration système de globales
- `HUD_Migration_Complete.md` - Migration HUD centralisé
- `Overlay_Initiative_HUD_Migration.md` - Migration overlay initiative
- `Problem_4_Resolution_Summary.md` - Résolution problème #4
- `Problem_5_Resolution_Summary.md` - Résolution problème #5
- `Documentation_Update_Plan.md` - Plan de mise à jour docs
- `StartStudio_Documentation.md` - Documentation StartStudio

## Nettoyage Effectué (Sept 2025)

✅ **Avant** : 3 dossiers de documentation dispersés
- `docs/` (racine)
- `my-librairie/docs/` 
- `my-librairie/documentation/`

✅ **Après** : 1 seul dossier `docs/` organisé
- Fusion de tout le contenu dans `docs/`
- Suppression des dossiers redondants
- Structure claire avec sous-dossiers thématiques

## Contribution

Pour ajouter de la documentation :
1. Utiliser les templates dans `templates/`
2. Placer dans le sous-dossier approprié
3. Mettre à jour ce fichier `ORGANIZATION.md` si nécessaire
