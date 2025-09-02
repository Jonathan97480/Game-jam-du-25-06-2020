# TODO - Refactoring complet du système d'application des effets de cartes

**Date de création** : 2 septembre 2025  
**Basé sur l'analyse de** : `docs/Card_Effects_Reference.md`  
**Objectif** : Réécrire entièrement le système d'application des effets pour corriger les Problèmes #6 et #7 (onPlay non exécuté, applyEffect défaillant)

---

## 🎯 Vision globale

**Problème actuel** : Le système d'application des effets est fragmenté, les `onPlay` ne s'exécutent pas, les effets `caster`/`target` ne s'appliquent pas correctement pour le joueur et l'IA.

**Solution** : Créer un système centralisé, robuste et testable avec :
- Module `card_effects` central pour toute application d'effets
- Module `card_actions` avec utilitaires pour les fonctions `action`
- Support complet du `multiTarget` (AOE)
- Gestion sécurisée des erreurs avec `pcall`
- Tests unitaires exhaustifs

---

## 📋 Phase 1 : Architecture et modules de base

### 1.1 Créer le module `card_effects` central
**Fichier** : `my-librairie/card-librairie/core/card_effects.lua`

**API principale à implémenter** :
```lua
local card_effects = {}

-- Application single-target (carte normale)
function card_effects.applyToTarget(card, targetActor, casterActor)
function card_effects.applyCasterEffects(card, casterActor)

-- Application multi-target (cartes AOE)
function card_effects.applyToAllTargets(card, enemies, casterActor)

-- Application des champs numériques (heal, shield, attack, etc.)
function card_effects.applyNumericEffects(effectTable, actor)
function card_effects.applyTemporalEffects(effectTable, actor) -- bleeding, force_augmented

-- Exécution sécurisée des fonctions action
function card_effects.executeAction(card, context)

-- Validation et logs
function card_effects.validateEffect(effect)
function card_effects.logEffectApplication(card, target, result)

return card_effects
```

**Checklist 1.1** :
- [ ] Créer la structure de base du module
- [ ] Implémenter `applyNumericEffects` (heal, shield, attack, Epine, etc.)
- [ ] Implémenter `applyTemporalEffects` (bleeding, force_augmented avec number_turns)
- [ ] Implémenter `applyCasterEffects` et `applyToTarget`
- [ ] Implémenter `applyToAllTargets` pour le support multiTarget
- [ ] Implémenter `executeAction` avec pcall et gestion d'erreurs
- [ ] Ajouter validation et logs détaillés
- [ ] Intégrer avec le système de globals (`_G.card_effects`)

### 1.2 Créer le module `card_actions` utilitaires
**Fichier** : `my-librairie/card-librairie/core/card_actions.lua`

**Fonctions à implémenter** (basées sur Card_Effects_Reference.md) :
```lua
local card_actions = {}

-- Manipulation deck/hand/graveyard
function card_actions.drawFromDeck(deck, n, toHand)
function card_actions.moveFromGraveyard(filter, dest, count)
function card_actions.moveBetweenZones(sourceZone, destZone, cardIndex)

-- Recherche de cartes
function card_actions.findCardByName(name, zone)
function card_actions.findCardsByType(typeName, zone)
function card_actions.findCardsByRarity(rarity, zone)

-- Effets spéciaux
function card_actions.setTargetStone(targetActor, durationTurns)
function card_actions.addEffectToActor(actor, effectTable)

-- Effets visuels et projectiles
function card_actions.spawnProjectileEffect(opts)
function card_actions.playAOEEffect(centerPos, radius, effectTable)

-- Utilitaires
function card_actions.safeCall(fn, ...)
function card_actions.scheduleDelayed(func, delaySeconds)

return card_actions
```

**Checklist 1.2** :
- [ ] Implémenter toutes les fonctions de manipulation deck/hand/graveyard
- [ ] Implémenter les fonctions de recherche avec support filtres
- [ ] Implémenter setTargetStone avec intégration au système de tours
- [ ] Implémenter addEffectToActor avec fusion intelligente d'effets
- [ ] Implémenter spawnProjectileEffect avec actorManager
- [ ] Implémenter playAOEEffect pour zones d'effet
- [ ] Implémenter safeCall et scheduleDelayed
- [ ] Tests unitaires pour chaque fonction
- [ ] Intégrer avec le système de globals (`_G.card_actions`)

