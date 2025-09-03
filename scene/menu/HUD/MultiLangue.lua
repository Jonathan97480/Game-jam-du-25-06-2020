-- scene/menu/HUD/MultiLangue.lua
-- Panneau de sélection de langue

local multiLangue = {}

-- Fonction d'importation sécurisée
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Accès aux globales
local screen = _G.screen
local globalFunction = _G.globalFunction

-- Chargement des ressources
local config = require("scene.menu.config")
local res = require("my-librairie.managers.resource_cache")

-- helper de log local
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Images des drapeaux (chargées dynamiquement)
multiLangue.flags = {}

-- Configuration des boutons de langue (utilise config.lua)
local config = safeRequire('scene.menu.config') or {}
local positions = config.MULTILANGUE or {}

multiLangue.buttons = {
    francais = {
        texte = 'Français',
        langue = 'fr',
        width = (positions.buttons and positions.buttons.francais and positions.buttons.francais.clickZone and positions.buttons.francais.clickZone.width) or
            300,
        height = (positions.buttons and positions.buttons.francais and positions.buttons.francais.clickZone and positions.buttons.francais.clickZone.height) or
            80,
        vector2 = (positions.buttons and positions.buttons.francais and positions.buttons.francais.clickZone) or
            { x = 60, y = screen.gameReso.height / 2 + (1 * 120) },
        flagPos = (positions.buttons and positions.buttons.francais and positions.buttons.francais.flag) or
            { x = 60, y = screen.gameReso.height / 2 + (1 * 120) + 40 },
        textPos = (positions.buttons and positions.buttons.francais and positions.buttons.francais.text) or
            { x = 60, y = screen.gameReso.height / 2 + (1 * 120) + 10 },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            _log("[multiLangue] Langue sélectionnée: Français")
            if _G.localization and _G.localization.setLanguage then
                _G.localization.setLanguage('fr')
                _log("[multiLangue] Langue changée vers: fr")
            end
        end
    },

    english = {
        texte = 'English',
        langue = 'en',
        width = (positions.buttons and positions.buttons.english and positions.buttons.english.clickZone and positions.buttons.english.clickZone.width) or
            300,
        height = (positions.buttons and positions.buttons.english and positions.buttons.english.clickZone and positions.buttons.english.clickZone.height) or
            80,
        vector2 = (positions.buttons and positions.buttons.english and positions.buttons.english.clickZone) or
            { x = 60, y = screen.gameReso.height / 2 + (2 * 120) + 20 },
        flagPos = (positions.buttons and positions.buttons.english and positions.buttons.english.flag) or
            { x = 60, y = screen.gameReso.height / 2 + (2 * 120) + 60 },
        textPos = (positions.buttons and positions.buttons.english and positions.buttons.english.text) or
            { x = 60, y = screen.gameReso.height / 2 + (2 * 120) + 30 },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            _log("[multiLangue] Langue sélectionnée: English")
            if _G.localization and _G.localization.setLanguage then
                _G.localization.setLanguage('en')
                _log("[multiLangue] Langue changée vers: en")
            end
        end
    },

    retour = {
        texte = 'Retour',
        width = (positions.buttons and positions.buttons.retour and positions.buttons.retour.clickZone and positions.buttons.retour.clickZone.width) or
            180,
        height = (positions.buttons and positions.buttons.retour and positions.buttons.retour.clickZone and positions.buttons.retour.clickZone.height) or
            60,
        vector2 = (positions.buttons and positions.buttons.retour and positions.buttons.retour.clickZone) or
            { x = 60, y = screen.gameReso.height / 2 + (4 * 100) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[multiLangue] Retour au menu principal")
            if multiLangue.onSwitchPanel then
                multiLangue.onSwitchPanel("main")
            end
        end
    }
}

-- Variable d'état pour les clics
multiLangue.isclick = false

-- Callback pour changer de panneau
multiLangue.onSwitchPanel = nil

-- Fonction de chargement
function multiLangue:load()
    _log("[multiLangue] Panneau multilingue chargé")

    -- Charger les drapeaux depuis resources.json
    self:loadFlags()

    -- Mettre à jour les textes selon la langue actuelle
    if _G.localization and _G.localization.get then
        self.buttons.francais.texte = _G.localization.get("menu.language.french") or "Français"
        self.buttons.english.texte = _G.localization.get("menu.language.english") or "English"
        self.buttons.retour.texte = _G.localization.get("menu.back") or "Retour"
    end
end

-- Fonction pour charger les drapeaux depuis resources.json
function multiLangue:loadFlags()
    local resources = config.load() or {}
    _log("[multiLangue] Chargement des drapeaux...")

    if resources and resources.flags then
        -- Charger drapeau français
        if resources.flags.fr then
            self.flags.fr = res.image(resources.flags.fr)
            _log("[multiLangue] ✅ Drapeau français chargé: " .. resources.flags.fr)
        else
            _log("[multiLangue] ❌ Drapeau français non trouvé dans resources")
        end

        -- Charger drapeau anglais
        if resources.flags.en then
            self.flags.en = res.image(resources.flags.en)
            _log("[multiLangue] ✅ Drapeau anglais chargé: " .. resources.flags.en)
        else
            _log("[multiLangue] ❌ Drapeau anglais non trouvé dans resources")
        end
    else
        _log("[multiLangue] ❌ Section 'flags' non trouvée dans resources.json")
    end
end

-- Fonction de mise à jour
function multiLangue:update(dt)
    self:handleInput()
end

-- Gestion des entrées (similaire à mainMenu)
function multiLangue:handleInput()
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
        _log("[multiLangue] Touche Echap détectée → retour au menu principal")
        if multiLangue.onSwitchPanel then
            multiLangue.onSwitchPanel("main")
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
                _log("[multiLangue] Clic détecté sur bouton: " .. (value.texte or "inconnu"))
                if value.action then
                    value.action(value)
                else
                    _log("[multiLangue] ERREUR: bouton sans fonction action")
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
function multiLangue:draw(res, fontPath)
    -- Titre du panneau
    love.graphics.setColor(1, 1, 1)
    if res and res.font and fontPath then
        love.graphics.setFont(res.font(fontPath, 80))
    end
    local titre = (_G.localization and _G.localization.get and _G.localization.get("menu.language.title")) or
        "Sélection de langue"
    love.graphics.print(titre, 60, screen.gameReso.height / 2 - 150)

    -- Rendu des boutons avec drapeaux
    for key, value in pairs(self.buttons) do
        -- Afficher le drapeau pour les boutons de langue (utilise les échelles depuis config)
        if key == "francais" and self.flags.fr then
            love.graphics.setColor(1, 1, 1)
            local scaleX = (positions.buttons and positions.buttons.francais and positions.buttons.francais.flag and positions.buttons.francais.flag.scaleX) or
                0.2
            local scaleY = (positions.buttons and positions.buttons.francais and positions.buttons.francais.flag and positions.buttons.francais.flag.scaleY) or
                0.15
            love.graphics.draw(self.flags.fr, value.flagPos.x, value.flagPos.y, 0, scaleX, scaleY)
        elseif key == "english" and self.flags.en then
            love.graphics.setColor(1, 1, 1)
            local scaleX = (positions.buttons and positions.buttons.english and positions.buttons.english.flag and positions.buttons.english.flag.scaleX) or
                0.2
            local scaleY = (positions.buttons and positions.buttons.english and positions.buttons.english.flag and positions.buttons.english.flag.scaleY) or
                0.15
            love.graphics.draw(self.flags.en, value.flagPos.x, value.flagPos.y, 0, scaleX, scaleY)
        end

        -- Afficher le texte du bouton
        love.graphics.setColor(value.color.curent)
        if res and res.font and fontPath then
            love.graphics.setFont(res.font(fontPath, 60))
        end

        -- Position du texte : à côté du drapeau pour les langues, position normale pour retour
        local textX = value.textPos and value.textPos.x or value.vector2.x
        local textY = value.textPos and value.textPos.y or value.vector2.y

        love.graphics.print(value.texte, textX, textY)
    end
    love.graphics.setColor(1, 1, 1)
end

return multiLangue
