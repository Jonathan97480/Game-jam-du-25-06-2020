-- scene/menu/HUD/loadSave.lua
-- Panneau de gestion des sauvegardes avec affichage des slots et suppression

local loadSave = {}

-- Fonction d'importation sécurisée
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Accès aux globales avec vérifications défensives
local screen = _G.screen
local scene = _G.scene
local globalFunction = _G.globalFunction
local saveManager = _G.saveManager

-- helper de log local (doit être défini avant les autres fonctions)
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- Fonction pour obtenir HUD de manière sécurisée
local function getHUD()
    return _G.hud
end

-- Fonction helper pour appels HUD sécurisés
local function safeHudCall(methodName, ...)
    local hud = getHUD()
    if hud and hud[methodName] then
        return hud[methodName](...)
    else
        _log("[loadSave] ⚠️ HUD." .. methodName .. " non disponible")
        return false
    end
end

-- Fonction pour valider que HUD est disponible
local function ensureHUD()
    local hud = getHUD()
    if not hud then
        _log("[loadSave] ❌ ERREUR: HUD non initialisé")
        return false
    end

    -- Debug détaillé de l'API HUD
    local missing = {}
    if not hud.addLabel then table.insert(missing, "addLabel") end
    if not hud.addButton then table.insert(missing, "addButton") end
    if not hud.setPanel then table.insert(missing, "setPanel") end
    if not hud.remove then table.insert(missing, "remove") end

    if #missing > 0 then
        _log("[loadSave] ❌ ERREUR: API HUD incomplète, fonctions manquantes: " .. table.concat(missing, ", "))
        return false
    end

    return true
end

-- Configuration depuis config.lua
local config = safeRequire('scene.menu.config') or {}
local positions = config.LOAD_SAVE or {}

-- État du panneau
local isVisible = false
local saveSlots = {}
local notification = nil

-- Configuration par défaut si pas dans config.lua
local defaultPositions = {
    title = { x = 60, y = screen.gameReso.height / 2 - 300, fontSize = 60 },
    slotContainer = { x = 60, y = screen.gameReso.height / 2 - 200, width = 600, height = 400 },
    noSavesMessage = { x = 60, y = screen.gameReso.height / 2 - 100, fontSize = 24 },
    buttons = {
        retour = { x = 60, y = screen.gameReso.height / 2 + 250, width = 180, height = 60 },
        createSave = { x = 260, y = screen.gameReso.height / 2 + 250, width = 200, height = 60 }
    }
}

-- Utiliser positions depuis config ou fallback
local finalPositions = {}
for key, value in pairs(defaultPositions) do
    finalPositions[key] = (positions[key] and positions[key]) or value
end

-- =========================================================================
-- FONCTIONS UTILITAIRES
-- =========================================================================

-- Afficher notification temporaire
local function showNotification(text, type)
    notification = {
        text = text,
        type = type or "info", -- "info", "success", "error"
        timer = 3.0,
        alpha = 1.0
    }
    _log("[loadSave] Notification: " .. text)
end

-- Mettre à jour notification
local function updateNotification(dt)
    -- Vérification de type pour éviter les erreurs
    if type(dt) ~= "number" then
        _log("[loadSave] ⚠️ updateNotification appelée avec dt invalide: " .. type(dt))
        return
    end

    if notification then
        notification.timer = notification.timer - dt
        if notification.timer <= 0.5 then
            notification.alpha = notification.timer / 0.5
        end
        if notification.timer <= 0 then
            notification = nil
        end
    end
end

-- Formater date depuis timestamp
local function formatDate(timestamp)
    return os.date("%d/%m/%Y %H:%M", timestamp)
end

-- Formater taille de fichier
local function formatSize(bytes)
    if bytes < 1024 then
        return bytes .. " B"
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    else
        return string.format("%.1f MB", bytes / (1024 * 1024))
    end
end

-- =========================================================================
-- GESTION DES SAUVEGARDES
-- =========================================================================

