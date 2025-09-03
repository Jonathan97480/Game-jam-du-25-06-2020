-- scene/menu/HUD/MultiLangue.lua
-- Panneau de sélection de langue

local multiLangue = {}

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

-- Configuration des boutons de langue
multiLangue.buttons = {
    francais = {
        texte = 'Français',
        langue = 'fr',
        width = 200,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (1 * 80) },
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
        width = 200,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (2 * 80) },
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
        width = 180,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (4 * 80) },
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

    -- Mettre à jour les textes selon la langue actuelle
    if _G.localization and _G.localization.get then
        self.buttons.francais.texte = _G.localization.get("menu.language.french") or "Français"
        self.buttons.english.texte = _G.localization.get("menu.language.english") or "English"
        self.buttons.retour.texte = _G.localization.get("menu.back") or "Retour"
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

return multiLangue
