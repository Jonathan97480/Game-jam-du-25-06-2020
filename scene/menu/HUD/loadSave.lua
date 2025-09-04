-- scene/menu/HUD/loadSave.lua
-- Panneau de gestion des sauvegardes avec affichage des slots et suppression

local loadSave = {}

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
local hud = _G.hud

-- Configuration depuis config.lua
local config = safeRequire('scene.menu.config') or {}
local positions = config.LOAD_SAVE or {}

-- helper de log local
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

-- État du panneau
local isVisible = false
local saveSlots = {}
local notification = nil

-- Configuration par défaut si pas dans config.lua
local defaultPositions = {
    title = { x = 60, y = screen.gameReso.height / 2 - 200, fontSize = 60 },
    slotContainer = { x = 60, y = screen.gameReso.height / 2 - 120, width = 600, height = 400 },
    buttons = {
        retour = { x = 60, y = screen.gameReso.height / 2 + 300, width = 180, height = 60 }
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
        success, result = saveManager.loadFromSlot(saveInfo.slot)
    else
        success, result = saveManager.loadFromFile(saveInfo.filename)
    end

    if success then
        showNotification("Partie chargée avec succès !", "success")
        _log("[loadSave] Chargement réussi")
        
        -- Retourner au menu après un délai
        love.timer.performWithDelay(1.5, function()
            if scene and scene.switch then
                scene:switch("scene.gameplay.gameplay")
            end
        end)
    else
        showNotification("Échec du chargement: " .. tostring(result), "error")
        _log("[loadSave] Échec chargement: " .. tostring(result))
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
    if not hud then
        _log("[loadSave] HUD non disponible")
        return
    end

    -- Nettoyer les éléments existants
    loadSave.clearUI()

    -- Titre
    hud.addLabel("loadsave_title", {
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
        -- Aucune sauvegarde trouvée
        hud.addLabel("loadsave_empty", {
            layer = "props",
            x = finalPositions.slotContainer.x,
            y = slotY + 100,
            text = _G.t and _G.t("ui.menu.no_saves") or "Aucune sauvegarde trouvée",
            font = 24,
            color = { 0.7, 0.7, 0.7 },
            align = "left"
        })
    else
        -- Afficher chaque slot
        for i, saveInfo in ipairs(saveSlots) do
            local y = slotY + (i - 1) * slotSpacing
            
            -- Panel de fond pour le slot
            hud.addPanel("loadsave_slot_" .. i, {
                layer = "decor",
                x = finalPositions.slotContainer.x,
                y = y,
                w = finalPositions.slotContainer.width,
                h = slotSpacing - 10,
                bg = { 0.1, 0.1, 0.1, 0.8 }
            })

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
                callback = function()
                    loadSaveSlot(saveInfo)
                end,
                tag = "loadsave"
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
                    callback = function()
                        deleteSaveSlot(saveInfo)
                    end,
                    tag = "loadsave"
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
        callback = function()
            loadSave.hide()
            if loadSave.onSwitchPanel then
                loadSave.onSwitchPanel("main")
            end
        end,
        tag = "loadsave"
    })

    isVisible = true
    _log("[loadSave] Interface créée avec " .. #saveSlots .. " sauvegardes")
end

-- Nettoyer l'interface
function loadSave.clearUI()
    if not hud then return end

    -- Supprimer tous les éléments avec tag "loadsave"
    hud.clearByTag("loadsave")
    
    -- Supprimer éléments spécifiques
    local elements = {
        "loadsave_title",
        "loadsave_empty"
    }
    
    for _, element in ipairs(elements) do
        hud.removeElement(element)
    end

    -- Supprimer slots dynamiques
    for i = 1, 20 do -- Maximum 20 slots
        hud.removeElement("loadsave_slot_" .. i)
        hud.removeElement("loadsave_name_" .. i)
        hud.removeElement("loadsave_info_" .. i)
        hud.removeElement("loadsave_load_" .. i)
        hud.removeElement("loadsave_delete_" .. i)
    end

    isVisible = false
end

-- =========================================================================
-- INTERFACE PUBLIQUE
-- =========================================================================

-- Afficher le panneau
function loadSave.show()
    _log("[loadSave] Affichage du panneau de chargement")
    loadSave.createUI()
end

-- Masquer le panneau
function loadSave.hide()
    _log("[loadSave] Masquage du panneau de chargement")
    loadSave.clearUI()
end

-- Vérifier si visible
function loadSave.isVisible()
    return isVisible
end

-- Définir callback de navigation
function loadSave.setOnSwitchPanel(callback)
    loadSave.onSwitchPanel = callback
end

-- Mettre à jour (pour notifications)
function loadSave.update(dt)
    updateNotification(dt)
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
        local x = (screen.gameReso.width / 2) - 100  -- Position approximative
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
