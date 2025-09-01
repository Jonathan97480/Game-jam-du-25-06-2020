# 📋 TODO - Corrections Projet LÖVE2D Game Jam
**Date de création**: 1er septembre 2025  
**Projet**: Jeu de Cartes Tactique LÖVE2D  
**Branche**: beta  

## 🎯 Progression Globale
- [x] ✅ Analyse complète des logs effectuée
- [x] ✅ Problèmes critiques identifiés (3 principaux)
- [x] ✅ Tests de validation créés
- [ ] 🔄 Corrections en cours...

---

## 🔥 PRIORITÉ CRITIQUE - Bugs à Corriger Immédiatement

### ✅ 1. Positions des ennemis = nil (RÉSOLU)
- [x] **Problème identifié**: Logs DEBUG affichaient `x: nil, y: nil`
- [x] **Cause trouvée**: Logs cherchaient `enemy.x/y` au lieu de `enemy.vector2.x/y`
- [x] **Solution appliquée**: Correction des logs de debug dans `card_target_selection.lua`
- [x] **Test validé**: `test_simple_enemy_positions.lua`
- [x] **Commit effectué**: `677ee9d` - Fix: Correction logs debug positions ennemis
- [x] **Status**: ✅ **RÉSOLU ET COMMITTÉ**

### 🔥 2. Erreur "attempt to call a string value" dans l'IA
- [x] **Problème identifié**: `globalFunction.safecall` mal utilisé - inversion paramètres
- [x] **Source localisée**: `my-librairie/ai/controller.lua` lignes 506, 511, 527, 532
- [x] **Cause**: Appels `safecall("string", function)` au lieu de `safecall(function)`
- [x] **Solution appliquée**: Correction signature + ajout pattern `onPlay(target)`
- [x] **Fichiers modifiés**:
  - [x] `my-librairie/ai/controller.lua` (safecall corrigé + signature target-only)
  - [x] `test/test_ai_safecall_fix.lua` (test de validation)
- [x] **Test validé**: Logs `session_20250901_124129.log` - Plus d'erreur "attempt to call"
- [x] **Status**: ✅ **RÉSOLU** - Correction fonctionnelle

### ⚙️ 3. GameFlags non initialisés
- [x] **Problème identifié**: Duplication définition `GameFlags` + flag `first_draft_done = nil`
- [x] **Source localisée**: `my-librairie/core/globals.lua` lignes 81 et 115 (duplication)
- [x] **Solution appliquée**: Suppression duplication + renommage flag + initialisation robuste
- [x] **Fichiers modifiés**:
  - [x] `my-librairie/core/globals.lua` (suppression duplication, logique OR robuste)
  - [x] `my-librairie/transitions/templateCombatTransition.lua` (renommage flag)
  - [x] `scene/gameplay/gameplay.lua` (mise à jour logs debug)
  - [x] `test/test_gameflags_fix.lua` (test de validation)
- [x] **Renommage**: `first_draft_done` → `initial_draft_completed` (plus explicite)
- [x] **Valeur par défaut**: `false` (logique métier: draft pas encore fait)
- [x] **Test validé**: ✅ Initialisation robuste + préservation valeurs existantes
- [x] **Status**: ✅ **RÉSOLU** - GameFlags correctement initialisés et renommés

---

## 📊 PRIORITÉ HAUTE - Optimisations et Améliorations

### 4. Verbosité excessive des logs CardTargetSelection
- [x] **Problème identifié**: Logs DEBUG répétitifs dans `card_target_selection.lua`
- [ ] **Action requise**: Réduire les logs ou les conditionner avec un flag
- [ ] **Impact**: Performance et lisibilité des logs
- [ ] **Status**: 🔄 **EN ATTENTE**

### 5. Validation du système CardStandbyPlay
- [x] **Problème identifié**: Vérifier cohérence copie/invisible
- [x] **Tests disponibles**: `test/test_cardstandbyplay.lua`
- [ ] **Action requise**: Validation complète du système
- [ ] **Status**: 🔄 **EN ATTENTE**

### 6. Amélioration gestion d'erreurs IA
- [x] **Problème identifié**: Manque de validation avant exécution des cartes
- [ ] **Action requise**: Meilleure validation dans `my-librairie/ai/controller.lua`
- [ ] **Fallbacks**: Ajouter des fallbacks plus robustes
- [ ] **Status**: 🔄 **EN ATTENTE**

---

## 🔧 PRIORITÉ MOYENNE - Maintenance et Structure

### 7. Optimisation du cache de ressources
- [ ] **Action**: Vérifier fuites mémoire dans `resource_cache.lua`
- [ ] **Monitoring**: Ajouter logs de cache hit/miss
- [ ] **Status**: 🔄 **EN ATTENTE**

### 8. Consolidation des patterns de require
- [ ] **Action**: Standardiser `_safeRequire` vs `pcall(require)`
- [ ] **Scope**: Tous les modules avec require conditionnel
- [ ] **Status**: 🔄 **EN ATTENTE**

### 9. Amélioration du système de transitions
- [ ] **Action**: Vérifier `GameFlags.first_draft_done` dependencies
- [ ] **Debug**: Répétitions dans `transition_debug.log`
- [ ] **Status**: 🔄 **EN ATTENTE**

---

## 📝 PRIORITÉ BASSE - Documentation et Tests

### 10. Mise à jour documentation
- [ ] **Action**: Synchroniser `docs/` avec changements récents
- [ ] **Focus**: CardStandbyPlay, HUD centralisé
- [ ] **Status**: 🔄 **EN ATTENTE**

### 11. Extension des tests unitaires
- [ ] **Nouveaux tests requis**:
  - [ ] Test positions ennemis (✅ déjà créé)
  - [ ] Test fonctions onPlay
  - [ ] Test GameFlags
- [ ] **Status**: 🔄 **EN ATTENTE**

### 12. Optimisation configuration debug
- [ ] **Action**: Centraliser les flags de debug
- [ ] **Pattern**: Uniformiser `DEBUG_*` variables
- [ ] **Status**: 🔄 **EN ATTENTE**

---

## 🎯 Ordre de Correction Recommandé

1. **🔥 Problème #2**: Erreur "attempt to call a string value" (30 min, stabilité IA)
2. **⚙️ Problème #3**: GameFlags non initialisés (5 min, impact majeur)
3. **📊 Problème #4**: Réduire verbosité logs (10 min, performance)
4. **📊 Problème #5**: Tester CardStandbyPlay (20 min, validation)
5. **📊 Problème #6**: Améliorer gestion erreurs IA (30 min, robustesse)

---

## 📈 Estimation Temps Total
- **Corrections critiques restantes**: 35 minutes
- **Optimisations haute priorité**: 60 minutes
- **Total pour stabilité complète**: ~1h35

---

## 📝 Notes de Session
- **Dernière mise à jour**: 1er septembre 2025, 12:22
- **Dernier commit**: `677ee9d` - Fix positions ennemis
- **Tests créés**: `test_simple_enemy_positions.lua`, `test_enemy_positions.lua`

## ✅ Comment Marquer un Problème Résolu
1. Changer `[ ]` en `[x]` pour les éléments terminés
2. Ajouter le hash du commit dans **Notes de Session**
3. Mettre à jour le **Status** vers ✅ **RÉSOLU**
4. Ajouter la date de résolution

---
*Ce fichier est mis à jour au fur et à mesure des corrections.*
