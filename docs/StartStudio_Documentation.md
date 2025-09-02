# Documentation - Scène Start Studio

## Vue d'ensemble
La scène `start_studio` est la première scène du jeu qui affiche le logo du studio de développement pendant quelques secondes avant de passer automatiquement au menu principal.

## Architecture

### Fichiers
- **Scène** : `scene/start_studio/start_studio.lua`
- **Logo** : `img/logoStudio/Sans titre-1.png`
- **Audio** : `audio/startup.ogg` (optionnel)

### Intégration
- Ajoutée dans `main.lua` avec `scene:add(scene_start_studio)`
- Démarrée automatiquement avec `scene:switch("start_studio")`
- Transition automatique vers le menu via `scene:switch("menu")`

## Fonctionnalités

### Timing et Phases
- **DISPLAY_DURATION** : 4.0 secondes d'affichage total
- **FADE_IN_DURATION** : 0.8 secondes de fade in
- **FADE_OUT_DURATION** : 0.6 secondes de fade out

### Phases d'exécution
1. **"fade_in"** : Apparition progressive du logo (0.8s)
2. **"display"** : Affichage statique du logo (4.0s)
3. **"fade_out"** : Disparition progressive du logo (0.6s)
4. **"transition"** : Transition vers le menu principal

### Contrôles Skip
Toutes ces actions permettent de passer immédiatement au menu :
- **Clavier** : Space, Return, Escape, Z, X
- **Souris** : Clic gauche n'importe où
- **Gamepad** : N'importe quel bouton

### Rendu
- **Fond noir** : Écran propre pour mise en valeur du logo
- **Logo centré** : Position automatiquement calculée selon résolution
- **Alpha progressive** : Fade in/out fluide avec interpolation
- **Indication skip** : Texte "Press any key to skip" en bas à droite

## Lifecycle LÖVE2D

### Méthodes implémentées
- **`load()`** : Chargement du logo et son optionnel
- **`enter(previous)`** : Entrée dans la scène, lecture du son
- **`update(dt)`** : Gestion des phases et timer
- **`draw()`** : Rendu du logo avec alpha et indication skip
- **`leave(next)`** : Sortie de la scène, arrêt du son
- **`unload()`** : Libération des ressources
- **`pause()`** / **`resume()`** : Gestion pause/reprise

### Gestion des entrées
- **`keypressed(key, scancode, isrepeat)`** : Skip clavier
- **`mousepressed(x, y, button, istouch, presses)`** : Skip souris
- **`gamepadpressed(joystick, button)`** : Skip gamepad

## Configuration

### Assets requis
```
img/logoStudio/Sans titre-1.png  # Logo du studio (obligatoire)
audio/startup.ogg                # Son de démarrage (optionnel)
```

### Personnalisation
```lua
-- Durées modifiables dans start_studio.lua
DISPLAY_DURATION = 4.0   -- Temps d'affichage total
FADE_IN_DURATION = 0.8   -- Durée fade in
FADE_OUT_DURATION = 0.6  -- Durée fade out
```

## Logging
Toutes les actions importantes sont loggées via `globalFunction.log` :
- Chargement des assets
- Phases de transition
- Demandes de skip
- Erreurs potentielles

## Responsive Design
- **Position automatique** : Logo centré quelque soit la résolution
- **Texte adaptatif** : Indication skip positionnée responsive
- **Gestion d'erreurs** : Fonctionne même si logo absent

## Utilisation

### Démarrage automatique
La scène se lance automatiquement au démarrage du jeu grâce à la configuration dans `main.lua`.

### Test indépendant
```lua
-- Pour tester la scène directement
scene:switch("start_studio")
```

### Intégration dans le flow
```
Démarrage → start_studio (4s + fade) → menu → reste du jeu
```

## Extensibilité future

### Audio
- Support intégré pour `audio/startup.ogg`
- Volume et pitch configurables
- Fade audio synchronisé avec fade visuel

### Effets visuels
- Particules ou effets additionnels faciles à ajouter
- Support pour animations plus complexes
- Transition personnalisable vers menu

### Localisation
- Texte skip déjà préparé pour traduction
- Support multi-langue via système de localisation existant

---

**Date de création** : 3 septembre 2025  
**Status** : ✅ Terminé et fonctionnel  
**Prochaine étape** : Amélioration du menu principal (section 1.3)
