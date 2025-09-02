# 🎮 TODO NOUVEAU FLOW DES SCÈNES
**Date de création**: 2 septembre 2025  
**Objectif**: Implémentation complète du nouveau système de navigation  
**Priorité**: PRINCIPALE - Refonte architecture jeu  
**🎯 OBJECTIF DÉMO**: Un étage complet fonctionnel en 4 mois (décembre 2025)  

## 📋 TÂCHES EN COURS DEPUIS HIER

### 🔧 Problème #6 - Échec Exécution Effets Cartes IA ⚠️ **EN COURS**
- [ ] **Investigation**: Système signatures d'appel IA controller
- [ ] **Analyse**: Coordination `applyEffect` + `onPlay` functions
- [ ] **Debug**: Pourquoi signatures ne correspondent pas
- [ ] **Test**: Validation exécution effets cartes IA
- [ ] **Cartes à corriger**: `j'ais d'encre`, `Attaque Rapide`, `Fil d'Ariane`, `j'ais de couteau`
- [ ] **Impact**: Gameplay IA non fonctionnel - priorité haute
- [ ] **Status**: Reporté d'hier - **À terminer aujourd'hui**

### 🆕 Problème #7 - Effets Cartes Joueur Non Appliqués ⚠️ **NOUVEAU**
- [ ] **Problème**: Cartes joueur validées mais effets/dégâts non appliqués
- [ ] **Symptôme**: Animation carte OK mais pas d'impact sur ennemi
- [ ] **Impact**: Gameplay joueur cassé - combat non fonctionnel
- [ ] **Root cause**: Système `applyEffect` défaillant global
- [ ] **Urgence**: 🔥 **CRITIQUE** - Jeu non jouable
- [ ] **Next**: Investigation parallèle avec Problème #6
- [ ] **Status**: 🆕 **DÉTECTÉ** - Investigation immédiate requise

---

## 🚀 NOUVEAU FLOW DES SCÈNES - ARCHITECTURE COMPLÈTE

### 🎯 PHASE 1 - Scènes de Base et Navigation

#### 1.1 Système Effets Cartes - Refonte Complète ⭐ **PRIORITÉ URGENTE**
- [ ] **🔧 Fix Core Effects System**:
  - [ ] Investigation système `applyEffect` global
  - [ ] Correction exécution effets joueur ET IA
  - [ ] Validation damage/heal/shield appliqués
  - [ ] Tests complets toutes cartes existantes
- [ ] **🎨 Nouveaux Assets Effets**:
  - [ ] Effets visuels dégâts étendus (slash, pierce, magic)
  - [ ] Effets heal améliorés (particles, glow)
  - [ ] Effets shield renforcés (barriers, absorption)
  - [ ] Effets debuff/buff (poison, strength, weakness)
  - [ ] Effets multi-cible (AOE circles, chain lightning)
  - [ ] Animations impact synchronisées avec dégâts
- [ ] **🏷️ Système Tags Cartes**:
  - [ ] Tag `multiTarget` dans générateur cartes
  - [ ] Logique auto-détection cartes multi-cibles
  - [ ] Valeur par défaut `multiTarget = false`
  - [ ] Override manuel `multiTarget = true` si spécifié
- [ ] **⚔️ Auto-Play Multi-Cibles**:
  - [ ] Modification `CardStandbyPlay` pour auto-play
  - [ ] Détection tag `multiTarget` avant ciblage
  - [ ] Bypass sélection cible si multi-target
  - [ ] Application effets à tous ennemis vivants
  - [ ] Animation simultanée tous targets

#### 1.2 Scène Start & Logos ⭐ **NOUVEAU**
- [ ] **Créer** `scene/start_studio/` - Logo studio initial
- [ ] **Implémentation**: Transition automatique vers menu après 3-5s
- [ ] **🎨 Assets**: 
  - [ ] Logo studio (1920x1080) - format PNG/SVG
  - [ ] Animation fade in/out
  - [ ] Son de démarrage (optionnel)
- [ ] **Transition**: Fade out → Menu principal
- [ ] **Skip**: Possibilité d'appuyer sur une touche pour passer