-- Rafraîchir la liste des sauvegardes
local function refreshSaveSlots()
    if not saveManager then
        _log("[loadSave] SaveManager non disponible")
        saveSlots = {}
        return
    end

    saveSlots = saveManager.getSaveSlots() or {}
    _log("[loadSave] " .. #saveSlots .. " sauvegardes trouvées")

    -- Debug: afficher les détails des sauvegardes trouvées
    for i, save in ipairs(saveSlots) do
        _log("[loadSave] Sauvegarde " .. i .. ": " .. tostring(save.filename) .. " (slot: " .. tostring(save.slot) .. ")")
    end
end

-- Charger une sauvegarde
local function loadSaveSlot(saveInfo)
    if not saveManager then
        showNotification("SaveManager non disponible", "error")
        return
    end

    _log("[loadSave] Chargement de: " .. saveInfo.filename)

    local success, result
    if saveInfo.slot then
        success, result = saveManager.loadGameAndSetId(saveInfo.slot)
    else
        -- Pour les anciens fichiers, on essaie de récupérer le slot depuis le nom
        local slotFromFilename = saveInfo.filename:match("save_slot_(%d+)%.json")
        if slotFromFilename then
            success, result = saveManager.loadGameAndSetId(tonumber(slotFromFilename))
        else
            success, result = saveManager.loadFromFile(saveInfo.filename)
        end
    end

    if success then
        showNotification("Partie chargée avec succès !", "success")
        _log("[loadSave] Chargement réussi - ID de sauvegarde: " .. tostring(_G.idSave))

        -- Lancer le gameplay immédiatement
        if scene and scene.switch then
            scene:switch("scene.gameplay.gameplay")
        end
    else
        showNotification("Échec du chargement: " .. tostring(result), "error")
        _log("[loadSave] Échec chargement: " .. tostring(result))
    end
end

-- Créer une nouvelle sauvegarde
local function createNewSave()
    if not saveManager then
        showNotification("SaveManager non disponible", "error")
        return
    end

    _log("[loadSave] Création d'une nouvelle sauvegarde")

    -- Créer une sauvegarde vide dans le premier slot disponible
    local success, result = saveManager.saveToSlot(1)

    if success then
        showNotification("Nouvelle partie créée !", "success")
        _log("[loadSave] Nouvelle sauvegarde créée dans le slot 1")

        -- Lancer le gameplay immédiatement
        if scene and scene.switch then
            scene:switch("scene.gameplay.gameplay")
        end
    else
        showNotification("Échec création: " .. tostring(result), "error")
        _log("[loadSave] Échec création nouvelle sauvegarde: " .. tostring(result))
    end
end

-- Supprimer une sauvegarde
local function deleteSaveSlot(saveInfo)
    if not saveManager then
        showNotification("SaveManager non disponible", "error")
        return
    end

    -- Confirmation avant suppression
    if saveInfo.isAutoSave then
        showNotification("Impossible de supprimer une auto-save", "error")
        return
    end

    _log("[loadSave] Suppression de: " .. saveInfo.filename)

    local success, error = saveManager.deleteSave(saveInfo.filename)

    if success then
        showNotification("Sauvegarde supprimée", "success")
        refreshSaveSlots()
        loadSave.createUI() -- Recréer l'interface
    else
        showNotification("Échec suppression: " .. tostring(error), "error")
    end
end

-- =========================================================================
-- INTERFACE UTILISATEUR
-- =========================================================================

-- Créer l'interface principale
function loadSave.createUI()
    if not ensureHUD() then
        _log("[loadSave] ❌ Impossible de créer l'interface: HUD non disponible")
        return
    end

    local hud = getHUD()

    -- Nettoyer les éléments existants
    loadSave.clearUI()

    -- Titre
    safeHudCall("addLabel", "loadsave_title", {
        layer = "props",
        x = finalPositions.title.x,
        y = finalPositions.title.y,
        text = _G.t and _G.t("ui.menu.load_save") or "Charger Partie",
        font = finalPositions.title.fontSize or 60,
        color = { 1, 1, 1 },
        align = "left"
    })

    -- Rafraîchir les sauvegardes
    refreshSaveSlots()

    -- Afficher les slots de sauvegarde
    local slotY = finalPositions.slotContainer.y
    local slotSpacing = 80

    if #saveSlots == 0 then
        -- Aucune sauvegarde trouvée - affichage message et boutons
        hud.addLabel("loadsave_empty", {
            layer = "props",
            x = finalPositions.noSavesMessage.x,
            y = finalPositions.noSavesMessage.y,
            text = _G.t and _G.t("ui.menu.no_saves") or "Aucune sauvegarde disponible",
            font = finalPositions.noSavesMessage.fontSize or 24,
            color = { 0.7, 0.7, 0.7 },
            align = "left"
        })

        -- Bouton "Créer une sauvegarde"
        hud.addButton("loadsave_create", {
            layer = "button",
            x = finalPositions.buttons.createSave.x,
            y = finalPositions.buttons.createSave.y,
            w = finalPositions.buttons.createSave.width,
            h = finalPositions.buttons.createSave.height,
            text = _G.t and _G.t("ui.menu.create_save") or "Créer une sauvegarde",
            onClick = function()
                _log("[loadSave] ✅ Bouton 'Créer une sauvegarde' cliqué !")
                createNewSave()
            end
        })
    else
        -- Afficher chaque slot
        for i, saveInfo in ipairs(saveSlots) do
            local y = slotY + (i - 1) * slotSpacing

            -- Panel de fond pour le slot
            local hud = getHUD()
            if hud and hud.setPanel then
                hud.setPanel("loadsave_slot_" .. i,
                    finalPositions.slotContainer.x,
                    y,
                    finalPositions.slotContainer.width,
                    slotSpacing - 10,
                    { layer = "decor" },               -- opts
                    { color = { 0.1, 0.1, 0.1, 0.8 } } -- options
                )
            else
                _log("[loadSave] ⚠️ HUD non disponible pour setPanel")
            end

            -- Nom de la sauvegarde
            local displayName = saveInfo.displayName or ("Sauvegarde " .. i)
            if saveInfo.isAutoSave then
                displayName = "Auto-save - " .. formatDate(saveInfo.timestamp)
            elseif saveInfo.slot then
                displayName = "Slot " .. saveInfo.slot .. " - " .. formatDate(saveInfo.timestamp)
            end

            hud.addLabel("loadsave_name_" .. i, {
                layer = "props",
                x = finalPositions.slotContainer.x + 10,
                y = y + 10,
                text = displayName,
                font = 18,
                color = { 1, 1, 1 },
                align = "left"
            })

            -- Informations additionnelles
            local infoText = formatSize(saveInfo.size or 0)
            if saveInfo.playTime then
                local hours = math.floor(saveInfo.playTime / 3600)
                local minutes = math.floor((saveInfo.playTime % 3600) / 60)
                infoText = infoText .. " | " .. string.format("%dh %02dm", hours, minutes)
            end

            hud.addLabel("loadsave_info_" .. i, {
                layer = "props",
                x = finalPositions.slotContainer.x + 10,
                y = y + 35,
                text = infoText,
                font = 14,
                color = { 0.7, 0.7, 0.7 },
                align = "left"
            })

            -- Bouton Charger
            hud.addButton("loadsave_load_" .. i, {
                layer = "button",
                x = finalPositions.slotContainer.x + finalPositions.slotContainer.width - 180,
                y = y + 10,
                w = 80,
                h = 30,
                text = _G.t and _G.t("ui.common.load") or "Charger",
                onClick = function()
                    loadSaveSlot(saveInfo)
                end
            })

            -- Bouton Supprimer (sauf pour auto-saves)
            if not saveInfo.isAutoSave then
                hud.addButton("loadsave_delete_" .. i, {
                    layer = "button",
                    x = finalPositions.slotContainer.x + finalPositions.slotContainer.width - 90,
                    y = y + 10,
                    w = 70,
                    h = 30,
                    text = _G.t and _G.t("ui.common.delete") or "Suppr",
                    color = { 0.8, 0.3, 0.3 },
                    onClick = function()
                        deleteSaveSlot(saveInfo)
                    end
                })
            end
        end
    end

    -- Bouton Retour
    hud.addButton("loadsave_retour", {
        layer = "button",
        x = finalPositions.buttons.retour.x,
        y = finalPositions.buttons.retour.y,
        w = finalPositions.buttons.retour.width,
        h = finalPositions.buttons.retour.height,
        text = _G.t and _G.t("ui.common.back") or "Retour",
        onClick = function()
            _log("[loadSave] ✅ Bouton 'Retour' cliqué !")
            loadSave.hide()
            if loadSave.onSwitchPanel then
                loadSave.onSwitchPanel("main")
            end
        end
    })

    isVisible = true
    _log("[loadSave] Interface créée avec " .. #saveSlots .. " sauvegardes")
end

-- Nettoyer l'interface
function loadSave.clearUI()
    if not hud then return end

    -- Supprimer éléments spécifiques
    local elements = {
        "loadsave_title",
        "loadsave_empty",
        "loadsave_create",
        "loadsave_retour"
    }

    for _, element in ipairs(elements) do
        if hud.remove then
            hud.remove(element)
        end
    end

    -- Supprimer slots dynamiques
    for i = 1, 20 do -- Maximum 20 slots
        local slotElements = {
            "loadsave_slot_" .. i,
            "loadsave_name_" .. i,
            "loadsave_info_" .. i,
            "loadsave_load_" .. i,
            "loadsave_delete_" .. i
        }

        for _, element in ipairs(slotElements) do
            if hud.remove then
                hud.remove(element)
            end
        end
    end

    isVisible = false
end

-- =========================================================================
-- INTERFACE PUBLIQUE
-- =========================================================================

-- Afficher le panneau
function loadSave.show()
    _log("[loadSave] *** Affichage du panneau de chargement - DEBUG ***")
    isVisible = true
    loadSave.createUI()
    _log("[loadSave] *** Interface créée ***")
end

-- Masquer le panneau
function loadSave.hide()
    _log("[loadSave] Masquage du panneau de chargement")
    loadSave.clearUI()
    isVisible = false
end

-- Vérifier si visible
function loadSave.isVisible()
    return isVisible
end

-- Définir callback de navigation
function loadSave.setOnSwitchPanel(callback)
    loadSave.onSwitchPanel = callback
end

-- Mettre à jour (pour notifications et input)
function loadSave:update(dt)
    updateNotification(dt)

    -- Gestion de la touche Échap pour retourner au menu principal
    if isVisible then
        local escPressed = false

        -- Méthode simple et fiable : vérification directe avec love.keyboard
        if love.keyboard.isDown("escape") then
            if not loadSave._escWasPressed then
                escPressed = true
                loadSave._escWasPressed = true
            end
        else
            loadSave._escWasPressed = false
        end

        if escPressed then
            _log("[loadSave] Touche Échap pressée, retour au menu principal")
            loadSave.hide()
            if loadSave.onSwitchPanel then
                loadSave.onSwitchPanel("main")
            end
        end
    end
end

-- Rendu des notifications
function loadSave.draw()
    if notification then
        love.graphics.push()
        love.graphics.setColor(1, 1, 1, notification.alpha)

        local colors = {
            info = { 0.3, 0.3, 1 },
            success = { 0.3, 1, 0.3 },
            error = { 1, 0.3, 0.3 }
        }

        local bgColor = colors[notification.type] or colors.info

        -- Fond de notification
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.8 * notification.alpha)
        love.graphics.rectangle("fill", screen.gameReso.width / 2 - 200, 50, 400, 60)

        -- Texte de notification (centré approximativement)
        love.graphics.setColor(1, 1, 1, notification.alpha)
        local x = (screen.gameReso.width / 2) - 100 -- Position approximative
        love.graphics.print(notification.text, x, 70)

        love.graphics.pop()
    end
end

-- =========================================================================
-- FONCTIONS UTILITAIRES PUBLIQUES
-- =========================================================================

-- Vérifier s'il y a des sauvegardes disponibles
function loadSave.hasSaves()
    if not saveManager then return false end

    local saves = saveManager.getSaveSlots() or {}
    return #saves > 0
end

-- Obtenir le nombre de sauvegardes
function loadSave.getSaveCount()
    if not saveManager then return 0 end

    local saves = saveManager.getSaveSlots() or {}
    return #saves
end

return loadSave
