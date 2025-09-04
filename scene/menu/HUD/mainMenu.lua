-- scene/menu/HUD/mainMenu.lua
-- Panneau principal du menu avec les boutons principaux

local mainMenu = {}

-- Fonction d'importation sécurisée
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Accès aux globales
local screen = _G.screen
local scene = _G.scene
local globalFunction = _G.globalFunction
local saveManager = _G.saveManager

-- Configuration depuis config.lua
local config = safeRequire('scene.menu.config') or {}
local positions = config.MAIN_MENU or {}

-- Import du panneau loadSave
local loadSave = safeRequire('scene.menu.HUD.loadSave')

-- helper de log local
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Fonction pour vérifier s'il y a des sauvegardes disponibles
local function hasSaves()
    if not saveManager then return false end
    local saves = saveManager.getSaveSlots() or {}
    return #saves > 0
end

-- Fonction pour charger la dernière sauvegarde
local function loadLatestSave()
    if not saveManager then
        _log("[mainMenu] SaveManager non disponible")
        return false
    end
    
    local latestSave = saveManager.getLatestSave()
    if not latestSave then
        _log("[mainMenu] Aucune sauvegarde trouvée")
        return false
    end
    
    local success, result
    if latestSave.slot then
        success, result = saveManager.loadFromSlot(latestSave.slot)
    else
        success, result = saveManager.loadFromFile(latestSave.filename)
    end
    
    if success then
        _log("[mainMenu] Dernière sauvegarde chargée avec succès")
        if scene and scene.switch then
            scene:switch("scene.gameplay.gameplay")
        end
        return true
    else
        _log("[mainMenu] Échec chargement dernière sauvegarde: " .. tostring(result))
        return false
    end
end