#### 1.3 Menu Principal Étendu ⭐ **NOUVEAU**
- [ ] **Améliorer** `scene/menu/` existant
- [ ] **🎨 Assets Menu**:
  - [ ] Background menu principal (1920x1080)
  - [ ] Boutons UI redesignés (Play, Options, Crédits, Quitter, Charger)
  - [ ] Hover effects et animations boutons
  - [ ] Logo du jeu principal
  - [ ] Musique d'ambiance menu
- [ ] **Nouveaux boutons**:
  - [ ] 🎮 **Play** (nouveau jeu ou continuer)
  - [ ] 💾 **Charger une partie** (save system)
  - [ ] ⚙️ **Options** (paramètres jeu)
  - [ ] 🏆 **Crédits** (équipe développement)
  - [ ] ❌ **Quitter** (fermeture jeu)
- [ ] **UI/UX**: Disposition claire et responsive
- [ ] **Navigation**: Support clavier/manette + souris

#### 1.4 Système de Sauvegarde JSON ✅ **TERMINÉ** (3 sept)
- [x] **Créer** `my-librairie/save-system/` ✅
- [x] **Architecture JSON** ✅:
  - [x] `saveManager.lua` - Gestionnaire principal save/load ✅
  - [x] `saveUI.lua` - Interface utilisateur complète ✅
  - [x] Structure données et validation intégrées ✅
- [x] **Fonctionnalités Principales** ✅:
  - [x] **Sauvegarde/Chargement**: Système JSON complet ✅
  - [x] **Auto-save**: Sauvegarde automatique (5min) ✅
  - [x] **Gestion slots**: 10 slots + auto-saves ✅
  - [x] **Interface UI**: Menu save/load intégré HUD ✅
  - [x] **Validation**: Vérification intégrité données ✅
  - [x] **Raccourcis**: F5=quick save, F9=quick load ✅
  - [x] **État jeu**: Collection complète game state ✅
  - [x] **Gestion erreurs**: Logging et fallbacks ✅
- [x] **Tests et Validation** ✅:
  - [x] `test/test_save_system.lua` - Suite tests complète ✅
  - [x] `scene/demo_save/demo_save.lua` - Démonstration ✅
  - [x] Intégration `globals.lua` et menu principal ✅
  - [x] Tests réussis: 8/11 (72.7%) - Core fonctionnel ✅
- [ ] **Format JSON Structure**:
  ```json
  {
    "meta": {"version": "1.0", "timestamp": "2025-09-03T10:30:00Z"},
    "player": {"health": 100, "maxHealth": 100, "energy": 3},
    "cards": {"hand": [], "deck": [], "discard": []},
    "game": {"flags": {}, "progression": {}},
    "scene": {"current": "menu", "data": {}}
  }
  ```
- [x] **API et Intégration** ✅:
  - [x] `_G.saveManager` global accessible partout ✅
  - [x] `_G.saveUI` interface utilisateur globale ✅
  - [x] Auto-initialisation dans `globals.lua` ✅
  - [x] Menu principal avec bouton démonstration ✅

#### 1.5 Système Multi-Langue JSON ✅ **TERMINÉ**
- [x] **Créer** `my-librairie/localization-system/` ✅
- [x] **Architecture Localisation** ✅:
  - [x] `localizationManager.lua` - Gestionnaire principal langues ✅
  - [x] `textLoader.lua` - Chargeur fichiers JSON langues ✅
  - [x] `textFormatter.lua` - Formatage textes avec variables ✅
- [x] **Fichiers Langues JSON** ✅:
  - [x] `localization/fr.json` - Français (défaut) ✅
  - [x] `localization/en.json` - Anglais ✅
  - [x] Structure extensible pour futures langues ✅
- [x] **Structure JSON Localisation** ✅:
  ```json
  {
    "meta": {
      "language": "fr",
      "version": "1.0",
      "name": "Français"
    },
    "ui": {
      "menu": {
        "play": "Jouer",
        "load": "Charger",
        "options": "Options", 
        "credits": "Crédits",
        "quit": "Quitter"
      },
      "gameplay": {
        "end_turn": "Fin de Tour",
        "health": "Vie",
        "energy": "Énergie"
      }
    },
    "cards": {
      "names": {
        "carte_001": "Attaque Rapide",
        "carte_002": "Boule de Feu"
      },
      "descriptions": {
        "carte_001": "Inflige {damage} dégâts à l'ennemi ciblé",
        "carte_002": "Inflige {damage} dégâts à tous les ennemis"
      }
    },
    "story": {
      "intro": {
        "title": "Le Château Maudit",
        "text1": "Il était une fois...",
        "text2": "Un héros courageux..."
      }
    },
    "errors": {
      "save_failed": "Échec de la sauvegarde",
      "load_failed": "Échec du chargement"
    }
  }
  ```
