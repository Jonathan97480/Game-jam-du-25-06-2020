--[[ anbianceanbiance.aambianceanbiance ]]
--anbianceanbiance.aambianceanbiance
--anbianceanbiance.aambianceanbiance
--anbiancemanbiancem.aambianceanbiancem
--anbiancemanbiancem.aambianceanbiancemful
--anbiancemanbiancem.aambianceanbiancemfulfullSound
--anbiancemanbiancem.aambianceanbiancemfulfullSoundambiance
--anbiancemanbiancem.aambianceanbiancemfulfullSoundambianceambiance2
--anbiancemanbiancem.aambianceanbiancemfulfullSoundambianceambiance2fullSound
--anbiancemanbiancem.aambianceanbiancemfulfullSoundambianceambiance2fullSoundambiance2

local screen         = _G.screen
local scene          = _G.scene
local globalFunction = _G.globalFunction

local config         = require("scene.menu.config")
local res            = require("my-librairie.managers.resource_cache")

-- Chargement des panneaux modulaires HUD
local mainMenu   = require("scene.menu.HUD.mainMenu")
local multiLangue = require("scene.menu.HUD.MultiLangue")
local options    = require("scene.menu.HUD.options")


-- helper de log local : utilise globalFunction.log.info si présent, sinon print
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

local menu        = {}
menu.name = "menu"  -- IMPORTANT: nom pour le sceneManager
menu.illustration = {}

-- État du menu et panneaux
menu.currentPanel = "main"  -- Panneau actuel : "main", "multilangue", "options"
menu.panels = {
    main = mainMenu,
    multilangue = multiLangue,
    options = options
}

-- Custom transition script for the menu scene (slide + fade)
menu.transition   = {
    durationOut = 0.4,
    durationIn  = 0.45,
    maskInput   = true,
    easingOut   = function(x) return x ^ 3 end,
    easingIn    = function(x) return 1 - (1 - x) ^ 3 end,
    drawOut     = function(p, ctx)
        local w, h = ctx.w, ctx.h
        love.graphics.push("all")
        love.graphics.translate(-p * w * 0.4, 0)
        love.graphics.pop()
        love.graphics.setColor(0, 0, 0, p * 0.6)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end,
    drawIn      = function(p, ctx)
        local w, h = ctx.w, ctx.h
        love.graphics.push("all")
        love.graphics.translate((1 - p) * w * 0.3, 0)
        love.graphics.pop()
        love.graphics.setColor(0, 0, 0, (1 - p) * 0.4)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end,
}


--[[ Arrière-plan & titre ]]
-- Chargement sécurisé des ressources avec fallback
local resources = config.load() or {}

-- Vérification et chargement sécurisé des images avec valeurs par défaut
local backgroundPath = "img/Menu/BackGround.jpg"
local titlePath = "img/Menu/Titre.png"

if resources and resources.images then
    backgroundPath = resources.images.background or backgroundPath
    titlePath = resources.images.title or titlePath
end

menu.illustration.background = {
    r = resources,
    img = res.image(backgroundPath),
    vector2 = { x = 0, y = 0 }
}

menu.illustration.title = {
    img = res.image(titlePath),
    vector2 = {
        x = screen.gameReso.width / 2,
        y = screen.gameReso.height / 4  -- Position corrigée (était /0.5)
    }
}

-- Footer (barre en bas)
-- footer removed from menu; drawn only in gameplay

-- Configuration des callbacks pour changer de panneau
local function setupPanelCallbacks()
    -- Fonction de changement de panneau
    local function switchPanel(panelName)
        _log("[menu] Changement de panneau vers: " .. tostring(panelName))
        menu.currentPanel = panelName or "main"
    end
    
    -- Fonction de notification de changement de langue
    local function onLanguageChanged()
        _log("[menu] Langue changée, mise à jour de tous les panneaux")
        -- Mettre à jour les textes de tous les panneaux
        for panelName, panel in pairs(menu.panels) do
            if panel and panel.updateTexts then
                panel:updateTexts()
                _log("[menu] Textes mis à jour pour le panneau: " .. panelName)
            end
        end
    end
    
    -- Assignation des callbacks
    for panelName, panel in pairs(menu.panels) do
        if panel then
            panel.onSwitchPanel = switchPanel
            panel.onLanguageChanged = onLanguageChanged
            _log("[menu] Callbacks assignés au panneau: " .. panelName)
        end
    end
