-- scene/overlay_initiative.lua
-- Overlay d'initiative converti au système HUD modulaire
local overlay = { name = "overlay_initiative" }

-- Fonction de chargement sécurisé
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local Transition     = _safeRequire("my-librairie/transition/templateCombatTransition")
local hud            = _G.hud
local inputManager   = _safeRequire("my-librairie/inputManager")

local W, H
local timer          = 0
local hold           = 10  -- secondes avant auto-continue (peut être réduit)
local who            = "?"
local spacePressed   = false -- Flag pour savoir si espace a été pressé
local spaceTimer     = 0   -- Timer depuis que espace a été pressé
local globalFunction = _G.globalFunction

-- IDs des éléments HUD
local PANEL_ID = "initiative_panel"
local TITLE_ID = "initiative_title"
local MESSAGE_ID = "initiative_message"
local STATUS_ID = "initiative_status"
local BACKGROUND_ID = "initiative_bg"

function overlay.load(self)
    globalFunction.log.info("[overlay_initiative] load() called!")
    W = (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    H = (screen and screen.gameReso and screen.gameReso.height) or love.graphics.getHeight()
    
    -- S'assurer que le HUD est disponible
    if not hud then
        globalFunction.log.warn("[overlay_initiative] HUD system not available, fallback mode")
        return
    end
    
    globalFunction.log.info("[overlay_initiative] load() finished, W=" .. W .. ", H=" .. H)
end

function overlay.enter(self)
    globalFunction.log.info("[overlay_initiative] enter() called!")
    timer = 0
    spacePressed = false -- Reset le flag espace
    spaceTimer = 0       -- Reset le timer espace
    
    -- Qui commence ? le manager doit l'avoir décidé avant d'entrer dans cet état
    if Transition and Transition.getInitiative then
        who = Transition.getInitiative() == "Enemy" and "L'ennemi commence !" or "Vous commencez !"
    elseif _G.Tour == "Enemy" then
        who = "L'ennemi commence !"
    else
        who = "Vous commencez !"
    end
    
    if hud then
        self:createHudElements()
    end
    
    globalFunction.log.info("[overlay_initiative] enter() finished, who=" .. who)
end

function overlay.createHudElements(self)
    -- Background semi-transparent plein écran
    hud.addIcon(BACKGROUND_ID, {
        x = 0,
        y = 0,
        w = W,
        h = H,
        layer = "background",
        color = {0, 0, 0, 0.6}
    })
    
    -- Panel principal centré
    local boxW, boxH = math.min(800, W * 0.8), math.min(320, H * 0.5)
    local panelX, panelY = (W - boxW) / 2, (H - boxH) / 2
    
    hud.setPanel(PANEL_ID, panelX, panelY, boxW, boxH, {}, {
        color = {20/255, 22/255, 26/255, 0.95},
        layer = "props"
    })
    
    -- Titre "Initiative"
    hud.addLabel(TITLE_ID, {
        text = "Initiative",
        x = panelX,
        y = panelY + 24,
        w = boxW,
        layer = "card",
        font = "title",
        color = {1, 1, 1, 1},
        align = "center"
    })
    
    -- Message qui commence
    hud.addLabel(MESSAGE_ID, {
        text = who,
        x = panelX + 20,
        y = panelY + 110,
        w = boxW - 40,
        layer = "card",
        font = "subtitle",
        color = {1, 1, 1, 1},
        align = "center"
    })
    
    -- Message de statut (en bas)
    local statusText = "Appuyez sur ESPACE pour continuer (" .. hold .. "s)"
    hud.addLabel(STATUS_ID, {
        text = statusText,
        x = panelX + 20,
        y = panelY + boxH - 48,
        w = boxW - 40,
        layer = "card",
        font = "normal",
        color = {1, 1, 1, 1},
        align = "center"
    })
end

function overlay.update(self, dt)
    -- Mise à jour du système input
    if inputManager then
        inputManager.update(dt)
    end
    
    -- Mise à jour du système HUD
    if hud then
        hud.update(dt)
    end
    
    timer = timer + dt
    globalFunction.log.info("[overlay_initiative] update() timer=" ..
        timer .. ", spacePressed=" .. tostring(spacePressed))

    -- Si espace a été pressé, compter 1 seconde puis fermer
    if spacePressed then
        spaceTimer = spaceTimer + dt
        globalFunction.log.info("[overlay_initiative] space countdown: " .. spaceTimer .. "/1.0")
        
        -- Mettre à jour le texte de statut
        if hud then
            local remainSpace = math.max(0, math.ceil(1.0 - spaceTimer))
            hud.setText(STATUS_ID, "Fermeture dans " .. remainSpace .. " seconde(s)...")
        end
        
        if spaceTimer >= 1.0 then -- 1 seconde après espace
            globalFunction.log.info("[overlay_initiative] 1 second passed, closing overlay directly")
            self:closeOverlay()
        end
    else
        -- Mettre à jour le timer de statut
        if hud then
            local remain = math.max(0, math.ceil(hold - timer))
            hud.setText(STATUS_ID, "Appuyez sur ESPACE pour continuer (" .. remain .. "s)")
        end
        
        -- Auto-continue après le délai normal
        if timer >= hold then
            globalFunction.log.info("[overlay_initiative] Auto-continue timeout reached, closing overlay directly")
            self:closeOverlay()
        end
    end
end

function overlay.closeOverlay(self)
    -- Nettoyer les éléments HUD
    if hud then
        hud.remove(BACKGROUND_ID)
        hud.remove(PANEL_ID)
        hud.remove(TITLE_ID)
        hud.remove(MESSAGE_ID)
        hud.remove(STATUS_ID)
    end
    
    -- Fermer l'overlay
    if _G.scene and _G.scene.pop then
        globalFunction.log.info("[overlay_initiative] Calling scene:pop() to close overlay")
        _G.scene:pop()
    end
end

function overlay.draw(self)
    -- Le système HUD s'occupe du rendu
    if hud then
        hud.draw()
    else
        -- Fallback vers le rendu manuel si HUD non disponible
        self:drawFallback()
    end
end

function overlay.drawFallback(self)
    -- Rendu de fallback (ancien système)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Panel central
    local boxW, boxH = math.min(800, W * 0.8), math.min(320, H * 0.5)
    local x, y = (W - boxW) / 2, (H - boxH) / 2
    
    love.graphics.setColor(20/255, 22/255, 26/255, 0.95)
    love.graphics.rectangle("fill", x, y, boxW, boxH, 16)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf("Initiative", x, y + 24, boxW, "center")
    
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf(who, x + 20, y + 110, boxW - 40, "center")

    love.graphics.setFont(love.graphics.newFont(18))
    -- Affichage différent selon l'état
    if spacePressed then
        local remainSpace = math.max(0, math.ceil(1.0 - spaceTimer))
        love.graphics.printf("Fermeture dans " .. remainSpace .. " seconde(s)...", x + 20, y + boxH - 48,
            boxW - 40, "center")
    else
        local remain = math.max(0, math.ceil(hold - timer))
        love.graphics.printf("Appuyez sur ESPACE pour continuer (" .. remain .. "s)", x + 20, y + boxH - 48,
            boxW - 40, "center")
    end
end

-- Entrées utilisateur pour "skip"
function overlay.keypressed(self, key)
    globalFunction.log.info("[overlay_initiative] ⚡ KEYPRESSED CALLED! Key: " .. tostring(key))
    globalFunction.log.info("[overlay_initiative] Key pressed: " .. tostring(key))
    if key == "space" or key == "return" or key == "kpenter" then
        globalFunction.log.info("[overlay_initiative] 🚀 SPACE DETECTED! spacePressed was:" .. tostring(spacePressed))
        globalFunction.log.info("[overlay_initiative] Space pressed! spacePressed was:" .. tostring(spacePressed))
        if not spacePressed then -- Évite de redéclencher si déjà en cours
            spacePressed = true
            spaceTimer = 0       -- Reset le timer à 0 pour commencer le compte à rebours d'1 seconde
            globalFunction.log.info("[overlay_initiative] ✅ SPACE FLAG SET! Timer started for 1 second countdown")
            globalFunction.log.info("[overlay_initiative] Timer started for 1 second countdown")
        end
    else
        globalFunction.log.info("[overlay_initiative] Other key pressed: " .. tostring(key))
    end
end

function overlay.leave(self)
    globalFunction.log.info("[overlay_initiative] leave() called - cleaning up HUD elements")
    self:closeOverlay()
end

-- Pour éviter que le HUD "mange" la souris pendant l'overlay :
function overlay.isMouseOver()
    return true
end

overlay.hitTest = overlay.isMouseOver
overlay.bounds = { { x = 0, y = 0, w = math.huge, h = math.huge } }

return overlay