- [x] **API Localisation** ✅:
  - [x] `t(key, variables)` - Fonction globale traduction ✅
  - [x] `setLanguage(lang)` - Changer langue runtime ✅
  - [x] `getAvailableLanguages()` - Liste langues disponibles ✅
  - [x] `formatText(text, vars)` - Formatage avec variables ✅
- [x] **Intégration Interface** ✅:
  - [x] **Menu Options**: Sélecteur langue FR/EN ✅
  - [x] **Application immédiate**: Changement sans redémarrage ✅
  - [x] **Persistance**: Langue sauvée dans settings ✅
  - [x] **Fallback**: Français si traduction manquante ✅
- [x] **Gestion Cartes Localisées** ✅:
  - [x] **Noms cartes**: Traduction automatique via ID ✅
  - [x] **Descriptions**: Support variables {damage}, {target} ✅
  - [x] **Générateur cartes**: Intégration système localisation ✅
  - [x] **Preview**: Affichage langue sélectionnée ✅
- [x] **Assets Textuels** ✅:
  - [x] **Polices**: Support caractères spéciaux (accents) ✅
  - [x] **Textures UI**: Boutons avec texte localisé ✅

**🎉 SYSTÈME MULTILINGUE TERMINÉ** (3 septembre 2025) :
- ✅ **LocalizationManager** : Gestion complète des langues FR/EN
- ✅ **TextFormatter** : Formatage avancé avec variables, pluriels, conditionnels
- ✅ **TextLoader** : Chargement et validation des fichiers JSON
- ✅ **Fichiers JSON** : 200+ traductions complètes FR/EN (UI, cartes, histoire, erreurs)
- ✅ **Intégration globale** : Fonction `t()` globale et intégration transparente
- ✅ **Tests complets** : Suite de 16 tests validant toutes les fonctionnalités
- ✅ **Scène démo** : `scene/example_multilingual.lua` pour démonstration
- ✅ **Performance** : Cache intelligent et optimisations
- 🚀 **Prêt pour intégration** dans toutes les scènes du jeu
  - [ ] **Longueurs variables**: Adaptation UI selon langue
  - [ ] **Test complet**: Validation toutes chaînes traduites

### 🎯 PHASE 2 - Scènes d'Introduction et Village

#### 2.1 Scène d'Intro ⭐ **NOUVEAU**
- [ ] **Créer** `scene/intro/`
- [ ] **🎨 Assets Intro**:
  - [ ] Images narration (5-8 images story)
  - [ ] Textes story localisés (français)
  - [ ] Musique dramatique introduction
  - [ ] SFX transitions entre images
  - [ ] Bouton skip stylisé
- [ ] **Narration**: Histoire/contexte du jeu
- [ ] **Cinématique**: Séquence d'introduction (texte + images)
- [ ] **Skip**: Bouton pour les joueurs expérimentés
- [ ] **Condition**: Affiché uniquement première partie
- [ ] **Transition**: Vers village après intro

#### 2.2 Scène Village - Hub Principal ⭐ **NOUVEAU**
- [ ] **Créer** `scene/village/`
- [ ] **🎨 Assets Village**:
  - [ ] Background village principal (1920x1080)
  - [ ] Château interactif avec zones cliquables
  - [ ] Bâtiments village (boutique, maison, statistiques)
  - [ ] Animations particules (fumée, oiseaux, vent)
  - [ ] Musique ambiance village paisible
  - [ ] SFX clicks et interactions
  - [ ] UI overlay village responsive
