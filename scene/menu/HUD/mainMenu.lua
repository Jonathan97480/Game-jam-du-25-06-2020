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
local panelConfig = positions.buttonPanel or { x = 60, y = screen.gameReso.height / 2 - 50, width = 300, height = 500 }

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
    if not saveManager then
        _log("[mainMenu] SaveManager non disponible")
        return false
    end
    local saves = saveManager.getSaveSlots() or {}
    _log("[mainMenu] Nombre de sauvegardes trouvées: " .. #saves)
    return #saves > 0
end

-- Fonction pour forcer l'affichage du bouton (temporaire pour debug)
local function debugShowLoadSave()
    -- Toujours montrer le bouton loadSave maintenant
    return true
end

-- Fonction pour créer le panel conteneur des boutons
local function createButtonPanel()
    if not _G.hud then
        _log("[mainMenu] HUD non disponible pour créer le panel")
        return false
    end

    local hud = _G.hud

    -- Créer le panel conteneur
    hud.setPanel("main_menu_buttons_panel",
        panelConfig.x,
        panelConfig.y,
        panelConfig.width,
        panelConfig.height,
        { layer = "background" },
        { type = "container", color = { 0, 0, 0, 0 } }
    )

    _log("[mainMenu] Panel conteneur créé à position: " .. panelConfig.x .. ", " .. panelConfig.y)
    return true
end

-- Fonction pour calculer la taille du texte (estimation approximative fiable)
local function getTextDimensions(text, fontSize)
    if not text then return 0, 0 end

    local textStr = tostring(text)
    local size = fontSize or 20 -- Taille par défaut

    -- Estimation basée sur la largeur moyenne des caractères
    local charWidth = size * 0.6 -- Ratio largeur/hauteur approximatif
    local width = #textStr * charWidth
    local height = size

    return width, height
end

-- Fonction pour organiser automatiquement les boutons dans le panel
local function organizeButtonsInPanel()
    if not _G.hud then
        _log("[mainMenu] HUD non disponible pour organiser les boutons")
        return 0, 0
    end

    -- Configuration de base
    local fontSize = 20
    local spacing = 15 -- Espacement entre les boutons
    local startX = 10  -- Marge gauche dans le panel
    local startY = 10  -- Marge haute dans le panel

    local currentY = startY
    local maxWidth = 0

    -- Liste ordonnée des boutons
    local buttonOrder = {
        "play", "continue", "loadSave", "options", "multilingual", "credits", "quit"
    }

    -- Parcourir tous les boutons dans l'ordre défini
    for _, buttonId in ipairs(buttonOrder) do
        local buttonData = mainMenu.buttons[buttonId]

        -- Vérifier si le bouton existe et est visible
        local isVisible = true
        if buttonData and buttonData.visible and type(buttonData.visible) == "function" then
            isVisible = buttonData.visible()
        end

        if buttonData and isVisible then
            -- Obtenir le texte du bouton
            local displayText = ""
            if type(buttonData.texte) == "function" then
                displayText = tostring(buttonData.texte())
            else
                displayText = tostring(buttonData.texte)
            end

            -- Calculer les dimensions du texte
            local textWidth, textHeight = getTextDimensions(displayText, fontSize)

            -- Ajouter du padding au texte pour le bouton
            local buttonWidth = textWidth + 40   -- 20px padding de chaque côté
            local buttonHeight = textHeight + 20 -- 10px padding haut/bas

            -- Mettre à jour la largeur maximale
            if buttonWidth > maxWidth then
                maxWidth = buttonWidth
            end

            -- Calculer la position relative au panel
            local relativeX = startX
            local relativeY = currentY

            -- Mettre à jour les dimensions et position du bouton
            buttonData.width = buttonWidth
            buttonData.height = buttonHeight
            buttonData.vector2 = {
                x = panelConfig.x + relativeX,
                y = panelConfig.y + relativeY
            }

            _log("[mainMenu] Bouton '" ..
                buttonId .. "' positionné à: " .. buttonData.vector2.x .. ", " .. buttonData.vector2.y ..
                " (taille: " .. buttonWidth .. "x" .. buttonHeight .. ")")

            -- Passer au bouton suivant
            currentY = currentY + buttonHeight + spacing
        end
    end

    -- Retourner les dimensions totales utilisées
    return maxWidth, currentY - startY
end -- Fonction pour créer une sauvegarde de test (temporaire)
local function createTestSave()
    if saveManager and saveManager.saveToSlot then
        local success, result = saveManager.saveToSlot(1)
        if success then
            _log("[mainMenu] Sauvegarde de test créée: " .. tostring(result))
        else
            _log("[mainMenu] Échec création sauvegarde test: " .. tostring(result))
        end
    else
        _log("[mainMenu] SaveManager non disponible pour créer sauvegarde test")
    end
end

-- Fonction pour charger la dernière sauvegarde
local function loadLatestSave()
    if not saveManager then
        _log("[mainMenu] SaveManager non disponible")
        return false
    end

    local success, result = saveManager.loadLatestGameAndSetId()

    if success then
        _log("[mainMenu] Dernière sauvegarde chargée avec succès - ID: " .. tostring(_G.idSave))
        if scene and scene.switch then
            scene:switch("scene.gameplay.gameplay")
        end
        return true
    else
        _log("[mainMenu] Échec chargement dernière sauvegarde: " .. tostring(result))
        return false
    end
end

-- Fonction pour créer une nouvelle partie avec sauvegarde automatique
local function createNewGame()
    if not saveManager then
        _log("[mainMenu] SaveManager non disponible")
        return false
    end

    local success, slotId, filename = saveManager.createNewGame()

    if success then
        _log("[mainMenu] Nouvelle partie créée avec succès - ID: " .. slotId .. ", fichier: " .. filename)
        if scene and scene.switch then
            scene:switch("scene.gameplay.gameplay")
        end
        return true
    else
        _log("[mainMenu] Échec création nouvelle partie: " .. tostring(slotId))
        return false
    end
end

-- Configuration des boutons principaux (positions calculées automatiquement)
mainMenu.buttons = {
    play = {
        cmd = 'play',
        texte = function()
            return _G.t and _G.t("ui.menu.play") or "Jouer"
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            if btn and btn.cmd == 'play' then
                -- Le bouton "Jouer" crée toujours une nouvelle partie
                _log("[mainMenu] Nouvelle Partie cliqué → création sauvegarde et lancement")
                createNewGame()
            end
        end
    },

    continue = {
        cmd = 'continue',
        texte = function()
            return _G.t and _G.t("ui.menu.continue") or "Continuer"
        end,
        visible = function()
            -- N'afficher que s'il y a des sauvegardes
            return hasSaves()
        end,
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(btn)
            if btn and btn.cmd == 'continue' then
                _log("[mainMenu] Continuer cliqué → chargement dernière sauvegarde")
                loadLatestSave()
            end
        end
    },

    loadSave = {
        cmd = 'loadsave',
        texte = function()
            return _G.t and _G.t("ui.menu.load_save") or "Charger Partie"
        end,
        visible = function()
            -- N'afficher que s'il y a des sauvegardes (temporairement forcé pour debug)
            return debugShowLoadSave()
        end,
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

    -- Créer le panel conteneur pour les boutons
    createButtonPanel()

    -- Organiser automatiquement les boutons avec le texte de chaque bouton
    local totalWidth, totalHeight = organizeButtonsInPanel()
    _log("[mainMenu] Boutons organisés automatiquement - espace utilisé: " .. totalWidth .. "x" .. totalHeight)

    -- Créer une sauvegarde de test si aucune n'existe (temporaire pour debug)
    if not hasSaves() then
        _log("[mainMenu] Aucune sauvegarde trouvée, création d'une sauvegarde test")
        createTestSave()
    end

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
        self.buttons.credits.texte = _G.localization.get("ui.menu.credits") or "Crédits"
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

        if isVisible then
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
                    _log("[mainMenu] Clic détecté sur bouton: " ..
                        (value.cmd or (type(value.texte) == "function" and value.texte() or value.texte) or "inconnu"))
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