### 1.3 Support du multiTarget
**Modifications requises** :

**Checklist 1.3** :
- [ ] Ajouter `multiTarget` dans le générateur de cartes (par défaut false)
- [ ] Modifier `CardStandbyPlay` pour détecter `multiTarget`
- [ ] Implémenter flux AOE dans `CardStandbyPlay` (bypass sélection de cible)
- [ ] Modifier l'IA pour supporter `multiTarget`
- [ ] Créer animations AOE visuelles
- [ ] Tests pour cartes single-target vs multi-target

---

## 📋 Phase 2 : Intégration et remplacement du système existant

### 2.1 Identifier et remplacer les anciens points d'application
**Localiser tous les endroits où les effets sont appliqués actuellement** :

**Checklist 2.1** :
- [ ] Analyser `Card.Play.tryPlay` et remplacer par `card_effects.applyToTarget`
- [ ] Analyser l'IA controller et remplacer par le nouveau système
- [ ] Chercher tous les appels directs à `_user.actor.state.*` et les centraliser
- [ ] Remplacer les `onPlay` manuels par `card_effects.executeAction`
- [ ] Vérifier `CardManager` et intégrer le nouveau système
- [ ] Audit complet avec grep_search pour trouver tous les points d'application

### 2.2 Restructurer CardStandbyPlay
**Modifications** :

**Checklist 2.2** :
- [ ] Modifier `putCardInStandby` pour détecter `multiTarget`
- [ ] Créer `playStandbyCardAOE` pour cartes multi-target
- [ ] Intégrer `card_effects.applyToTarget` et `applyToAllTargets`
- [ ] Assurer cohérence avec CardTargetSelection
- [ ] Tests de régression pour standby normal et AOE

### 2.3 Restructurer l'IA
**Modifications** :

**Checklist 2.3** :
- [ ] Modifier `ai/controller.lua` pour utiliser `card_effects`
- [ ] Implémenter stratégie IA pour cartes `multiTarget`
- [ ] Assurer que `getCurrentEnemy` fonctionne avec le nouveau système
- [ ] Tests IA single-target et multi-target
- [ ] Validation que les logs IA n'ont plus "aucun changement d'état"

---

## 📋 Phase 3 : Support des fonctionnalités avancées

### 3.1 Système de projectiles et effets visuels
**Intégration avec actorManager** :

**Checklist 3.1** :
- [ ] Créer système d'acteurs projectiles légers
- [ ] Implémenter collision detection
- [ ] Système d'animations (travel, hit, explode)
- [ ] Support des trajectoires (linear, parabola, custom)
- [ ] Gestion du timing (délais entre lancement et impact)
- [ ] Intégration avec `spawnProjectileEffect`

### 3.2 Localisation des effets
**Support multi-langue** :

**Checklist 3.2** :
- [ ] Ajouter `name_key` et `description_key` aux cartes
- [ ] Créer `localization/fr.json` et `localization/en.json`
- [ ] Implémenter `textFormatter` avec variables ({damage}, {target}, etc.)
- [ ] Modifier le générateur de cartes pour utiliser les clés
- [ ] UI de sélection de langue

### 3.3 Système de sauvegarde JSON
**Persistance des états d'effets temporels** :

**Checklist 3.3** :
- [ ] Sauvegarder bleeding/force_augmented en cours
- [ ] Sauvegarder états d'acteurs (shield, Epine, etc.)
- [ ] Sauvegarder deck/hand/graveyard avec IDs de cartes
- [ ] Charger et restaurer tous les états
- [ ] Validation des données chargées

---

## 📋 Phase 4 : Tests et validation

### 4.1 Tests unitaires pour card_effects
**Fichier** : `test/card_effects_test.lua`

**Checklist 4.1** :
- [ ] Test `applyNumericEffects` (heal, shield, attack)
- [ ] Test `applyTemporalEffects` (bleeding, force_augmented)
- [ ] Test `applyToTarget` complet
- [ ] Test `applyToAllTargets` avec liste d'ennemis
- [ ] Test `executeAction` avec succès et échec
- [ ] Test validation d'effets malformés
- [ ] Test logs et traces

### 4.2 Tests unitaires pour card_actions
**Fichier** : `test/card_actions_test.lua`

