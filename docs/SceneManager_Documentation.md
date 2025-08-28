# SceneManager Documentation - LÖVE2D Game Framework

## Table des Matières
1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [API Principale](#api-principale)
4. [Lifecycle des Scènes](#lifecycle-des-scènes)
5. [Event Dispatching](#event-dispatching)
6. [Patterns d'Usage](#patterns-dusage)
7. [Mode StackMode](#mode-stackmode)
8. [Debug & Logging](#debug--logging)
9. [Exemples Pratiques](#exemples-pratiques)
10. [Best Practices](#best-practices)

## Vue d'ensemble

Le SceneManager (`my-librairie/sceneManager.lua`) est le système central de gestion des scènes pour ce jeu LÖVE2D. Il fournit une architecture robuste basée sur une pile (stack) avec un lifecycle complet et un système d'events automatique.

### Caractéristiques principales
- **Pile de scènes** : Stack avec push/pop pour navigation et overlays
- **Lifecycle complet** : load → enter → update/draw → pause/resume → leave → unload
- **Event dispatching** : Propagation automatique des événements LÖVE2D
- **Deux modes** : `stackMode=false` (broadcast) / `stackMode=true` (top-only)
- **Require flexible** : Fallback automatique point/slash pour compatibilité
- **Debug intégré** : Logs détaillés dans `gameLogs/` pour diagnostic

## Architecture

### Structure de la pile
```
Index 3: overlay_pause     ← Sommet (scène active)
Index 2: overlay_start     
Index 1: scene_gameplay    ← Base
```

### Modes de fonctionnement
```lua
-- Mode diffusion (défaut) - toutes les scènes reçoivent update/draw/events
scene.stackMode = false  

-- Mode pile strict - seule la scène au sommet est active
scene.stackMode = true   
```

## API Principale

### Gestion de pile

```lua
-- Empile une nouvelle scène au-dessus
scene:push("scene.gameplay.gameplay")          

-- Retire n scènes du sommet (défaut: 1)
scene:pop(2)                                   

-- Remplace toute la pile par une nouvelle scène
scene:switch("scene.menu.menu")                

-- Vide la pile complètement
scene:clear()                                  
```

### Navigation avancée

```lua
-- Transition avec effet visuel
scene:switchWithTransition(target, params, transitionOpts)  

-- Retourne la scène au sommet
local topScene = scene:top()                   

-- Nombre de scènes dans la pile
local count = scene:count()                    

-- Retourne la table des scènes
local sceneList = scene:get()                  
```

### Cycle de vie (appelés automatiquement)

```lua
-- Bootstrap depuis love.load
scene:load()        

-- Update loop depuis love.update
scene:update(dt)    

-- Rendu depuis love.draw
scene:draw()        

-- Event dispatching
scene:mousepressed(x, y, button)
scene:keypressed(key, scancode, isrepeat)
scene:emit("custom_event", params)
```

## Lifecycle des Scènes

### Structure standard d'une scène

```lua
-- Structure minimale obligatoire
local myScene = { name = "my_scene" }

-- Lifecycle complet (toutes optionnelles sauf name)
function myScene.load(self)      -- Chargement initial (une fois)
    -- Initialisation des ressources, chargement des assets
end

function myScene.enter(self)     -- Entrée sur la pile (peut être multiple)
    -- Setup spécifique à chaque entrée
end

function myScene.update(self, dt) -- Update loop (si scène active)
    -- Logique de mise à jour
end

function myScene.draw(self)      -- Rendu (selon stackMode)
    -- Rendu de la scène
end

function myScene.pause(self)     -- Pause quand autre scène empilée dessus
    -- Pause des animations, sauvegarde d'état
end

function myScene.resume(self)    -- Reprise quand scène au-dessus supprimée
    -- Reprise des animations, restauration d'état
end

function myScene.leave(self)     -- Sortie de la pile
    -- Nettoyage temporaire
end

function myScene.unload(self)    -- Nettoyage final (destructeur)
    -- Libération des ressources
end

-- Events LÖVE2D (optionnels)
function myScene.mousepressed(self, x, y, button)
    -- Gestion des clics souris
    return true  -- true = event consommé, arrêt propagation
end

function myScene.keypressed(self, key, scancode, isrepeat)
    -- Gestion des touches clavier
end

function myScene.mousemoved(self, x, y, dx, dy, istouch)
    -- Gestion du mouvement souris
end

return myScene
```

### Ordre d'appel typique

```
1. scene:push("my_scene")
   → myScene.load()
   → myScene.enter()

2. Pendant l'exécution
   → myScene.update(dt)  [chaque frame]
   → myScene.draw()      [chaque frame]

3. Autre scène pushée par-dessus
   → myScene.pause()

4. Scène au-dessus poppée
   → myScene.resume()

5. scene:pop()
   → myScene.leave()
   → myScene.unload()
```

## Event Dispatching

### Dispatch automatique

```lua
-- Depuis main.lua
function love.mousepressed(x, y, button, istouch, presses)
    scene:mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
    scene:keypressed(key, scancode, isrepeat)
end
```

### Events personnalisés

```lua
-- Émission d'event custom
scene:emit("player_died", { reason = "fall", score = 1500 })

-- Dans la scène qui reçoit
function myScene.player_died(self, data)
    print("Player died:", data.reason, "Score:", data.score)
    return true  -- Event consommé
end
```

### Propagation intelligente

```lua
-- stackMode=false : broadcast à toutes les scènes (z-order inversé)
-- L'event est envoyé à toutes les scènes, en commençant par le sommet

-- stackMode=true : seule la scène au sommet reçoit l'event
-- Plus efficace pour les overlays modaux
```

## Patterns d'Usage

### Menu principal → Gameplay

```lua
-- Remplacement complet de la pile
scene:switch("scene.gameplay.gameplay")
```

### Overlay temporaire (pause, options)

```lua
-- Ajout par-dessus gameplay
scene:push("scene.overlay.pause")     

-- Utilisateur interagit avec pause menu...

-- Retour au gameplay
scene:pop()                           
```

### Séquence d'overlays complexe

```lua
-- Combat start → initiative → reward
scene:push("scene.overlay_start.overlay_start")     

-- Continue cliqué → transition propre
scene:pop()                                         -- Supprime start
scene:push("scene.overlay_initiative.overlay_initiative")  -- Affiche initiative

-- Initiative terminée → reward
scene:pop()                                         -- Supprime initiative  
scene:push("scene.overlay_reward.overlay_reward")  -- Affiche reward
```

### Debug de la pile

```lua
-- Affichage de l'état actuel
for i, sc in ipairs(scene:get()) do
    print(i, sc.name or "unnamed")
end

-- Output exemple:
-- 1    scene_gameplay
-- 2    overlay_start  
-- 3    overlay_initiative
```

## Mode StackMode

### Mode diffusion (stackMode=false) - Défaut

```lua
scene.stackMode = false
```

**Comportement** :
- Toutes les scènes reçoivent `update()`, `draw()`, et les events
- Rendu en ordre de pile (base → sommet)
- Events propagés du sommet vers la base

**Utilisation** :
- Backgrounds persistants
- UI qui reste visible sous les overlays
- Overlays multiples simultanés
- Effets de parallaxe

### Mode pile strict (stackMode=true)

```lua
scene.stackMode = true
```

**Comportement** :
- Seule la scène au sommet reçoit `update()`, `draw()`, et les events
- Plus performant (moins d'appels)
- Overlays complètement modaux

**Utilisation** :
- Dialogs modaux
- Overlays exclusifs (pause game)
- Menus full-screen
- Systèmes de pause complets

## Debug & Logging

### Activation du debug

```lua
scene.debug = true  -- Active les logs de navigation
```

### Logs automatiques

```
[sceneManager] push → overlay_start
[sceneManager] pop → gameplay  
[sceneManager] switch → scene.menu.menu
[sceneManager] scene.draw error in scene 'broken_scene': attempt to call nil
```

### Logs dans gameLogs/

- **hud_clicks.log** : Dispatches de clics souris avec coordonnées
- **scene_list.log** : État de la pile (dump manuel)
- **game_logs_*.log** : Logs généraux avec timestamps

### Debug helpers

```lua
-- Logs détaillés de pop/push
scene:pop(2)  
-- Output:
-- [sceneManager] pop() appelé avec count=2 - stack size avant: 4
-- [sceneManager] Suppression scene overlay_reward - iteration 1
-- [sceneManager] Suppression scene overlay_initiative - iteration 2  
-- [sceneManager] Nouvelle top scene: overlay_start
-- [sceneManager] pop() terminé - stack size final: 2
```

## Exemples Pratiques

### 1. Scène de gameplay basique

```lua
-- scene/gameplay/gameplay.lua
local gameplay = { name = "gameplay" }

function gameplay.load(self)
    -- Chargement des cartes, initialisation du combat
    Card.loadCards()
    Hero:init()
end

function gameplay.enter(self)
    -- Reset pour chaque entrée
    self.timer = 0
    self.turn = "player"
end

function gameplay.update(self, dt)
    dt = globalFunction.clampDt(dt)
    self.timer = self.timer + dt
    
    -- Update logique de jeu
    if Card then Card.update(dt) end
    if Hero then Hero.update(dt) end
end

function gameplay.draw(self)
    -- Rendu du plateau de jeu
    love.graphics.setColor(1, 1, 1, 1)
    -- ... rendu ...
end

function gameplay.mousepressed(self, x, y, button)
    -- Gestion des clics sur les cartes
    if Card and Card.handleClick then
        return Card.handleClick(x, y, button)
    end
    return false
end

return gameplay
```

### 2. Overlay modal simple

```lua
-- scene/overlay/pause.lua
local pause = { name = "pause_overlay" }

function pause.load(self)
    -- Chargement du HUD de pause
    hud.clear()
    hud.addButton("resume", "button", {x=400, y=300}, 200, 50, 
        function() scene:pop() end)
    hud.addButton("menu", "button", {x=400, y=400}, 200, 50,
        function() scene:switch("scene.menu.menu") end)
end

function pause.draw(self)
    -- Background semi-transparent
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- HUD par-dessus
    hud.draw()
end

function pause.keypressed(self, key)
    if key == "escape" then
        scene:pop()  -- Ferme la pause
        return true
    end
    return false
end

return pause
```

### 3. Transition complexe d'overlays

```lua
-- Dans templateCombatTransition.lua
function CombatFlow:startEncounter()
    -- Nettoyage propre de la pile avant transition
    if SceneManager and SceneManager.pop then
        -- Pop tous les overlays jusqu'à la scène de base
        while SceneManager.list and #SceneManager.list > 1 do
            local topScene = SceneManager.list[#SceneManager.list]
            if topScene and topScene.name and not topScene.name:find("overlay") then
                break  -- On a atteint la scène de base
            end
            logT("Cleaning overlay: " .. tostring(topScene.name))
            SceneManager:pop()
        end
    end
    
    -- Push overlay_start sur une pile propre
    SceneManager:push("scene.overlay_start.overlay_start")
    changeState("overlay_start")
end
```

## Best Practices

### Structure des fichiers

```
scene/
  menu/
    menu.lua              ← { name = "menu" }
  gameplay/
    gameplay.lua          ← { name = "gameplay" }
    HUD/
      hud_gameplay.lua
  overlay/
    pause.lua             ← { name = "pause_overlay" }
  overlay_start/
    overlay_start.lua     ← { name = "overlay_start" }
    HUD/
      hud_overlay_start.lua
```

### Conventions de nommage

```lua
-- ✅ BIEN : Name obligatoire et descriptif
local myScene = { name = "gameplay_combat" }

-- ❌ ÉVITER : Pas de name
local myScene = {}

-- ✅ BIEN : Chemins explicites
scene:push("scene.overlay.pause")
scene:push("scene/overlay/pause")  -- Auto-fallback

-- ❌ ÉVITER : Chemins relatifs
scene:push("pause")
```

### Gestion d'erreurs

```lua
function myScene.update(self, dt)
    -- ✅ BIEN : Protection contre dt invalide
    dt = globalFunction.clampDt(dt)
    
    -- ✅ BIEN : Vérification des dépendances
    if Card and Card.update then
        local ok, err = pcall(Card.update, dt)
        if not ok then
            print("Card update error:", err)
        end
    end
end

function myScene.mousepressed(self, x, y, button)
    -- ✅ BIEN : Retourner true si event consommé
    if self:handleClick(x, y) then
        return true  -- Arrête la propagation
    end
    return false  -- Continue la propagation
end
```

### Performance

```lua
-- ✅ BIEN : Vérifier count avant opérations lourdes
if scene:count() > 5 then
    print("Warning: Stack getting deep")
end

-- ✅ BIEN : Utiliser stackMode=true pour overlays modaux
scene.stackMode = true
scene:push("modal_dialog")

-- ✅ BIEN : Cleanup dans unload
function myScene.unload(self)
    if self.resources then
        for _, resource in ipairs(self.resources) do
            resource:release()
        end
        self.resources = nil
    end
end
```

### Debug

```lua
-- ✅ BIEN : Logs informatifs
function myScene.enter(self)
    if scene.debug then
        print("[" .. self.name .. "] entering with data:", globalFunction.tstr(self.data))
    end
end

-- ✅ BIEN : Validation des transitions
function myScene.leave(self)
    if self.hasUnsavedChanges then
        print("Warning: leaving scene with unsaved changes")
    end
end
```

---

## Support & Débogage

Si vous rencontrez des problèmes avec le SceneManager :

1. **Activez le debug** : `scene.debug = true`
2. **Vérifiez les logs** dans `gameLogs/`
3. **Inspectez la pile** : `scene:get()` et `scene:count()`
4. **Vérifiez les noms** : Toutes les scènes doivent avoir un `name`
5. **Testez le lifecycle** : Implémentez tous les hooks nécessaires

Pour plus d'informations, consultez le code source dans `my-librairie/sceneManager.lua`.
