-- =========================================================================
-- PHASE 3.1 : Module d'intégration et coordination
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 2 septembre 2025
-- Description: Coordonne tous les modules Phase 3 et les intègre au jeu
-- Dépendances: Phase 1 & 2 complètes, modules Phase 3
-- =========================================================================

local phase3Integration = {}

-- Dépendances
local globalFunction = _G.globalFunction

-- État de l'intégration
local integrationState = {
    initialized = false,
    modulesLoaded = {},
    active = false,
    errorLog = {}
}

-- =========================================================================
-- CHARGEMENT DES MODULES PHASE 3
-- =========================================================================

---Charger un module Phase 3 de manière sécurisée
---@param moduleName string Nom du module
---@param modulePath string Chemin vers le module
---@return boolean success Si le chargement a réussi
function phase3Integration.loadModule(moduleName, modulePath)
    local success, module = pcall(require, modulePath)

    if success and module then
        integrationState.modulesLoaded[moduleName] = module

        if globalFunction and globalFunction.log then
            globalFunction.log.info("Phase 3 module loaded: " .. moduleName)
        end
        return true
    else
        local errorMsg = "Failed to load Phase 3 module: " .. moduleName .. " (" .. tostring(module) .. ")"
        table.insert(integrationState.errorLog, errorMsg)

        if globalFunction and globalFunction.log then
            globalFunction.log.error(errorMsg)
        end
        return false
    end
end

