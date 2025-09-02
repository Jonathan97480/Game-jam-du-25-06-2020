# TODO - Refactoring complet du système d'application des effets de cartes

**Date de création** : 2 septembre 2025  
**Basé sur l'analyse de** : `docs/Card_Effects_Reference.md`  
**Objectif** : Réécrire entièrement le système d'application des effets pour corriger les Problèmes #6 et #7 (onPlay non exécuté, applyEffect défaillant)

---

## 🎯 Vision globale

**Problème actuel** : Le système d'application des effets est fragmenté, les `onPlay` ne s'exécutent pas, les effets `caster`/`target` ne s'appliquent pas correctement pour le joueur et l'IA.

**Architecture existante analysée** :
- `Common.playCard()` appelle `applyEffect.applyCardEffect()` mais le module `applyEffect` est manquant
- Modules `cardEffect/` (attack.lua, heal.lua, etc.) existent mais ne sont pas intégrés
- `play.lua` contient `_tryPlay()` qui appelle `Common.playCard()` et exécute `onPlay`
- `CardStandbyPlay` gère le système copie/invisible mais pas les effets
- `card_target_selection.lua` appelle `Card.Play.tryPlay()` pour exécuter les cartes

**Solution** : Créer un système centralisé, robuste et testable avec :
- Module `card_effects` central pour remplacer le `applyEffect` manquant
- Module `card_actions` avec utilitaires pour les fonctions `action`
- Intégration avec les modules `cardEffect/` existants (attack, heal, etc.)
- Support complet du `multiTarget` (AOE)
- Gestion sécurisée des erreurs avec `pcall`
- Tests unitaires exhaustifs

---

## 📋 Phase 1 : Architecture et modules de base

### 1.1 Créer le module `card_effects` central
**Fichier** : `my-librairie/card-librairie/core/card_effects.lua`

**Remplace** : Le module `applyEffect` manquant appelé par `Common.playCard()`

**Intégration avec l'existant** :
- Réutiliser les modules `cardEffect/attack.lua`, `heal.lua`, `giveSheld.lua`, `giveEpine.lua`
- Se connecter à `actorManager.applyEffect()` pour les effets sur acteurs
- Remplacer l'appel `applyEffect.applyCardEffect()` dans `Common.playCard()`

