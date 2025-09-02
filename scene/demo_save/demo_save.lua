-- =========================================================================
-- SCENE DEMO SAVE SYSTEM - Démonstration Système de Sauvegarde
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 3 septembre 2025
-- Description: Scène de démonstration du système de sauvegarde
-- =========================================================================

local scene_demo_save = {
    name = "demo_save"
}

-- État de la scène
local isLoaded = false
local showSaveMenu = false

-- =========================================================================
-- LIFECYCLE METHODS
-- =========================================================================

function scene_demo_save:load()
    print("[scene_demo_save] Chargement de la scène de démonstration")

    -- Vérifier que les systèmes sont disponibles
    if not _G.saveManager then
        print("[scene_demo_save] ❌ SaveManager non disponible")
        return false
    end

    if not _G.saveUI then
        print("[scene_demo_save] ❌ SaveUI non disponible")
        return false
    end

    if not _G.hud then
        print("[scene_demo_save] ❌ HUD non disponible")
        return false
    end

    print("[scene_demo_save] ✅ Tous les systèmes sont disponibles")
    isLoaded = true
    return true
end

function scene_demo_save:enter()
    print("[scene_demo_save] Entrée dans la scène")

    if not isLoaded then
        print("[scene_demo_save] Scène non chargée correctement")
        return
    end

    -- Créer l'interface HUD
    self:createHUD()

    -- Rafraîchir la liste des sauvegardes
    if _G.saveUI then
        _G.saveUI.refreshSaveList()
    end
end

function scene_demo_save:leave()
    print("[scene_demo_save] Sortie de la scène")

    -- Nettoyer l'interface
    if _G.hud then
        _G.hud.clear()
    end

    -- Masquer l'interface de sauvegarde si ouverte
    if _G.saveUI and _G.saveUI.isVisible() then
        _G.saveUI.hide()
    end

    showSaveMenu = false
end

function scene_demo_save:unload()
    print("[scene_demo_save] Déchargement de la scène")
    isLoaded = false
end

-- =========================================================================
-- INTERFACE UTILISATEUR
-- =========================================================================

function scene_demo_save:createHUD()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Titre
    _G.hud.addLabel("title", {
        layer = "props",
        x = screenW / 2,
        y = 50,
        text = _G.t and _G.t("ui.save_demo.title") or "DÉMONSTRATION SYSTÈME DE SAUVEGARDE",
        font = 32,
        color = { 1, 1, 1 },
        align = "center"
    })

    -- Instructions
    _G.hud.addLabel("instructions", {
        layer = "props",
        x = screenW / 2,
        y = 100,
        text = _G.t and _G.t("ui.save_demo.instructions") or "Testez les fonctionnalités de sauvegarde/chargement",
        font = 16,
        color = { 0.8, 0.8, 0.8 },
        align = "center"
    })

    -- Boutons principaux
    local buttonY = 180
    local buttonSpacing = 80

    -- Bouton Quick Save
    _G.hud.addButton("btn_quick_save", {
        layer = "button",
        x = screenW / 2 - 200,
        y = buttonY,
        w = 180,
        h = 50,
        text = _G.t and _G.t("ui.save_demo.quick_save") or "SAUVEGARDE RAPIDE",
        font = 14,
        color = { 0.2, 0.8, 0.2 },
        textColor = { 1, 1, 1 },
        callback = function()
            self:performQuickSave()
        end
    })

    -- Bouton Quick Load
    _G.hud.addButton("btn_quick_load", {
        layer = "button",
        x = screenW / 2 + 20,
        y = buttonY,
        w = 180,
        h = 50,
        text = _G.t and _G.t("ui.save_demo.quick_load") or "CHARGEMENT RAPIDE",
        font = 14,
        color = { 0.2, 0.2, 0.8 },
        textColor = { 1, 1, 1 },
        callback = function()
            self:performQuickLoad()
        end
    })

    buttonY = buttonY + buttonSpacing

    -- Bouton Ouvrir menu de sauvegarde
    _G.hud.addButton("btn_save_menu", {
        layer = "button",
        x = screenW / 2 - 90,
        y = buttonY,
        w = 180,
        h = 50,
        text = _G.t and _G.t("ui.save_demo.save_menu") or "MENU SAUVEGARDES",
        font = 14,
        color = { 0.8, 0.6, 0.2 },
        textColor = { 1, 1, 1 },
        callback = function()
            self:toggleSaveMenu()
        end
    })

    buttonY = buttonY + buttonSpacing

    -- Informations système
    self:updateSystemInfo()

    -- Bouton Retour
    _G.hud.addButton("btn_back", {
        layer = "button",
        x = 50,
        y = screenH - 80,
        w = 120,
        h = 40,
        text = _G.t and _G.t("ui.common.back") or "RETOUR",
        font = 14,
        color = { 0.6, 0.6, 0.6 },
        textColor = { 1, 1, 1 },
        callback = function()
            self:returnToMenu()
        end
    })
end

