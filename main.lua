-- Point d'entrée du jeu LÖVE2D
-- Activation du débogueur si argument passé
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

-- ***********Configuration de la Fenêtre de Jeu*************
love.window.setTitle("Tactique Cards")

-- Chargement centralisé de toutes les globales AVANT tout require de scène
local globales = require("my-librairie.core.globals")

-- Modules locaux (non-globaux) - chargés APRÈS les globales
local scene_menu = require("scene.menu.menu")

-- Calcule la distance euclidienne entre deux points
---
-- Fonction utilitaire pour calculer la distance entre deux points.
-- @param x1 number Coordonnée X du premier point
-- @param y1 number Coordonnée Y du premier point
-- @param x2 number Coordonnée X du deuxième point
-- @param y2 number Coordonnée Y du deuxième point
-- @return number La distance calculée
function math.dist(x1, y1, x2, y2)
  return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- VARIABLES GLOBALES ET LOCALES
-- Couleur par défaut de l'écran (sauvegardée pour restauration)
_G.Couleur_defaut = love.graphics.getColor()

-- INITIALISATION DU JEU
---
-- Fonction appelée au démarrage pour initialiser les ressources et l'état du jeu.
-- Gère la création du dossier de logs, l'ajout de la scène menu et le chargement initial.
-- @return nil
function love.load()
  -- Assurer qu'un dossier pour les logs runtime existe pour éviter les échecs silencieux
  pcall(function()
    local lfs_disponible = pcall(require, 'lfs') -- Préférer lfs si disponible
    -- Essayer un fallback basique Lua I/O pour créer le répertoire sur Windows
    local creation_reussie = pcall(function()
      -- Sur Windows, mkdir via os.execute peut être disponible ; essayer une approche portable
      if package.config:sub(1, 1) == '\\' then
        os.execute('if not exist "gameLogs" mkdir "gameLogs"')
      else
        os.execute('mkdir -p gameLogs')
      end
    end)
  end)

  -- Log d'initialisation
  globalFunction.log.info("[main.lua] love.load() appelé - début initialisation")

  -- Ajout de la scène menu au gestionnaire de scènes
  globalFunction.log.info("[main.lua] Ajout de la scène menu")
  scene:add(scene_menu) -- Utilisation de deux-points pour la méthode

  -- Chargement des scènes
  globalFunction.log.info("[main.lua] Appel de scene:load()")
  scene:load() -- Pas besoin de dt ici

  globalFunction.log.info("[main.lua] love.load() terminé")

  -- Chargement du HUD centralisé avec gestion d'erreur
  globalFunction.safecall(function()
    if _G.hud and _G.hud.load then
      _G.hud.load()
    end
  end)
end

-- MISE À JOUR DU JEU À CHAQUE FRAME
---
-- Fonction appelée à chaque frame pour mettre à jour la logique du jeu.
-- Gère les mises à jour des scènes, transitions, effets et HUD.
-- @param dt number Temps écoulé depuis la dernière frame (delta time)
-- @return nil
function love.update(dt)
  -- Stockage du delta time dans une globale pour accès facile
  _G.deltaTime = dt
  -- Mise à jour du ratio d'écran
  screen.UpdateRatio(dt)
  -- Mise à jour du gestionnaire d'entrée si disponible
  if inputManager and inputManager.update then inputManager.update(dt) end
  -- Mise à jour des scènes seulement si les transitions ne masquent pas l'entrée
  if not Transition.maskInput() then scene:update(dt) end -- else: scènes non mises à jour
  -- Mise à jour des transitions
  Transition.update(dt)
  -- Mise à jour des effets
  effect.update(dt)
  -- Mise à jour de la carte en attente de sélection (CardStandbyPlay)
  globalFunction.safecall(function()
    if _G.CardStandbyPlay and _G.CardStandbyPlay.update then
      _G.CardStandbyPlay.update(dt)
    end
  end)
  -- Mise à jour du HUD centralisé
  globalFunction.safecall(function()
    if _G.hud and _G.hud.update then
      _G.hud.update(dt)
    end
  end)
end

-- RENDU À L'ÉCRAN
---
-- Fonction appelée à chaque frame pour dessiner le jeu à l'écran.
-- Gère le rendu des scènes, transitions, effets et HUD.
-- @return nil
function love.draw()
  -- Sauvegarde de la matrice de transformation
  love.graphics.push()
  -- Application du ratio d'écran
  love.graphics.scale(screen.ratioScreen.width, screen.ratioScreen.height)
  -- Rendu des scènes
  scene:draw()
  -- Rendu des transitions
  Transition.draw()
  -- Rendu de la carte en attente de sélection (CardStandbyPlay)
  globalFunction.safecall(function()
    if _G.CardStandbyPlay and _G.CardStandbyPlay.draw then
      _G.CardStandbyPlay.draw()
    end
  end)

  -- Affichage du panneau de logs global si activé
  local fonctions_globales = _G.globalFunction or _G.myFunction or _G.myFonction
  if type(fonctions_globales) == 'table' and type(fonctions_globales.drawLogs) == 'function' then
    fonctions_globales.drawLogs()
  end
  -- Rendu des effets
  effect.draw()
  -- Affichage des FPS pour débogage
  love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
  -- Rendu du HUD centralisé
  if _G.hud and type(_G.hud.draw) == 'function' then
    _G.hud.draw()
  end
  -- Restauration de la matrice de transformation
  love.graphics.pop()
