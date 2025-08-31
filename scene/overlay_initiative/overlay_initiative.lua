-- scene/overlay_initiative/overlay_initiative.lua
-- LOGIQUE MÉTIER UNIQUEMENT pour l'overlay d'initiative
local overlay = { name = "overlay_initiative" }

-- Fonction de chargement sécurisé
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Dépendances
local TransitionCombat = _safeRequire("my-librairie/transitions/templateCombatTransition")
local inputInterface   = _safeRequire("my-librairie/inputInterface")
local InitiativeHUD    = _safeRequire("scene/overlay_initiative/HUD/initiative_overlay_hud")

-- Variables de logique métier
local W, H
local timer            = 0
local hold             = 10    -- secondes avant auto-continue
local who              = "?"   -- qui commence le combat
local spacePressed     = false -- a-t-on pressé espace ?
local spaceTimer       = 0     -- temps depuis que espace a été pressé
local globalFunction   = _G.globalFunction

-- Instance graphique
local hudRenderer      = nil

-- ============================
-- LOGIQUE D'INITIALISATION
-- ============================

function overlay.load(self)
    globalFunction.log.info("[overlay_initiative] load() - LOGIQUE")

    -- Récupération des dimensions d'écran
    W = (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    H = (screen and screen.gameReso and screen.gameReso.height) or love.graphics.getHeight()

    -- Création du renderer graphique
    if InitiativeHUD then
        hudRenderer = InitiativeHUD.create()
        globalFunction.log.info("[overlay_initiative] Renderer créé")
    else
        globalFunction.log.warn("[overlay_initiative] Pas de renderer, mode fallback")
    end

    globalFunction.log.info("[overlay_initiative] load() terminé, W=" .. W .. ", H=" .. H)
end

function overlay.enter(self)
    globalFunction.log.info("[overlay_initiative] enter() - LOGIQUE D'ENTRÉE")

    -- Reset de tous les timers
    timer = 0
    spacePressed = false
    spaceTimer = 0

    -- Déterminer qui commence (LOGIQUE MÉTIER)
    who = self:determineWhoStarts()

    -- Afficher l'interface graphique
    self:showInterface()

    globalFunction.log.info("[overlay_initiative] enter() terminé, qui commence: " .. who)
end

-- ============================
-- LOGIQUE MÉTIER
-- ============================

function overlay.determineWhoStarts(self)
    -- LOGIQUE : déterminer qui commence le combat
    if TransitionCombat and TransitionCombat.getInitiative then
        local initiative = TransitionCombat.getInitiative()
        return (initiative == "Enemy") and "L'ennemi commence !" or "Vous commencez !"
    elseif _G.Tour == "Enemy" then
        return "L'ennemi commence !"
    else
        return "Vous commencez !"
    end
end

function overlay.showInterface(self)
    -- DÉLÉGATION au renderer graphique
    if hudRenderer then
        local statusText = self:getStatusText()
        hudRenderer:show(W, H, who, statusText)
    end
end

function overlay.getStatusText(self)
    -- LOGIQUE : générer le texte de statut
    if spacePressed then
        local remainSpace = math.max(0, math.ceil(1.0 - spaceTimer))
        return "Fermeture dans " .. remainSpace .. " seconde(s)..."
    else
        local remain = math.max(0, math.ceil(hold - timer))
        return "Appuyez sur ESPACE pour continuer (" .. remain .. "s)"
    end
end

-- ============================
-- GESTION DES ENTRÉES
-- ============================

function overlay.keypressed(self, key)
    globalFunction.log.info("[overlay_initiative] LOGIQUE : touche pressée: " .. tostring(key))

    -- LOGIQUE : réaction à l'espace, entrée, etc.
    if key == "space" or key == "return" then
        if not spacePressed then
            globalFunction.log.info("[overlay_initiative] LOGIQUE : début du compte à rebours")
            spacePressed = true
            spaceTimer = 0
        end
    end
end

function overlay.mousepressed(self, x, y, button)
    globalFunction.log.info("[overlay_initiative] LOGIQUE : clic souris détecté: " .. tostring(button))

    -- Permettre le clic pour continuer
    if button == 1 and not spacePressed then -- clic gauche
        globalFunction.log.info("[overlay_initiative] LOGIQUE : clic pour continuer")
        spacePressed = true
        spaceTimer = 0
    end
end

function overlay.update(self, dt)
    -- print("[DEBUG] overlay_initiative.update() appelé ! dt=" .. tostring(dt) .. ", timer=" .. tostring(timer)) -- ❌ Trop verbeux

    -- Vérifier les raccourcis clavier globaux
    if globalFunction and globalFunction.endTurnHotkeys and globalFunction.endTurnHotkeys() then
        if not spacePressed then
            globalFunction.log.info("[overlay_initiative] LOGIQUE : raccourci détecté, début du compte à rebours")
            spacePressed = true
            spaceTimer = 0
        end
    end

    -- LOGIQUE : progression des timers
    timer = timer + dt

    if spacePressed then
        spaceTimer = spaceTimer + dt
        -- globalFunction.log.info("[overlay_initiative] Compte à rebours espace: " .. spaceTimer .. "/1.0") -- ❌ Trop verbeux

        -- LOGIQUE : fermer après 1 seconde
        if spaceTimer >= 1.0 then
            globalFunction.log.info("[overlay_initiative] 1 seconde écoulée, fermeture")
            self:closeOverlay()
            return
        end
    else
        -- LOGIQUE : auto-fermeture après délai
        if timer >= hold then
            globalFunction.log.info("[overlay_initiative] Délai auto-fermeture atteint")
            self:closeOverlay()
            return
        end
    end

    -- Mise à jour de l'affichage
    self:updateInterface()
end

function overlay.updateInterface(self)
    -- DÉLÉGATION au renderer graphique
    if hudRenderer then
        local statusText = self:getStatusText()
        hudRenderer:updateStatus(statusText)
    end
end

function overlay.closeOverlay(self)
    globalFunction.log.info("[overlay_initiative] LOGIQUE : fermeture de l'overlay")

    -- Nettoyer l'affichage
    if hudRenderer then
        hudRenderer:hide()
    end

    -- CORRECTIF: Utiliser la fonction du templateCombatTransition au lieu de faire pop() directement
    -- Cela évite le conflit où les deux systèmes font pop() en même temps
    if TransitionCombat and TransitionCombat.confirmInitiativeOverlay then
        globalFunction.log.info("[overlay_initiative] Notification au Transition system via confirmInitiativeOverlay()")
        TransitionCombat.confirmInitiativeOverlay()
    elseif _G.scene and _G.scene.pop then
        -- Fallback si Transition pas disponible
        globalFunction.log.warn("[overlay_initiative] Fallback: Transition non disponible, pop() direct")
        _G.scene:pop()
    else
        globalFunction.log.error("[overlay_initiative] ERREUR: Aucun moyen de fermer l'overlay !")
    end
end

-- ============================
-- RENDU
-- ============================

function overlay.draw(self)
    -- ✅ HUD rendu centralisé dans main.lua - plus besoin d'appeler hudRenderer:draw() ici

    -- Les éléments HUD sont automatiquement affichés par main.lua après hud.draw()
    -- Le HUD d'initiative est créé dans enter() et sera automatiquement rendu
end

-- ============================
-- NETTOYAGE
-- ============================

function overlay.leave(self)
    globalFunction.log.info("[overlay_initiative] leave() - NETTOYAGE LOGIQUE")

    -- Nettoyer le renderer seulement
    if hudRenderer then
        hudRenderer:hide()
        hudRenderer = nil
    end

    -- Reset des variables
    timer = 0
    spacePressed = false
    spaceTimer = 0
    who = "?"
end

-- Capture de souris pour éviter les interactions pendant l'overlay
function overlay.isMouseOver()
    return true
end

overlay.hitTest = overlay.isMouseOver
overlay.bounds = { { x = 0, y = 0, w = math.huge, h = math.huge } }

return overlay