-- Configuration des boutons principaux (utilise config.lua)
mainMenu.buttons = {
    play = {
        cmd = 'play',
        texte = function() 
            -- Changer le texte selon la présence de sauvegardes
            if hasSaves() then
                return _G.t and _G.t("ui.menu.continue") or "Continuer"
            else
                return _G.t and _G.t("ui.menu.new_game") or "Nouvelle Partie"
            end
        end,
        width = (positions.buttons and positions.buttons.play and positions.buttons.play.width) or 180,
        height = (positions.buttons and positions.buttons.play and positions.buttons.play.height) or 60,
        vector2 = (positions.buttons and positions.buttons.play) or { x = 60, y = screen.gameReso.height / 2 + (1 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            if btn and btn.cmd == 'play' then
                if hasSaves() then
                    -- S'il y a des sauvegardes, charger la plus récente
                    _log("[mainMenu] Continue cliqué → chargement dernière sauvegarde")
                    loadLatestSave()
                else
                    -- Sinon, commencer une nouvelle partie
                    _log("[mainMenu] Nouvelle Partie cliqué → switch vers gameplay")
                    
                    if not scene then
                        _log("[mainMenu] ERREUR: scene global n'est pas disponible")
                        return
                    end

                    if not scene.switchWithTransition then
                        _log("[mainMenu] ERREUR: scene.switchWithTransition n'existe pas")
                        return
                    end

                    local gameplayPaths = { "scene.gameplay.gameplay" }
                    local gameplayLoaded = false

                    for _, path in ipairs(gameplayPaths) do
                        local ok, gameplayScene = pcall(require, path)
                        if ok and gameplayScene then
                            _log("[mainMenu] Gameplay trouvé avec le chemin: " .. path)
                            local switchOk, result = pcall(function()
                                return scene:switchWithTransition(path, {})
                            end)
                            if switchOk then
                                _log("[mainMenu] Switch réussi vers: " .. path)
                                gameplayLoaded = true
                                break
                            else
                                _log("[mainMenu] Échec du switch vers " .. path .. ": " .. tostring(result))
                            end
                        else
                            _log("[mainMenu] Impossible de charger: " .. path .. " (" .. tostring(gameplayScene) .. ")")
                        end
                    end

                    if not gameplayLoaded then
                        _log("[mainMenu] ERREUR: Impossible de charger la scène de gameplay")
                    end
                end
            end
        end
    },

    loadSave = {
        cmd = 'loadsave',
        texte = function()
            return _G.t and _G.t("ui.menu.load_save") or "Charger Partie"
        end,
        visible = function()
            -- N'afficher que s'il y a des sauvegardes
            return hasSaves()
        end,
        width = (positions.buttons and positions.buttons.play and positions.buttons.play.width) or 180,
        height = (positions.buttons and positions.buttons.play and positions.buttons.play.height) or 60,
        vector2 = (positions.buttons and positions.buttons.play) or { x = 60, y = screen.gameReso.height / 2 + (2 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            if btn and btn.cmd == 'loadsave' then
                _log("[mainMenu] Load Save cliqué → switch vers panneau loadSave")
                if mainMenu.onSwitchPanel then
                    mainMenu.onSwitchPanel("loadsave")
                end
            end
        end
    },

    options = {
        texte = function()
            return _G.t and _G.t("ui.menu.options") or "Options"
        end,
        width = (positions.buttons and positions.buttons.options and positions.buttons.options.width) or 180,
        height = (positions.buttons and positions.buttons.options and positions.buttons.options.height) or 60,
        vector2 = function()
            -- Ajuster position selon présence du bouton loadSave
            local yOffset = hasSaves() and 3 or 2
            return (positions.buttons and positions.buttons.options) or 
                { x = 60, y = screen.gameReso.height / 2 + (yOffset * 80) }
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[mainMenu] Options cliqué → switch vers panneau options")
            if mainMenu.onSwitchPanel then
                mainMenu.onSwitchPanel("options")
            end
        end
    },

    multilingual = {
        texte = function()
            return _G.t and _G.t("ui.menu.languages") or "Langues"
        end,
        width = (positions.buttons and positions.buttons.languages and positions.buttons.languages.width) or 180,
        height = (positions.buttons and positions.buttons.languages and positions.buttons.languages.height) or 60,
        vector2 = function()
            -- Ajuster position selon présence du bouton loadSave
            local yOffset = hasSaves() and 4 or 3
            return (positions.buttons and positions.buttons.languages) or
                { x = 60, y = screen.gameReso.height / 2 + (yOffset * 80) }
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[mainMenu] Langues cliqué → switch vers panneau multilangue")
            if mainMenu.onSwitchPanel then
                mainMenu.onSwitchPanel("multilangue")
            end
        end
    },

    credits = {
        texte = function()
            return _G.t and _G.t("ui.menu.credits") or "Crédits"
        end,
        width = (positions.buttons and positions.buttons.credits and positions.buttons.credits.width) or 180,
        height = (positions.buttons and positions.buttons.credits and positions.buttons.credits.height) or 60,
        vector2 = function()
            -- Ajuster position selon présence du bouton loadSave
            local yOffset = hasSaves() and 5 or 4
            return (positions.buttons and positions.buttons.credits) or
                { x = 60, y = screen.gameReso.height / 2 + (yOffset * 80) }
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[mainMenu] Crédits cliqué → switch vers crédits")
            if scene and scene.switch then
                scene:switch("scene.credit.credit")
            end
        end
    },

    quit = {
        texte = function()
            return _G.t and _G.t("ui.menu.quit") or "Quitter"
        end,
        width = (positions.buttons and positions.buttons.quit and positions.buttons.quit.width) or 180,
        height = (positions.buttons and positions.buttons.quit and positions.buttons.quit.height) or 60,
        vector2 = function()
            -- Ajuster position selon présence du bouton loadSave
            local yOffset = hasSaves() and 6 or 5
            return (positions.buttons and positions.buttons.quit) or
                { x = 60, y = screen.gameReso.height / 2 + (yOffset * 80) }
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            love.window.close()
        end
    }
}

-- Variable d'état pour les clics
mainMenu.isclick = false

-- Callback pour changer de panneau (sera défini par menu.lua)
mainMenu.onSwitchPanel = nil

-- Fonction de chargement
function mainMenu:load()
    _log("[mainMenu] Panneau principal chargé")
    -- Mettre à jour les textes selon la langue actuelle
    self:updateTexts()
end

-- Fonction pour mettre à jour les textes selon la langue actuelle
function mainMenu:updateTexts()
    if _G.localization and _G.localization.get then
        -- Mettre à jour les textes des boutons selon la langue actuelle
        self.buttons.play.texte = _G.localization.get("ui.menu.play") or "Jouer"
        self.buttons.options.texte = _G.localization.get("ui.menu.options") or "Options"
        self.buttons.multilingual.texte = _G.localization.get("ui.options.language") or "Langues"
        self.buttons.credit.texte = _G.localization.get("ui.menu.credits") or "Crédits"
        self.buttons.quit.texte = _G.localization.get("ui.menu.quit") or "Quitter"

        _log("[mainMenu] Textes mis à jour selon la langue: " .. (_G.localization.getCurrentLanguage() or "unknown"))
    end
end

-- Fonction de mise à jour avec gestion des interactions
function mainMenu:update(dt)
    self:handleInput()
end

-- Gestion des entrées (hover et clic)
function mainMenu:handleInput()
    local gf = _G.globalFunction
    local mx, my = 0, 0

    -- Récupération de la position de la souris
    local okI, iface = pcall(require, "my-librairie/inputInterface")
    if okI and iface and iface.getCursor then
        local c = iface.getCursor()
        mx, my = (c and c.x) or 0, (c and c.y) or 0
    else
        if _G.cursor and type(_G.cursor) == "table" and type(_G.cursor.get) == "function" then
            local x, y = _G.cursor.get()
            mx, my = x, y
        else
            if gf and gf.mouse and gf.mouse.hover then
                local hx, hy = gf.mouse.hover()
                if type(hx) == 'number' and type(hy) == 'number' then
                    mx, my = hx, hy
                else
                    mx, my = 0, 0
                end
            else
                mx, my = 0, 0
            end
        end
    end

    -- Détection du clic
    local isClickNow = false
    if gf and gf.mouse and gf.mouse.click then
        isClickNow = gf.mouse.click() == true
    else
        local input_ok, input = pcall(require, "my-librairie/inputManager")
        if input_ok and input and input.justPressed then
            isClickNow = input.justPressed()
        else
            local okI, iface = pcall(require, "my-librairie/inputInterface")
            if okI and iface and iface.justPressedAction then
                isClickNow = iface.justPressedAction()
            end
        end
    end

    -- Traitement des boutons
    for _, value in pairs(self.buttons) do
        -- Gérer la visibilité dynamique
        local isVisible = true
        if type(value.visible) == "function" then
            isVisible = value.visible()
        elseif value.visible == false then
            isVisible = false
        end
        
        if not isVisible then
            goto continue -- Passer au bouton suivant
        end
        
        -- Obtenir position dynamique
        local pos = value.vector2
        if type(pos) == "function" then
            pos = pos()
        end
        
        local inside = (mx >= pos.x) and (mx <= pos.x + value.width) and
            (my >= pos.y) and (my <= pos.y + value.height)
        if inside then
            if isClickNow and not self.isclick then
                self.isclick = true
                value.color.curent = value.color.click
                _log("[mainMenu] Clic détecté sur bouton: " .. (value.cmd or (type(value.texte) == "function" and value.texte() or value.texte) or "inconnu"))
                if value.action then
                    value.action(value)
                else
                    _log("[mainMenu] ERREUR: bouton sans fonction action")
                end
                break
            else
                value.color.curent = value.color.hover
                self.isclick = false
            end
            break
        elseif self.isclick then
            self.isclick = false
            break
        else
            value.color.curent = value.color.normal
        end
        
        ::continue::
    end
end

-- Fonction de rendu
function mainMenu:draw(res, fontPath)
    -- Rendu des boutons
    for _, value in pairs(self.buttons) do
        -- Gérer la visibilité dynamique
        local isVisible = true
        if type(value.visible) == "function" then
            isVisible = value.visible()
        elseif value.visible == false then
            isVisible = false
        end
        
        if isVisible then
            love.graphics.setColor(value.color.curent)
            if res and res.font and fontPath then
                love.graphics.setFont(res.font(fontPath, 60))
            end
            
            -- Obtenir texte dynamique
            local displayText = ""
            if type(value.texte) == "function" then
                displayText = tostring(value.texte())
            else
                displayText = tostring(value.texte)
            end
            
            -- Obtenir position dynamique
            local pos = value.vector2
            if type(pos) == "function" then
                pos = pos()
            end
            
            love.graphics.print(displayText, pos.x, pos.y)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

return mainMenu