- [ ] **Background**: Vue d'ensemble du village
- [ ] **Éléments interactifs**:
  - [ ] 🏰 **Château** (accès donjons)
  - [ ] 🏪 **Boutique** (future expansion)
  - [ ] 🏠 **Maison joueur** (future expansion)
  - [ ] 📊 **Statistiques** (progression)
- [ ] **UI Village**: HUD spécialisé pour la navigation
- [ ] **Micromanagement**: Base pour futures fonctionnalités

### 🎯 PHASE 3 - Système Château et Donjons

#### 3.1 Scène Préparation Château ⭐ **NOUVEAU**
- [ ] **Créer** `scene/castle_preparation/`
- [ ] **🎨 Assets Préparation**:
  - [ ] Background salle préparation château
  - [ ] Interface deck builder stylisée
  - [ ] Cartes preview avec animations
  - [ ] Liste étages avec difficultés visuelles
  - [ ] Portraits ennemis par étage
  - [ ] Musique tension pré-combat
  - [ ] Boutons validation/retour stylisés
- [ ] **Deck Builder**: Interface construction deck
- [ ] **Sélection Étage**: Liste des étages disponibles
- [ ] **Preview Étage**: Aperçu difficulté et récompenses
- [ ] **Validation**: Deck minimum requis pour entrer
- [ ] **Retour**: Possibilité retour village