**Checklist 4.2** :
- [ ] Test drawFromDeck avec deck vide/plein
- [ ] Test moveFromGraveyard avec filtres string et function
- [ ] Test findCardByName/Type/Rarity
- [ ] Test setTargetStone et intégration système de tours
- [ ] Test addEffectToActor avec fusion d'effets
- [ ] Test safeCall avec fonctions valides/invalides

### 4.3 Tests d'intégration
**Fichier** : `test/card_system_integration_test.lua`

**Checklist 4.3** :
- [ ] Test complet player joue carte single-target
- [ ] Test complet player joue carte multi-target
- [ ] Test complet IA joue carte single-target
- [ ] Test complet IA joue carte multi-target
- [ ] Test cartes avec action complexe (jumelles, etc.)
- [ ] Test CardStandbyPlay avec nouveau système
- [ ] Test persistance/chargement états

### 4.4 Tests de régression
**Vérifier que les anciens comportements fonctionnent** :

**Checklist 4.4** :
- [ ] Toutes les cartes existantes s'exécutent sans erreur
- [ ] Les logs n'affichent plus "onPlay non exécuté"
- [ ] Les effets s'appliquent visiblement (PV, shield, etc.)
- [ ] L'IA prend des décisions cohérentes
- [ ] Performance stable (pas de fuites mémoire)

---

## 📋 Phase 5 : Documentation et finalisation

### 5.1 Documentation technique
**Checklist 5.1** :
- [ ] Mettre à jour `Card_Effects_Reference.md` avec la nouvelle API
- [ ] Créer `docs/Card_Effects_Implementation.md`
- [ ] Documenter l'API `card_effects` et `card_actions`
- [ ] Exemples d'usage pour développeurs
- [ ] Guide de migration depuis l'ancien système

### 5.2 Exemples et cas d'usage
**Checklist 5.2** :
- [ ] Créer exemple de carte simple (attaque de base)
- [ ] Créer exemple de carte AOE
- [ ] Créer exemple de carte avec action complexe
- [ ] Créer exemple de carte avec projectile
- [ ] Créer exemple de carte temporelle (bleeding)

---

## 🚨 Priorités et ordre d'exécution

### Priorité CRITIQUE (à faire en premier)
1. **Phase 1.1** : Créer `card_effects` avec API de base
2. **Phase 2.1** : Identifier et remplacer anciens points d'application
3. **Phase 4.4** : Tests de régression pour s'assurer que ça marche

### Priorité HAUTE (pour demo 4 mois)
1. **Phase 1.2** : `card_actions` complet
2. **Phase 1.3** : Support `multiTarget`
3. **Phase 2.2** et **2.3** : Intégration CardStandbyPlay et IA

### Priorité MOYENNE (features avancées)
1. **Phase 3** : Projectiles, localisation, sauvegarde
2. **Phase 4.1-4.3** : Tests unitaires complets
3. **Phase 5** : Documentation

---

## 📊 Estimation temporelle

- **Phase 1** : 1-2 semaines (modules de base)
- **Phase 2** : 1 semaine (intégration)
- **Phase 3** : 2-3 semaines (features avancées)
- **Phase 4** : 1 semaine (tests)
- **Phase 5** : 3-4 jours (documentation)

**Total estimé** : 5-7 semaines pour refactoring complet

---

## 🔗 Fichiers impactés (liste préliminaire)

### À créer :
- `my-librairie/card-librairie/core/card_effects.lua`
- `my-librairie/card-librairie/core/card_actions.lua`
- `test/card_effects_test.lua`
- `test/card_actions_test.lua`
- `test/card_system_integration_test.lua`
- `localization/fr.json`
- `localization/en.json`

### À modifier :
- `my-librairie/card-librairie/cardStandbyPlay.lua`
- `my-librairie/ai/controller.lua`
- `my-librairie/card-librairie/card.lua`
- `my-librairie/card-librairie/play/*.lua`
- `ressources/cards_data_player.lua` (pour multiTarget)
- `my-librairie/core/globals.lua` (ajout modules)

### À analyser/audit :
- Tous les fichiers avec `grep_search` pour trouver application d'effets existante
- `my-librairie/card-librairie/` complet
- `scene/gameplay/` pour intégration

---

**Prochaine étape recommandée** : Commencer Phase 1.1 - Créer le module `card_effects` de base avec l'API principale.