**API principale à implémenter** :
```lua
local card_effects = {}

-- ⭐ FONCTION PRINCIPALE - remplace applyEffect.applyCardEffect
function card_effects.applyCardEffect(card, source, target)

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
- [ ] Créer la structure de base du module avec `applyCardEffect` comme point d'entrée
- [ ] Implémenter `applyNumericEffects` en réutilisant `cardEffect/attack.lua`, `heal.lua`, etc.
- [ ] Implémenter `applyTemporalEffects` (bleeding, force_augmented avec number_turns)
- [ ] Implémenter `applyCasterEffects` et `applyToTarget` avec dispatch vers sous-effets
- [ ] Implémenter `applyToAllTargets` pour le support multiTarget
- [ ] Implémenter `executeAction` avec pcall pour exécuter `card.Effect.action`
- [ ] Ajouter validation et logs détaillés
- [ ] Remplacer l'import manquant dans `Common.playCard()` : `require("my-librairie/card-librairie/core/card_effects")`
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

**Points d'application identifiés** :
- `my-librairie/card-librairie/core/common.lua:289` : `applyEffect.applyCardEffect(card, source, target)` ⚠️ MODULE MANQUANT
- `my-librairie/card-librairie/play/play.lua:78` et `242` : Exécution `card.onPlay()` dans `_tryPlay` et `_cardPlaySelf`
- `my-librairie/card-librairie/ui/card_target_selection.lua:821` : Appel `Card.Play.tryPlay()` 
- `my-librairie/card-librairie/ui/interaction.lua:474,487` : Appels directs `Card.Play.tryPlay()`
- `my-librairie/card-librairie/cardEffect/` : Modules isolés (attack, heal, giveSheld, giveEpine) non intégrés

**Checklist 2.1** :
- [ ] **PRIORITÉ 1** : Créer `card_effects.lua` et remplacer l'import manquant dans `common.lua`
- [ ] Analyser et centraliser les appels `_tryPlay()` dans `play.lua`
- [ ] Intégrer les modules `cardEffect/` existants dans le nouveau système
- [ ] Auditer `card_target_selection.lua` et `interaction.lua` pour utiliser le nouveau système
- [ ] Chercher tous les appels directs à `_user.actor.state.*` et les centraliser
- [ ] Remplacer les `onPlay` manuels par `card_effects.executeAction`
- [ ] Vérifier `CardManager` et intégrer le nouveau système
- [ ] Audit complet avec grep_search pour trouver tous les points d'application cachés

### 2.2 Restructurer CardStandbyPlay
**Fichier existant** : `my-librairie/card-librairie/cardStandbyPlay.lua`

**Architecture actuelle analysée** :
- Système copie/invisible fonctionnel : `cardInStandby` (originale invisible) + `standbyCopy` (visible)
- État géré dans `CardStandbyPlay.state`
- Position de standby configurée : `standbyX = 50, standbyY = 400`
- Intégration avec `card_target_selection.lua` qui appelle `Card.Play.tryPlay()`

**Modifications requises** :

**Checklist 2.2** :
- [ ] Analyser `putCardInStandby()` pour détecter `card.multiTarget`
- [ ] Créer `playStandbyCardAOE()` pour cartes multi-target (bypass sélection cible)
- [ ] Modifier la logique de confirmation pour appeler `card_effects.applyToTarget/applyToAllTargets`
- [ ] Remplacer l'appel `Card.Play.tryPlay()` dans `card_target_selection.lua` par le nouveau système
- [ ] Assurer cohérence entre `CardStandbyPlay.state` et `CardTargetSelection`
- [ ] Tests de régression pour standby normal et AOE
- [ ] Vérifier que les animations standby fonctionnent avec multiTarget

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

### Priorité CRITIQUE (à faire EN PREMIER - BLOCAGE TOTAL)
1. **Phase 1.1** : Créer `card_effects.lua` avec `applyCardEffect()` pour réparer `Common.playCard()`
2. **Phase 2.1** : Remplacer l'import manquant dans `common.lua` ligne 289
3. **Test immédiat** : Vérifier qu'une carte simple (attaque de base) s'exécute sans erreur

### Priorité HAUTE (pour déblocage gameplay)
1. **Phase 1.2** : `card_actions` complet pour fonctions `action` des cartes
2. **Phase 2.1** : Intégrer modules `cardEffect/` existants dans le nouveau système  
3. **Phase 2.2** et **2.3** : Intégration CardStandbyPlay et IA avec nouveau système
4. **Phase 4.4** : Tests de régression pour s'assurer que les cartes s'exécutent

### Priorité MOYENNE (pour demo 4 mois)
1. **Phase 1.3** : Support `multiTarget` complet
2. **Phase 3** : Projectiles, localisation, sauvegarde
3. **Phase 4.1-4.3** : Tests unitaires complets
4. **Phase 5** : Documentation

**URGENCE ABSOLUE** : Le module `applyEffect` manquant empêche TOUTE exécution d'effet de carte. C'est la cause racine des Problèmes #6 et #7.

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
- `my-librairie/card-librairie/core/card_effects.lua` ⭐ **REMPLACE applyEffect manquant**
- `my-librairie/card-librairie/core/card_actions.lua`
- `test/card_effects_test.lua`
- `test/card_actions_test.lua`
- `test/card_system_integration_test.lua`
- `localization/fr.json`
- `localization/en.json`

### À modifier :
- `my-librairie/card-librairie/core/common.lua` ⚠️ **URGENT - ligne 289 import applyEffect manquant**
- `my-librairie/card-librairie/play/play.lua` (intégrer nouveau système dans _tryPlay)
- `my-librairie/card-librairie/cardStandbyPlay.lua` (support multiTarget)
- `my-librairie/card-librairie/ui/card_target_selection.lua` (remplacer tryPlay)
- `my-librairie/card-librairie/ui/interaction.lua` (remplacer tryPlay)
- `my-librairie/ai/controller.lua` (utiliser nouveau système)
- `my-librairie/card-librairie/core/generator.lua` (ajouter multiTarget flag)
- `ressources/cards_data_player.lua` (pour multiTarget sur cartes AOE)
- `my-librairie/core/globals.lua` (ajout modules)

### À intégrer (existants) :
- `my-librairie/card-librairie/cardEffect/attack.lua` → dans card_effects
- `my-librairie/card-librairie/cardEffect/heal.lua` → dans card_effects  
- `my-librairie/card-librairie/cardEffect/giveSheld.lua` → dans card_effects
- `my-librairie/card-librairie/cardEffect/giveEpine.lua` → dans card_effects

### À analyser/audit :
- Tous les fichiers avec `grep_search` pour `applyEffect|onPlay|tryPlay|_user\.actor\.state`
- `my-librairie/card-librairie/` complet pour points d'application cachés
- `scene/gameplay/` pour intégration runtime
- Tests existants `test/test_cardstandbyplay.lua` pour validation

---

---

## 📦 ANALYSE COMPLÈTE DES CARTES ET ASSETS REQUIS

### 🎮 **Cartes Joueur Analysées** (cards_data_player.lua)

| Carte | Effets utilisés | Assets visuels requis | Assets audio requis |
|-------|----------------|----------------------|-------------------|
| **A demain** | `chancePassedTour: 25%` | Sleep/Stun effect, Particle stars | Sleep.ogg, MagicCast.ogg |
| **Coup puissant** | `attack: 12` | Impact slash, Blood splatter | SwordHit.ogg, MeleeImpact.ogg |
| **Aide moi mon ami** | `shield: 4, shield: +4 (jumelle)` | Shield bubble, Shield particles | ShieldUp.ogg, MagicShield.ogg |
| **Bouclier depines** | `shield: 8, Epine: 50` | Thorn shield, Spiky barrier | ThornShield.ogg, SpikeActivate.ogg |
| **Griffure** | `attack: 8` | Claw marks, Small blood | ClawScratch.ogg, AnimalAttack.ogg |
| **Ca va piquer** | Graveyard→Deck, Deck→Hand | Card recycling, Draw effect | CardShuffle.ogg, CardDraw.ogg |
| **Toi et moi** | `heal: 10, free play (jumelle)` | Healing light, Heart particles | Heal.ogg, LoveSpell.ogg |
| **Double frappe** | `attack: 5, AttackReduction: 25%` | Double hit, Weakness debuff | DoubleStrike.ogg, WeaknessDebuff.ogg |
| **Deux soeurs** | `attack: 2, deck draw` | Twin connection, Card draw | TwinMagic.ogg, CardDraw.ogg |
| **A** | `attack: 10, deck search` | Letter glow, Search effect | PowerStrike.ogg, CardSearch.ogg |

### 🤖 **Cartes IA Analysées** (EnemySceneDemo.lua)

| Ennemi | Carte | Effets | Assets projectiles requis | Assets impact requis |
|--------|-------|--------|-------------------------|-------------------|
| **Pouplpie** | j'ais d'encre | `caster.attack: 5` | Ink projectile (dark blob) | Ink splatter effect |
| **Assasin Crue** | j'ais de couteau | `caster.attack: 5` | Knife projectile sprites | Knife impact, metallic sound |
| **Spider** | Fil d'Ariane | `caster.attack: 5` | Web projectile animation | Web impact, entangle effect |
| **Chevalier Noir** | Attaque Rapide | `caster.attack: 5` | Sword slash trail | Sword impact, sparks |

### 🎨 **Assets existants détectés** :
- `img/effect/Attaque-base/` : 8 frames (frame-0 à frame-7) ✅
- `img/effect/heal/` : 5 frames (bonuss-heal-1 à bonuss-heal-5) ✅
- `img/effect/shield/`, `img/effect/epine/`, `img/effect/degat/` ✅

---

## 📋 **LISTE COMPLÈTE DES ASSETS À CRÉER**

### 🖼️ **Assets Visuels - Effets de cartes joueur**

#### **Effets d'état et buffs/debuffs** :
- [ ] **Sleep/Stun effect** : Animation particules dorées + "Zzz" (chancePassedTour)
- [ ] **Shield bubble** : Bulle de protection bleue translucide (shield)
- [ ] **Thorn shield** : Bouclier avec épines rouges qui brillent (Epine)
- [ ] **Weakness debuff** : Aura rouge/grise autour de l'ennemi (AttackReduction)
- [ ] **Healing light** : Rayons verts/dorés descendant du ciel (heal)
- [ ] **Twin connection** : Effet magique reliant deux cartes (cartes jumelles)

#### **Effets d'attaque et dégâts** :
- [ ] **Impact slash** : Effet de tranchant pour attaques puissantes
- [ ] **Claw marks** : Traces de griffes pour "Griffure"
- [ ] **Double hit effect** : Animation double impact synchronisé
- [ ] **Blood splatter** : Éclaboussures de sang pour dégâts critiques
- [ ] **Letter glow** : Effet lumineux pour la carte "A"

#### **Effets de manipulation cartes** :
- [ ] **Card recycling** : Animation cartes voltigeant du cimetière au deck
- [ ] **Card draw effect** : Effet magique de tirage de carte
- [ ] **Card search** : Lueur dorée parcourant le deck

### 🎯 **Assets Visuels - Projectiles IA**

#### **Projectiles par ennemi** :
- [ ] **Ink projectile** : Boule d'encre noire avec traînée (Pouplpie)
  - Sprite : `ink_projectile.png` (32x32)
  - Animation : 4 frames de rotation
  - Traînée : Particules noires qui s'estompent

- [ ] **Knife projectile** : Couteau tournoyant (Assasin Crue)
  - Sprite : `knife_projectile.png` (24x48)  
  - Animation : 8 frames de rotation
  - Traînée : Éclat métallique

- [ ] **Web projectile** : Toile d'araignée (Spider)
  - Sprite : `web_projectile.png` (40x40)
  - Animation : 6 frames d'expansion
  - Traînée : Fils argentés

- [ ] **Sword slash** : Lame d'énergie (Chevalier Noir)
  - Sprite : `sword_slash.png` (48x16)
  - Animation : 5 frames d'allongement
  - Traînée : Lumière dorée

#### **Effets d'impact projectiles** :
- [ ] **Ink splatter** : Explosion d'encre (4 frames)
- [ ] **Knife impact** : Étincelles métalliques + son métallique
- [ ] **Web impact** : Toile qui s'étend + effet collant
- [ ] **Sword impact** : Explosion d'énergie + étincelles

### 🔊 **Assets Audio**

#### **Effets de cartes joueur** :
- [ ] **Sleep.ogg** : Son doux de sommeil/étourdissement
- [ ] **SwordHit.ogg** : Impact d'épée métallique
- [ ] **ShieldUp.ogg** : Activation de bouclier (whoosh + clang)
- [ ] **ThornShield.ogg** : Crépitement d'épines
- [ ] **ClawScratch.ogg** : Grattement de griffes
- [ ] **Heal.ogg** : Son magique de guérison
- [ ] **DoubleStrike.ogg** : Double impact rapide
- [ ] **CardShuffle.ogg** : Brassage de cartes
- [ ] **CardDraw.ogg** : Tirage de carte

#### **Projectiles et impacts IA** :
- [ ] **InkLaunch.ogg** : Lancement de projectile visqueux
- [ ] **InkSplat.ogg** : Impact d'encre
- [ ] **KnifeLaunch.ogg** : Sifflement de couteau
- [ ] **KnifeHit.ogg** : Impact métallique
- [ ] **WebLaunch.ogg** : Lancement de toile
- [ ] **WebHit.ogg** : Impact collant
- [ ] **SwordSlash.ogg** : Tranchant d'épée énergétique
- [ ] **EnergyImpact.ogg** : Impact d'énergie

### 🎭 **Effets AOE (pour multiTarget)**

#### **Visuels AOE à créer** :
- [ ] **Fire explosion** : Explosion de feu avec onde de choc
- [ ] **Ice blast** : Explosion de glace avec cristaux
- [ ] **Lightning storm** : Éclairs multiples frappant plusieurs cibles
- [ ] **Poison cloud** : Nuage toxique s'étendant
- [ ] **Healing wave** : Onde dorée de guérison de groupe

#### **Audio AOE** :
- [ ] **Explosion.ogg** : Explosion puissante
- [ ] **IceShatter.ogg** : Fracas de glace
- [ ] **Thunder.ogg** : Grondement de tonnerre
- [ ] **PoisonHiss.ogg** : Sifflement toxique
- [ ] **HealingWave.ogg** : Onde harmonique

---

## 📊 **Résumé par priorité**

### **PRIORITÉ 1 - Effets de base** (pour démo fonctionnelle) :
- Attaque de base (existant ✅)
- Heal (existant ✅) 
- Shield (existant ✅)
- Projectiles IA simples (4 types)

### **PRIORITÉ 2 - Effets avancés** (pour gameplay complet) :
- Sleep/Stun, AttackReduction, Epine
- Effets de cartes jumelles
- Manipulation deck/hand/graveyard

### **PRIORITÉ 3 - Polish et AOE** (pour démo finale) :
- Effets AOE multiTarget
- Animations avancées
- Audio polish

**Total estimé** : ~45 assets visuels + ~20 assets audio = **65 assets à créer**
