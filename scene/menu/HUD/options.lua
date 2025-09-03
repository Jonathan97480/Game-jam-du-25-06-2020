-- scene/menu/HUD/options.lua
-- Panneau d'options du jeu

local options = {}

-- Accès aux globales
local screen = _G.screen
local globalFunction = _G.globalFunction

-- helper de log local
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Configuration des options et boutons
options.settings = {
    volume = 50,        -- Volume général (0-100)
    fullscreen = false, -- Mode plein écran
    debug = false,      -- Mode debug
}

options.buttons = {
    volume_moins = {
        texte = 'Volume -',
        width = 150,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (1 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            options.settings.volume = math.max(0, options.settings.volume - 10)
            _log("[options] Volume diminué: " .. options.settings.volume)
            -- Appliquer le volume au système audio
            options:applyVolumeSettings()
        end
    },

    volume_plus = {
        texte = 'Volume +',
        width = 150,
        height = 60,
        vector2 = { x = 220, y = screen.gameReso.height / 2 + (1 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            options.settings.volume = math.min(100, options.settings.volume + 10)
            _log("[options] Volume augmenté: " .. options.settings.volume)
            -- Appliquer le volume au système audio
            options:applyVolumeSettings()
        end
    },

    fullscreen_toggle = {
        texte = 'Plein écran: OFF',
        width = 280,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (2 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            options.settings.fullscreen = not options.settings.fullscreen
            btn.texte = "Plein écran: " .. (options.settings.fullscreen and "ON" or "OFF")
            _log("[options] Mode plein écran: " .. tostring(options.settings.fullscreen))

            -- Appliquer le changement
            if love.window.setFullscreen then
                love.window.setFullscreen(options.settings.fullscreen)
            end
        end
    },

    debug_toggle = {
        texte = 'Debug: OFF',
        width = 200,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (3 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            options.settings.debug = not options.settings.debug
            btn.texte = "Debug: " .. (options.settings.debug and "ON" or "OFF")
            _log("[options] Mode debug: " .. tostring(options.settings.debug))

            -- Appliquer le changement au système debug
            if _G.scene then
                _G.scene.debug = options.settings.debug
            end
        end
    },

    sauvegarder = {
        texte = 'Sauvegarder',
        width = 220,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (5 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[options] Sauvegarde des options")
            options:saveSettings()
        end
    },

    retour = {
        texte = 'Retour',
        width = 180,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (6 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[options] Retour au menu principal")
            if options.onSwitchPanel then
                options.onSwitchPanel("main")
            end
        end
    }
}

-- Variable d'état pour les clics
options.isclick = false

-- Callback pour changer de panneau
options.onSwitchPanel = nil

-- Fonction de chargement
function options:load()
    _log("[options] Panneau options chargé")
    self:loadSettings()
    self:updateButtonTexts()
    -- Appliquer le volume initial
    self:applyVolumeSettings()
end

-- Charger les paramètres sauvegardés
function options:loadSettings()
    -- TODO: Charger depuis fichier de sauvegarde
    -- Pour l'instant, utiliser les valeurs par défaut
    _log("[options] Chargement des paramètres (valeurs par défaut)")
end

-- Sauvegarder les paramètres
function options:saveSettings()
    -- Appliquer les paramètres avant de sauvegarder
    self:applyVolumeSettings()

    -- TODO: Sauvegarder dans fichier
    _log("[options] Paramètres sauvegardés: volume=" .. self.settings.volume ..
        ", fullscreen=" .. tostring(self.settings.fullscreen) ..
        ", debug=" .. tostring(self.settings.debug))
end

-- Mettre à jour les textes des boutons selon l'état actuel
function options:updateButtonTexts()
    self.buttons.fullscreen_toggle.texte = "Plein écran: " .. (self.settings.fullscreen and "ON" or "OFF")
    self.buttons.debug_toggle.texte = "Debug: " .. (self.settings.debug and "ON" or "OFF")
end

-- Appliquer les paramètres de volume au système audio
function options:applyVolumeSettings()
    local volumeRatio = self.settings.volume / 100.0 -- Convertir 0-100 en 0.0-1.0

    _log("[options] Application du volume: " .. volumeRatio .. " (volume=" .. self.settings.volume .. "%)")

    -- Appliquer le volume global dans LÖVE2D
    if love.audio and love.audio.setVolume then
        love.audio.setVolume(volumeRatio)
        _log("[options] ✅ Volume global appliqué: " .. volumeRatio)
    else
        _log("[options] ❌ ERREUR: love.audio.setVolume non disponible")
    end

    -- Optionnel: Appliquer le volume à toutes les sources audio actives
    local sources = love.audio.getSourceCount and love.audio.getSourceCount() or 0
    if sources > 0 then
        _log("[options] 🔊 " .. sources .. " sources audio actives détectées")
        -- Note: Pour appliquer le volume aux sources individuelles,
        -- il faudrait maintenir une liste des sources dans le jeu
    end
end

-- Fonction de mise à jour
function options:update(dt)
    self:handleInput()
end

-- Gestion des entrées
function options:handleInput()
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

    -- Gestion de la touche Echap pour retourner au menu principal
    if love.keyboard.isDown("escape") then
        _log("[options] Touche Echap détectée → retour au menu principal")
        if options.onSwitchPanel then
            options.onSwitchPanel("main")
        end
        return -- Sortir pour éviter de traiter les autres inputs
    end

    -- Traitement des boutons
    for _, value in pairs(self.buttons) do
        local inside = (mx >= value.vector2.x) and (mx <= value.vector2.x + value.width) and
            (my >= value.vector2.y) and (my <= value.vector2.y + value.height)
        if inside then
            if isClickNow and not self.isclick then
                self.isclick = true
                value.color.curent = value.color.click
                _log("[options] Clic détecté sur bouton: " .. (value.texte or "inconnu"))
                if value.action then
                    value.action(value)
                else
                    _log("[options] ERREUR: bouton sans fonction action")
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
function options:draw(res, fontPath)
    -- Titre du panneau
    love.graphics.setColor(1, 1, 1)
    if res and res.font and fontPath then
        love.graphics.setFont(res.font(fontPath, 80))
    end
    love.graphics.print("Options", 60, screen.gameReso.height / 2 - 150)

    -- Affichage du volume actuel
    if res and res.font and fontPath then
        love.graphics.setFont(res.font(fontPath, 40))
    end
    love.graphics.print("Volume: " .. self.settings.volume .. "%", 380, screen.gameReso.height / 2 + (1 * 80) + 10)

    -- Rendu des boutons
    for _, value in pairs(self.buttons) do
        love.graphics.setColor(value.color.curent)
        if res and res.font and fontPath then
            love.graphics.setFont(res.font(fontPath, 50))
        end
        love.graphics.print(value.texte, value.vector2.x, value.vector2.y)
    end
    love.graphics.setColor(1, 1, 1)
end

return options