function scene_demo_save:updateSystemInfo()
    local screenW = love.graphics.getWidth()

    -- Récupérer les statistiques du système
    local stats = _G.saveManager and _G.saveManager.getStats() or {}

    local infoText = string.format(
        _G.t and _G.t("ui.save_demo.stats_format") or
        "Sauvegardes: %d | Auto-saves: %d | Manuelles: %d\nAuto-save: %s",
        stats.totalSaves or 0,
        stats.autoSaves or 0,
        stats.manualSaves or 0,
        (stats.autoSaveEnabled and (_G.t and _G.t("ui.common.enabled") or "Activé")) or
        (_G.t and _G.t("ui.common.disabled") or "Désactivé")
    )

    _G.hud.addLabel("system_info", {
        layer = "props",
        x = screenW / 2,
        y = 380,
        text = infoText,
        font = 14,
        color = { 0.7, 0.7, 0.7 },
        align = "center"
    })
end

-- =========================================================================
-- FONCTIONNALITÉS DE SAUVEGARDE
-- =========================================================================

function scene_demo_save:performQuickSave()
    print("[scene_demo_save] Tentative de sauvegarde rapide")

    if not _G.saveUI then
        self:showMessage("SaveUI non disponible", "error")
        return
    end

    local success = _G.saveUI.quickSave()
    if success then
        self:showMessage(_G.t and _G.t("ui.save_demo.quick_save_success") or "Sauvegarde rapide réussie !", "success")
        self:updateSystemInfo() -- Mettre à jour les stats
    else
        self:showMessage(_G.t and _G.t("ui.save_demo.quick_save_failed") or "Échec de la sauvegarde rapide", "error")
    end
end

function scene_demo_save:performQuickLoad()
    print("[scene_demo_save] Tentative de chargement rapide")

    if not _G.saveUI then
        self:showMessage("SaveUI non disponible", "error")
        return
    end

    local success = _G.saveUI.quickLoad()
    if success then
        self:showMessage(_G.t and _G.t("ui.save_demo.quick_load_success") or "Chargement rapide réussi !", "success")
        self:updateSystemInfo() -- Mettre à jour les stats
    else
        self:showMessage(_G.t and _G.t("ui.save_demo.quick_load_failed") or "Échec du chargement rapide", "error")
    end
end

function scene_demo_save:toggleSaveMenu()
    print("[scene_demo_save] Basculement du menu de sauvegarde")

    if not _G.saveUI then
        self:showMessage("SaveUI non disponible", "error")
        return
    end

    if _G.saveUI.isVisible() then
        _G.saveUI.hide()
        showSaveMenu = false
        self:showMessage(_G.t and _G.t("ui.save_demo.save_menu_closed") or "Menu fermé", "info")
    else
        _G.saveUI.show("list")
        showSaveMenu = true
        self:showMessage(_G.t and _G.t("ui.save_demo.save_menu_opened") or "Menu ouvert", "info")
    end
end

function scene_demo_save:showMessage(text, type)
    -- Afficher un message temporaire
    local color = { 1, 1, 1 } -- blanc par défaut

    if type == "success" then
        color = { 0.2, 0.8, 0.2 } -- vert
    elseif type == "error" then
        color = { 0.8, 0.2, 0.2 } -- rouge
    elseif type == "info" then
        color = { 0.2, 0.6, 0.8 } -- bleu
    end

    _G.hud.addLabel("message", {
        layer = "props",
        x = love.graphics.getWidth() / 2,
        y = 450,
        text = text,
        font = 16,
        color = color,
        align = "center"
    })

    -- Programmer la suppression du message après 3 secondes
    love.timer.delayed_call(3.0, function()
        if _G.hud then
            _G.hud.remove("message")
        end
    end)
end

function scene_demo_save:returnToMenu()
    print("[scene_demo_save] Retour au menu principal")

    if _G.scene then
        _G.scene:switch("menu/menu")
    end
end

-- =========================================================================
-- MISE À JOUR ET RENDU
-- =========================================================================

function scene_demo_save:update(dt)
    -- Mettre à jour SaveUI si visible
    if _G.saveUI and _G.saveUI.isVisible() and _G.saveUI.update then
        _G.saveUI.update(dt)
    end

    -- Gérer les raccourcis clavier
    if love.keyboard.isDown("f5") then
        -- F5 = Sauvegarde rapide
        self:performQuickSave()
    elseif love.keyboard.isDown("f9") then
        -- F9 = Chargement rapide
        self:performQuickLoad()
    elseif love.keyboard.isDown("escape") then
        -- ESC = Retour ou fermer menu
        if showSaveMenu then
            self:toggleSaveMenu()
        else
            self:returnToMenu()
        end
    end
end

function scene_demo_save:draw()
    -- Fond
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Le HUD sera rendu automatiquement par le système centralisé
    -- SaveUI sera rendu automatiquement si visible
end

-- =========================================================================
-- GESTION DES ÉVÉNEMENTS
-- =========================================================================

function scene_demo_save:keypressed(key)
    if key == "f5" then
        self:performQuickSave()
    elseif key == "f9" then
        self:performQuickLoad()
    elseif key == "escape" then
        if showSaveMenu then
            self:toggleSaveMenu()
        else
            self:returnToMenu()
        end
    end
end

function scene_demo_save:mousepressed(x, y, button)
    -- Transférer les clics vers SaveUI si visible
    if _G.saveUI and _G.saveUI.isVisible() and _G.saveUI.mousepressed then
        _G.saveUI.mousepressed(x, y, button)
    end
end

function scene_demo_save:mousereleased(x, y, button)
    -- Transférer les clics vers SaveUI si visible
    if _G.saveUI and _G.saveUI.isVisible() and _G.saveUI.mousereleased then
        _G.saveUI.mousereleased(x, y, button)
    end
end

return scene_demo_save