end

-- GESTION DES ÉVÉNEMENTS SOURIS
---
-- Fonction appelée lorsqu'un bouton de souris est pressé.
-- Gère les clics sur CardStandbyPlay et propage aux scènes si nécessaire.
-- @param x number Coordonnée X du clic
-- @param y number Coordonnée Y du clic
-- @param bouton number Numéro du bouton pressé
-- @return nil
function love.mousepressed(x, y, bouton)
  -- Log du clic pour débogage
  pcall(function()
    local fichier_log = io.open("gameLogs/hud_clicks.log", "a")
    if fichier_log then
      fichier_log:write(os.date("%Y-%m-%d %H:%M:%S") ..
        " - love.mousepressed -> window_coords=" ..
        tostring(x) .. "," .. tostring(y) .. " button=" .. tostring(bouton) .. "\n")
      fichier_log:close()
    end
  end)

  -- Vérifier d'abord CardStandbyPlay pour gestion des annulations
  if _G.CardStandbyPlay and _G.CardStandbyPlay.handleClick then
    local gere = _G.CardStandbyPlay.handleClick(x, y, bouton)
    if gere then
      globalFunction.log.info(string.format("[main] Clic géré par CardStandbyPlay: (%d,%d) button=%d", x, y, bouton))
      return -- Arrêter la propagation si géré
    end
  end

  -- DÉSACTIVÉ: Le HUD doit être géré par les scènes, pas directement par main.lua
  -- Le design correct: main.lua fait hud.update() pour le hover, les scènes font hud.hover("click")
  --[[
  -- Vérifier le HUD global AVANT les scènes
  if _G.hud and _G.hud.hover then
    local gere_par_hud = _G.hud.hover("click", x, y)
    pcall(function()
      local fichier_log = io.open("gameLogs/hud_clicks.log", "a")
      if fichier_log then
        fichier_log:write(os.date("%Y-%m-%d %H:%M:%S") ..
          " - HUD appelé, résultat: " .. tostring(gere_par_hud) .. "\n")
        fichier_log:close()
      end
    end)
    if gere_par_hud then
      return -- Arrêter la propagation si le HUD a géré le clic
    end
  end
  --]]

  -- Propager aux scènes seulement si pas géré par CardStandbyPlay ou HUD
  scene:emit("mousepressed", x, y, bouton)
end

---
-- Fonction appelée lorsqu'un bouton de souris est relâché.
-- Propage l'événement aux scènes.
-- @param x number Coordonnée X du relâchement
-- @param y number Coordonnée Y du relâchement
-- @param bouton number Numéro du bouton relâché
-- @return nil
function love.mousereleased(x, y, bouton)
  scene:emit("mousereleased", x, y, bouton)
end

-- GESTION DES ÉVÉNEMENTS CLAVIER
---
-- Fonction appelée lorsqu'une touche est pressée.
-- Gère les raccourcis (F12 pour logs, T pour test) et propage aux scènes.
-- @param touche string La touche pressée
-- @param scancode string Le scancode de la touche
-- @param repetition boolean Si c'est une répétition
-- @return nil
function love.keypressed(touche, scancode, repetition)
  -- Basculer les logs globaux avec F12 si disponible
  if touche == "f12" then
    local fonctions_globales = _G.globalFunction or _G.myFunction or _G.myFonction
    if type(fonctions_globales) == 'table' and type(fonctions_globales.log) == 'table' and type(fonctions_globales.log.toggle) == 'function' then
      fonctions_globales.log.toggle()
    end
  end
  -- Debug: appuyer sur 't' pour tester la transition vers gameplay
  if touche == 't' then
    pcall(function()
      local chargement_reussi, script_focus = pcall(require, 'my-librairie.transitions.focus')
      if chargement_reussi and script_focus then
        scene:switchWithTransition('scene.gameplay.gameplay', nil, { script = script_focus })
      else
        scene:switchWithTransition('scene.gameplay.gameplay')
      end
    end)
    return
  end
  -- Ne pas propager si les transitions masquent l'entrée
  if Transition.maskInput() then return end
  scene:emit("keypressed", touche, scancode, repetition)
end

-- FERMETURE DU JEU
---
-- Fonction appelée à la fermeture du jeu.
-- Exporte les logs si possible.
-- @return nil
function love.quit()
  local fonctions_globales = _G.globalFunction or _G.myFunction or _G.myFonction
  if type(fonctions_globales) == 'table' and type(fonctions_globales.log) == 'table' and type(fonctions_globales.log.exportToFile) == 'function' then
    pcall(function() fonctions_globales.log.exportToFile() end)
  end
end