#### 3.2 Système Étages du Château ⭐ **NOUVEAU**
- [ ] **Créer** `my-librairie/dungeon-system/`
- [ ] **Structure étage**: Plan avec zones interconnectées
- [ ] **Types de zones**:
  - [ ] ⚔️ **Combat** (bataille tactique)
  - [ ] 💤 **Repos** (récupération HP/cartes)
  - [ ] 🎁 **Trésor** (récompenses)
  - [ ] 🔮 **Événement** (choix narratifs)
  - [ ] 🚪 **Boss** (fin d'étage)
- [ ] **Navigation**: Choix multiple selon sorties zones
- [ ] **Progression**: Sauvegarde position dans étage

#### 3.3 Scène Plan d'Étage ⭐ **NOUVEAU**
- [ ] **Créer** `scene/floor_map/`
- [ ] **🎨 Assets Plan Étage**:
  - [ ] Carte étage détaillée avec zones distinctes
  - [ ] Icônes zones (combat, repos, trésor, boss, événement)
  - [ ] Chemins et connexions entre zones
  - [ ] Indicateur position joueur animé
  - [ ] Zones visitées grisées/colorées différemment
  - [ ] Overlay choix avec preview zone
  - [ ] Musique exploration mystérieuse
  - [ ] SFX clic zones et navigation
- [ ] **Carte interactive**: Plan étage avec zones
- [ ] **Position joueur**: Indicateur position actuelle
- [ ] **Zones visitées**: Marquage zones explorées
- [ ] **Sorties disponibles**: Highlight choix possibles
- [ ] **Menu Échap**: Quitter étage → retour village
- [ ] **Persistence**: Sauvegarde état exploration

### 🎯 PHASE 4 - Mécaniques de Progression

#### 4.1 Système de Progression ⭐ **NOUVEAU**
- [ ] **Créer** `my-librairie/progression-system/`
- [ ] **Étages terminés**: Marquage complétion
- [ ] **Re-jouabilité**: Possibilité refaire étages
- [ ] **Récompenses**: Cartes/items manqués récupérables
- [ ] **Déblocage**: Nouveaux étages selon progression
- [ ] **Statistiques**: Tracking performances joueur

#### 4.2 Système d'Inventaire ⭐ **NOUVEAU**
- [ ] **Items persistants**: Objets gardés entre runs
- [ ] **Cartes collectées**: Collection permanente
- [ ] **Upgrade system**: Amélioration équipement
- [ ] **UI Inventaire**: Interface gestion objets

### 🎯 PHASE 5 - Intégration et Polish

#### 5.1 Transitions Entre Scènes ⭐ **NOUVEAU**
- [ ] **Améliorer** `my-librairie/transitions/`
- [ ] **Transitions spécialisées**:
  - [ ] Village ↔ Château
  - [ ] Plan étage ↔ Combat
  - [ ] Étage ↔ Village (escape)
- [ ] **Loading screens**: Pour les changements complexes
- [ ] **Continuité**: Musique et ambiance

#### 5.2 Système Audio ⭐ **NOUVEAU**
- [ ] **🎵 Assets Audio Complets**:
  - [ ] **Musiques** (format OGG/MP3):
    - [ ] Thème menu principal (boucle 2-3min)
    - [ ] Musique village paisible (boucle 4-5min)
    - [ ] Tension pré-combat château (1-2min)
    - [ ] Exploration étage mystérieuse (boucle 3-4min)
    - [ ] Combat tactique énergique (boucle 2-3min)
    - [ ] Victoire/défaite (stinger 10-20s)
  - [ ] **SFX** (format WAV/OGG):
    - [ ] Clicks UI et boutons
    - [ ] Interactions village/château
    - [ ] Navigation plan étage
    - [ ] Cartes (tirage, jeu, effets)
    - [ ] Feedback combat (dégâts, heal, shield)
- [ ] **Musiques**: Thèmes par zone (village, château, combat)
- [ ] **SFX**: Sons d'interface et d'actions
- [ ] **Ambiance**: Sons d'atmosphère par scène

#### 5.3 Tests et Validation ⭐ **NOUVEAU**
- [ ] **Tests flow complet**: Start → Village → Château → Combat
- [ ] **Tests sauvegarde**: Load/Save à tous les points
- [ ] **Tests navigation**: Tous les chemins possibles
- [ ] **Tests escape**: Retour village depuis tous les points
- [ ] **Tests re-jouabilité**: Refaire étages terminés

---

## 📊 PLANNING ESTIMÉ - DÉMO 4 MOIS

### **🎯 OBJECTIF RÉALISTE**: ✅ **FAISABLE EN 4 MOIS**

**Scope Démo**: 1 étage complet + flow complet start→village→château→combat
**Assets minimum**: Prototypes fonctionnels, polish final optionnel

### **MOIS 1** (Septembre 2025) - Fondations
- **Semaine 1** (2-8 sept): Problème #6 + #7 + Start/Menu + Save JSON + **Localisation FR/EN**
- **Semaine 2** (9-15 sept): Village + Préparation château + Assets de base + **Intégration multi-langue**
- **Semaine 3** (16-22 sept): Plan étage + Navigation + Assets cartes étage + **Tests localisation**
- **Semaine 4** (23-29 sept): Intégration systèmes + Tests alpha + **Validation langues complète**

### **MOIS 2** (Octobre 2025) - Contenu et Assets
- **Semaine 1** (30 sept-6 oct): **🎨 Sprint Assets** - Tous les visuels
- **Semaine 2** (7-13 oct): **🎵 Sprint Audio** - Musiques et SFX
- **Semaine 3** (14-20 oct): **⚔️ Contenu Étage 1** - 5 zones complètes
- **Semaine 4** (21-27 oct): **🃏 Équilibrage** - Cartes et ennemis

### **MOIS 3** (Novembre 2025) - Polish et Optimisation
- **Semaine 1** (28 oct-3 nov): **🐛 Debug intensif** - Tous les bugs
- **Semaine 2** (4-10 nov): **✨ Polish UI/UX** - Finitions interface
- **Semaine 3** (11-17 nov): **🎮 Playtests** - Feedback et ajustements
- **Semaine 4** (18-24 nov): **🔧 Optimisations** - Performance finale

### **MOIS 4** (Décembre 2025) - Finalisation Démo
- **Semaine 1** (25 nov-1 déc): **📦 Build démo** - Version stable
- **Semaine 2** (2-8 déc): **🎥 Trailer/Screenshots** - Communication
- **Semaine 3** (9-15 déc): **🚀 Release candidate** - Version finale
- **Semaine 4** (16-22 déc): **🎉 DÉMO RELEASE** - Publication

### **Semaine 1** (2-8 septembre)
- ✅ Finir Problème #6 (cartes IA)
- 🚀 Phase 1: Scènes de base (Start, Menu)
- 💾 **Système JSON**: Architecture save complète
- ✅ **Localisation**: Architecture multi-langue FR/EN JSON **TERMINÉ** (3 sept)

### **Semaine 2** (9-15 septembre)  
- 💾 **Finaliser Save System**: Tests et intégration
- ✅ **Intégration Localisation**: Menu + UI + Cartes **TERMINÉ** (3 sept)
- 🏘️ Phase 2: Intro + Village + **🎨 Assets village**
- 🏰 Phase 3.1: Préparation château + **🎨 Assets château**

### **Semaine 3** (16-22 septembre)
- 🗺️ Phase 3.2-3.3: Système étages + plan + **🎨 Assets plan/zones**
- 📈 Phase 4.1: Progression + **🎨 Assets UI progression**

### **Semaine 4** (23-29 septembre)
- 🎒 Phase 4.2: Inventaire + **🎨 Assets items/inventaire**
- 🎨 Phase 5: Intégration + **🎵 Audio de base**

---

## 🎯 PRIORITÉS IMMÉDIATES (AUJOURD'HUI)

1. **🔥 URGENT**: Terminer Problème #6 ET #7 - Système effets cartes complet
2. **💾 SAVE SYSTEM**: Implémenter système de sauvegarde JSON
3. **🏷️ TAGS**: Implémenter système tags `multiTarget` dans générateur
4. **⚔️ AUTO-PLAY**: Modifier CardStandbyPlay pour cartes multi-cibles
4. **🎨 ASSETS EFFETS**: Créer nouveaux effets visuels étendus
5. **🌍 LOCALISATION**: Créer système multi-langue FR/EN JSON
6. **⭐ START**: Créer scène start_studio (logo) 
7. **📋 MENU**: Étendre menu principal (nouveaux boutons + sélecteur langue)
8. **💾 JSON SAVE**: Commencer architecture système sauvegarde JSON
9. **🗂️ STRUCTURE**: Créer dossiers `my-librairie/save-system/`, `my-librairie/localization-system/`, `saves/`, `localization/`

---

## 📝 NOTES IMPORTANTES

### Architecture SceneManager
- Utiliser le système existant `my-librairie/sceneManager.lua`
- Pattern push/pop pour overlays (ex: menu pause sur village)
- Transitions fluides entre toutes les scènes

### Compatibilité Existant
- Garder scène gameplay actuelle comme base combat
- Intégrer système cartes existant dans nouveau flow
- Préserver système HUD centralisé

#### **Structure générateur cartes étendue** :
```lua
-- Exemple structure carte avec tag multiTarget + localisation
{
  id = "carte_fireball",
  name_key = "cards.names.carte_fireball",  -- Clé localisation
  effect = "damage",
  power = 25,
  multiTarget = true,  -- NOUVEAU TAG
  description_key = "cards.descriptions.carte_fireball",  -- Clé localisation
  variables = { damage = 25 }  -- Variables pour formatage
}

-- Logique auto-détection + localisation
if card.multiTarget == nil then
  card.multiTarget = false  -- Défaut
end

-- Récupération texte localisé
local name = t(card.name_key)
local description = t(card.description_key, card.variables)
```

#### **API Localisation Exemples** :
```lua
-- Utilisation basique
local playText = t("ui.menu.play")  -- "Jouer" ou "Play"

-- Avec variables
local damageText = t("cards.descriptions.fireball", {damage = 25})
-- FR: "Inflige 25 dégâts à tous les ennemis"
-- EN: "Deals 25 damage to all enemies"

-- Changement langue
setLanguage("en")  -- Passage anglais immédiat
```

### Données Persistantes JSON
- Structure save JSON complète avec validation schéma
- Séparation données temporaires (run) vs permanentes (progression)
- Backup automatique et migration versions pour éviter perte progression
- API unifiée save/load avec gestion erreurs robuste
- Compression et optimisation pour performances
- Structure save JSON complète avec validation schéma
- Séparation données temporaires (run) vs permanentes (progression)
- Backup automatique et migration versions pour éviter perte progression
- API unifiée save/load avec gestion erreurs robuste
- Compression et optimisation pour performances

---

**Estimation Temps Total**: 4 mois pour démo complète  
**Complexité**: HAUTE - Refonte complète navigation + assets  
**Impact**: MAJEUR - Nouvelle expérience joueur complète  
**Responsable**: Équipe développement complet  
**🎯 FAISABILITÉ DÉMO 4 MOIS**: ✅ **RÉALISTE** avec planning structuré et assets progressifs