end

--[[
Fonction : menu.load
Rôle : Prépare l'écran de menu et charge les panneaux.
Paramètres : (aucun)
Retour : nil
]]
function menu.load()
    _log("[menu] Chargement scène menu")
    config.load()
    
    -- Configuration des callbacks entre panneaux
    setupPanelCallbacks()
    
    -- Chargement des panneaux
    for panelName, panel in pairs(menu.panels) do
        if panel and panel.load then
            _log("[menu] Chargement panneau: " .. panelName)
            panel:load()
        end
    end
    
    -- Chargement sécurisé des ressources audio
    local audioResources = config.RESOURCES
    if audioResources and audioResources.audio then
        if audioResources.audio.ambiance then
            res.audio(audioResources.audio.ambiance)
        end
        if audioResources.audio.fullSound then
            res.audio(audioResources.audio.fullSound)
            love.audio.play(res.audio(audioResources.audio.ambiance2))
        end
    else
        _log("[menu] Ressources audio non trouvées dans config.RESOURCES")
    end
end

--[[
Fonction : menu.enter
Rôle : Appelée quand la scène devient active
Paramètres : (aucun)
Retour : nil
]]
function menu.enter()
    _log("[menu] Scène menu activée")
end

--[[
Fonction : menu.resume
Rôle : Appelée quand la scène reprend après avoir été en pause (ex: après un pop)
Paramètres : (aucun)
Retour : nil
]]
function menu.resume()
    _log("[menu] Scène menu reprise après pause")
    -- Recharger les ressources si nécessaire
    if config.RESOURCES == nil or #config.RESOURCES == 0 then
        config.load()
    end
end

--[[
Fonction : menu.pause
Rôle : Appelée quand la scène est mise en pause (ex: avant un push)
Paramètres : (aucun)
Retour : nil
]]
function menu.pause()
    _log("[menu] Scène menu mise en pause")
end

--[[
Fonction : menu.leave
Rôle : Appelée quand la scène devient inactive
Paramètres : (aucun)
Retour : nil
]]
function menu.leave()
    _log("[menu] Scène menu quittée")
end

--[[
Fonction : menu.unload
Rôle : Appelée pour nettoyer les ressources de la scène
Paramètres : (aucun)
Retour : nil
]]
function menu.unload()
    _log("[menu] Ressources menu libérées")
end

--[[
Fonction : menu.update
Rôle : Délègue la mise à jour au panneau actuel.
Paramètres :
  - dt : nombre
Retour : nil
]]
function menu.update(dt)
    if config.RESOURCES == nil or #config.RESOURCES == 0 then
        config.load()
    end
    
    -- Déléguer au panneau actuel
    local currentPanel = menu.panels[menu.currentPanel]
    if currentPanel and currentPanel.update then
        currentPanel:update(dt)
    end
end

--[[
Fonction : menu.draw
Rôle : Affiche le menu et délègue au panneau actuel.
Paramètres : (aucun)
Retour : nil
]]
function menu.draw()
    if config.RESOURCES == nil or #config.RESOURCES == 0 then
        config.load()
    end
    
    -- Arrière-plan commun
    love.graphics.draw(menu.illustration.background.img, 0, 0)
    
    -- Footer si présent
    if menu.illustration.footer and menu.illustration.footer.img then
        local f = menu.illustration.footer.img
        local fh = (type(f.getHeight) == 'function' and f:getHeight()) or 0
        love.graphics.draw(f, 0, screen.gameReso.height - fh)
    end
    
    -- Titre du jeu (optionnel)
    -- love.graphics.draw(menu.illustration.title.img, menu.illustration.title.vector2.x, menu.illustration.title.vector2.y)
    
    -- Déléguer le rendu au panneau actuel
    local currentPanel = menu.panels[menu.currentPanel]
    if currentPanel and currentPanel.draw then
        local fontResources = config.RESOURCES
        local fontPath = "fonts/PANICKO.ttf"
        if fontResources and fontResources.fonts and fontResources.fonts.main then
            fontPath = fontResources.fonts.main
        end
        currentPanel:draw(res, fontPath)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return menu
