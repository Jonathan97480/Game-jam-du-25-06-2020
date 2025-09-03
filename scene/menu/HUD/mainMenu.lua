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

-- Configuration depuis config.lua
local config = safeRequire('scene.menu.config') or {}
local positions = config.MAIN_MENU or {}

-- helper de log local
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Configuration des boutons principaux (utilise config.lua)
mainMenu.buttons = {
    play = {
        cmd = 'play',
        texte = 'Play',
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
                _log("[mainMenu] Play cliqué → switch vers gameplay")

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
    },

    options = {
        texte = 'Options',
        width = (positions.buttons and positions.buttons.options and positions.buttons.options.width) or 180,
        height = (positions.buttons and positions.buttons.options and positions.buttons.options.height) or 60,
        vector2 = (positions.buttons and positions.buttons.options) or
        { x = 60, y = screen.gameReso.height / 2 + (2 * 80) },
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
        texte = 'Langues',
        width = (positions.buttons and positions.buttons.languages and positions.buttons.languages.width) or 180,
        height = (positions.buttons and positions.buttons.languages and positions.buttons.languages.height) or 60,
        vector2 = (positions.buttons and positions.buttons.languages) or
        { x = 60, y = screen.gameReso.height / 2 + (3 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[mainMenu] Langues cliqué → switch vers panneau multilingue")
            if mainMenu.onSwitchPanel then
                mainMenu.onSwitchPanel("multilangue")
            end
        end
    },

    credit = {
        texte = 'Credits',
        width = (positions.buttons and positions.buttons.credits and positions.buttons.credits.width) or 180,
        height = (positions.buttons and positions.buttons.credits and positions.buttons.credits.height) or 60,
        vector2 = (positions.buttons and positions.buttons.credits) or
        { x = 60, y = screen.gameReso.height / 2 + (4 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[mainMenu] Credits cliqué → TODO: scène credits")
            -- TODO: Implémenter scène credits
        end
    },

    quit = {
        texte = 'Quitter',
        width = (positions.buttons and positions.buttons.quit and positions.buttons.quit.width) or 180,
        height = (positions.buttons and positions.buttons.quit and positions.buttons.quit.height) or 60,
        vector2 = (positions.buttons and positions.buttons.quit) or { x = 60, y = screen.gameReso.height / 2 + (5 * 80) },
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
        local inside = (mx >= value.vector2.x) and (mx <= value.vector2.x + value.width) and
            (my >= value.vector2.y) and (my <= value.vector2.y + value.height)
        if inside then
            if isClickNow and not self.isclick then
                self.isclick = true
                value.color.curent = value.color.click
                _log("[mainMenu] Clic détecté sur bouton: " .. (value.cmd or value.texte or "inconnu"))
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
    end
end

-- Fonction de rendu
function mainMenu:draw(res, fontPath)
    -- Rendu des boutons
    for _, value in pairs(self.buttons) do
        love.graphics.setColor(value.color.curent)
        if res and res.font and fontPath then
            love.graphics.setFont(res.font(fontPath, 60))
        end
        love.graphics.print(value.texte, value.vector2.x, value.vector2.y)
    end
    love.graphics.setColor(1, 1, 1)
end

return mainMenu