---Charger tous les modules Phase 3
function phase3Integration.loadAllModules()
    local moduleList = {
        { "visualFeedback",    "my-librairie/phase3/visual_feedback" },
        { "keyboardShortcuts", "my-librairie/phase3/keyboard_shortcuts" },
        { "tooltipSystem",     "my-librairie/phase3/tooltip_system" }
    }

    local loadedCount = 0

    for _, moduleInfo in ipairs(moduleList) do
        local moduleName, modulePath = moduleInfo[1], moduleInfo[2]
        if phase3Integration.loadModule(moduleName, modulePath) then
            loadedCount = loadedCount + 1
        end
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info(string.format("Phase 3: %d/%d modules loaded successfully", loadedCount, #moduleList))
    end

    return loadedCount == #moduleList
end

-- =========================================================================
-- INTÉGRATION AVEC LE SYSTÈME EXISTANT
-- =========================================================================

---Intégrer le feedback visuel avec le système de cartes
function phase3Integration.integrateVisualFeedback()
    local visualFeedback = integrationState.modulesLoaded.visualFeedback
    if not visualFeedback then return false end

    -- Hook dans le système énergétique
    local Hero = _G.Hero
    if Hero and Hero.actor and Hero.actor.state then
        -- Monitoring énergie en continu
        phase3Integration.setupEnergyMonitoring(visualFeedback)
    end

    -- Hook dans le système de cartes
    local Card = _G.Card
    if Card then
        phase3Integration.setupCardFeedback(visualFeedback)
    end

    -- Hook dans CardStandbyPlay
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay then
        phase3Integration.setupStandbyFeedback(visualFeedback)
    end

    return true
end

---Configurer le monitoring de l'énergie
---@param visualFeedback table Module de feedback visuel
function phase3Integration.setupEnergyMonitoring(visualFeedback)
    local Hero = _G.Hero
    if not Hero or not Hero.actor then return end

    -- Surveiller les changements d'énergie
    local lastEnergy = Hero.actor.state.power or 8

    -- Fonction de mise à jour (sera appelée dans update)
    phase3Integration.updateEnergyFeedback = function()
        local currentEnergy = Hero.actor.state.power or 8

        if currentEnergy ~= lastEnergy then
            visualFeedback.updateEnergyFeedback(currentEnergy, 8)
            lastEnergy = currentEnergy
        end
    end
end

---Configurer le feedback pour les cartes
---@param visualFeedback table Module de feedback visuel
function phase3Integration.setupCardFeedback(visualFeedback)
    local Card = _G.Card
    if not Card then return end

    -- Hook dans le système de jeu de cartes
    local originalPlayCard = _G.card_effects and _G.card_effects.applyCardEffect

    if originalPlayCard then
        _G.card_effects.applyCardEffectWithVisualFeedback = function(card, source, target)
            -- Feedback de confirmation
            if visualFeedback.applyConfirmGlow then
                visualFeedback.applyConfirmGlow(card)
            end

            -- Exécuter l'effet original
            local result = originalPlayCard(card, source, target)

            -- Feedback post-jeu
            if result and visualFeedback.showMessage then
                local cardName = card.name or "Carte"
                visualFeedback.showMessage("✅ " .. cardName .. " jouée !", 1.5)
            end

            return result
        end
    end
end

---Configurer le feedback pour le système standby
---@param visualFeedback table Module de feedback visuel
function phase3Integration.setupStandbyFeedback(visualFeedback)
    local CardStandbyPlay = _G.CardStandbyPlay
    if not CardStandbyPlay then return end

    -- Hook mise en standby
    local originalPutInStandby = CardStandbyPlay.putCardInStandby
    if originalPutInStandby then
        CardStandbyPlay.putCardInStandbyWithFeedback = function(card, index)
            local result = originalPutInStandby(card, index)

            if result and visualFeedback.applyStandbyGlow then
                visualFeedback.applyStandbyGlow(card)
            end

            return result
        end
    end

    -- Hook annulation standby
    local originalReturnToHand = CardStandbyPlay.returnCardToHand
    if originalReturnToHand then
        CardStandbyPlay.returnCardToHandWithFeedback = function()
            local card = CardStandbyPlay.getStandbyCopy()
            local result = originalReturnToHand()

            if result and card and visualFeedback.clearCardEffects then
                visualFeedback.clearCardEffects(card)
            end

            return result
        end
    end
end

---Intégrer les raccourcis clavier
function phase3Integration.integrateKeyboardShortcuts()
    local keyboardShortcuts = integrationState.modulesLoaded.keyboardShortcuts
    if not keyboardShortcuts then return false end

    -- Hook dans le système d'input LÖVE2D
    local originalKeypressed = love.keypressed

    love.keypressed = function(key, scancode, isrepeat)
        -- Laisser les raccourcis Phase 3 traiter en premier
        local handled = keyboardShortcuts.handleKeyPress(key)

        -- Si pas traité, passer à l'ancien système
        if not handled and originalKeypressed then
            originalKeypressed(key, scancode, isrepeat)
        end
    end

    return true
end

---Intégrer le système de tooltips
function phase3Integration.integrateTooltipSystem()
    local tooltipSystem = integrationState.modulesLoaded.tooltipSystem
    if not tooltipSystem then return false end

    -- Ajouter tooltips aux cartes existantes
    phase3Integration.addCardTooltips(tooltipSystem)

    -- Ajouter tooltip à l'affichage d'énergie
    phase3Integration.addEnergyTooltip(tooltipSystem)

    -- Hook dans le système de rendu
    phase3Integration.setupTooltipRendering(tooltipSystem)

    return true
end

---Ajouter tooltips aux cartes
---@param tooltipSystem table Module de tooltips
function phase3Integration.addCardTooltips(tooltipSystem)
    local Card = _G.Card
    if not Card or not Card.hand then return end

    -- Cette fonction sera appelée pour mettre à jour les tooltips des cartes
    phase3Integration.updateCardTooltips = function()
        for i, card in ipairs(Card.hand) do
            if card and card.visual then
                -- Ajouter zone de hover pour la carte
                card.tooltipData = {
                    type = "card",
                    data = card
                }
            end
        end
    end
end

---Ajouter tooltip à l'affichage d'énergie
---@param tooltipSystem table Module de tooltips
function phase3Integration.addEnergyTooltip(tooltipSystem)
    local Hero = _G.Hero
    if not Hero or not Hero.actor then return end

    -- Configuration du tooltip énergie
    phase3Integration.energyTooltipData = {
        type = "energy",
        getData = function()
            local currentEnergy = Hero.actor.state.power or 8
            return { current = currentEnergy, max = 8 }
        end
    }
end

---Configurer le rendu des tooltips
---@param tooltipSystem table Module de tooltips
function phase3Integration.setupTooltipRendering(tooltipSystem)
    -- Hook dans le système de rendu principal
    local originalDraw = love.draw

    love.draw = function()
        -- Rendu normal du jeu
        if originalDraw then
            originalDraw()
        end

        -- Rendu des tooltips par-dessus
        if tooltipSystem.draw then
            tooltipSystem.draw()
        end
    end

    -- Hook dans update pour tooltips
    local originalUpdate = love.update

    love.update = function(dt)
        -- Update normal du jeu
        if originalUpdate then
            originalUpdate(dt)
        end

        -- Update des tooltips
        if tooltipSystem.update then
            tooltipSystem.update(dt)
        end

        -- Update du feedback visuel
        if phase3Integration.updateEnergyFeedback then
            phase3Integration.updateEnergyFeedback()
        end

        -- Update des cartes tooltips
        if phase3Integration.updateCardTooltips then
            phase3Integration.updateCardTooltips()
        end
    end
end

-- =========================================================================
-- GESTION DES INTERACTIONS SOURIS
-- =========================================================================

---Gérer les événements de souris pour les tooltips
function phase3Integration.setupMouseHandling()
    local tooltipSystem = integrationState.modulesLoaded.tooltipSystem
    if not tooltipSystem then return end

    -- Hook mousemoved
    local originalMousemoved = love.mousemoved

    love.mousemoved = function(x, y, dx, dy, istouch)
        -- Traitement normal
        if originalMousemoved then
            originalMousemoved(x, y, dx, dy, istouch)
        end

        -- Vérifier hover sur éléments avec tooltips
        phase3Integration.checkTooltipHovers(x, y)
    end
end

---Vérifier les hovers pour tooltips
---@param mouseX number Position X souris
---@param mouseY number Position Y souris
function phase3Integration.checkTooltipHovers(mouseX, mouseY)
    local tooltipSystem = integrationState.modulesLoaded.tooltipSystem
    if not tooltipSystem then return end

    local foundHover = false

    -- Vérifier hover sur cartes en main
    local Card = _G.Card
    if Card and Card.hand then
        for _, card in ipairs(Card.hand) do
            if card.visual and phase3Integration.isPointInCard(mouseX, mouseY, card) then
                tooltipSystem.startHover("card", card, mouseX, mouseY)
                foundHover = true
                break
            end
        end
    end

    -- Vérifier hover sur affichage énergie (position approximative)
    if not foundHover then
        if phase3Integration.isPointInEnergyDisplay(mouseX, mouseY) then
            local energyData = phase3Integration.energyTooltipData.getData()
            tooltipSystem.startHover("energy", energyData, mouseX, mouseY)
            foundHover = true
        end
    end

    -- Si aucun hover, terminer
    if not foundHover then
        tooltipSystem.endHover()
    end
end

---Vérifier si un point est dans une carte
---@param x number Position X
---@param y number Position Y
---@param card table Données de la carte
---@return boolean isInside Si le point est dans la carte
function phase3Integration.isPointInCard(x, y, card)
    if not card.visual then return false end

    local cardX = card.visual.x or card.x or 0
    local cardY = card.visual.y or card.y or 0
    local cardW = card.visual.width or card.width or 80
    local cardH = card.visual.height or card.height or 120

    return x >= cardX and x <= cardX + cardW and y >= cardY and y <= cardY + cardH
end

---Vérifier si un point est dans l'affichage énergie
---@param x number Position X
---@param y number Position Y
---@return boolean isInside Si le point est dans l'affichage énergie
function phase3Integration.isPointInEnergyDisplay(x, y)
    -- Position approximative de l'affichage énergie (à ajuster selon l'interface)
    local energyX, energyY = 20, 20
    local energyW, energyH = 100, 30

    return x >= energyX and x <= energyX + energyW and y >= energyY and y <= energyY + energyH
end

-- =========================================================================
-- INITIALISATION PRINCIPALE
-- =========================================================================

---Initialiser complètement la Phase 3
---@return boolean success Si l'initialisation a réussi
function phase3Integration.initialize()
    if integrationState.initialized then
        return true
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("🚀 Initializing Phase 3 - Advanced features & UX")
    end

    -- Étape 1: Charger tous les modules
    local modulesLoaded = phase3Integration.loadAllModules()
    if not modulesLoaded then
        if globalFunction and globalFunction.log then
            globalFunction.log.error("Phase 3 initialization failed: modules loading failed")
        end
        return false
    end

    -- Étape 2: Intégrer chaque système
    local integrations = {
        { "Visual Feedback",    phase3Integration.integrateVisualFeedback },
        { "Keyboard Shortcuts", phase3Integration.integrateKeyboardShortcuts },
        { "Tooltip System",     phase3Integration.integrateTooltipSystem },
        { "Mouse Handling",     phase3Integration.setupMouseHandling }
    }

    local successCount = 0
    for _, integration in ipairs(integrations) do
        local name, func = integration[1], integration[2]
        local success = func()

        if success then
            successCount = successCount + 1
            if globalFunction and globalFunction.log then
                globalFunction.log.info("✅ " .. name .. " integrated successfully")
            end
        else
            if globalFunction and globalFunction.log then
                globalFunction.log.error("❌ " .. name .. " integration failed")
            end
        end
    end

    integrationState.initialized = true
    integrationState.active = successCount == #integrations

    if globalFunction and globalFunction.log then
        globalFunction.log.info(string.format("🎉 Phase 3 initialization complete: %d/%d systems active", successCount,
            #integrations))
    end

    return integrationState.active
end

---Activer/désactiver la Phase 3
---@param active boolean État d'activation
function phase3Integration.setActive(active)
    integrationState.active = active

    -- Activer/désactiver les raccourcis clavier
    local keyboardShortcuts = integrationState.modulesLoaded.keyboardShortcuts
    if keyboardShortcuts and keyboardShortcuts.setEnabled then
        keyboardShortcuts.setEnabled(active)
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Phase 3 set to: " .. (active and "active" or "inactive"))
    end
end

---Obtenir l'état de la Phase 3
---@return table status État détaillé
function phase3Integration.getStatus()
    return {
        initialized = integrationState.initialized,
        active = integrationState.active,
        modulesLoaded = integrationState.modulesLoaded,
        errorLog = integrationState.errorLog
    }
end

-- =========================================================================
-- EXPOSITION GLOBALE ET INITIALISATION AUTO
-- =========================================================================

-- Exposer globalement
_G.phase3Integration = phase3Integration

-- Initialisation automatique si les dépendances sont disponibles
if _G.card_effects and _G.Hero and _G.Card then
    phase3Integration.initialize()
else
    if globalFunction and globalFunction.log then
        globalFunction.log.warn("Phase 3 waiting for dependencies (card_effects, Hero, Card)")
    end
end

return phase3Integration
