-- =========================================================================
-- PHASE 3.1 : Améliorations visuelles et feedback UX
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 2 septembre 2025
-- Description: Module pour améliorer les feedback visuels du système de cartes
-- Dépendances: Phases 1 & 2 (système énergétique et cartes opérationnel)
-- =========================================================================

local visualFeedback = {}

-- Dépendances
local globalFunction = _G.globalFunction
local hud = _G.hud

-- Configuration des couleurs pour feedback
local COLORS = {
    ENERGY_OK = { 0.3, 1.0, 0.3, 1.0 },         -- Vert pour énergie suffisante
    ENERGY_LOW = { 1.0, 0.8, 0.3, 1.0 },        -- Orange pour énergie faible
    ENERGY_INSUFFICIENT = { 1.0, 0.3, 0.3, 1.0 }, -- Rouge pour énergie insuffisante
    CARD_PLAYABLE = { 0.9, 0.9, 0.9, 1.0 },     -- Blanc pour carte jouable
    CARD_BLOCKED = { 0.5, 0.5, 0.5, 0.8 },      -- Gris pour carte non jouable
    STANDBY_GLOW = { 0.3, 0.7, 1.0, 0.8 },      -- Bleu pour carte en standby
    CONFIRM_GLOW = { 0.3, 1.0, 0.3, 1.0 }       -- Vert pour confirmation
}

-- Messages de feedback pour le joueur
local FEEDBACK_MESSAGES = {
    ENERGY_INSUFFICIENT = "⚡ Énergie insuffisante !",
    CARD_PLAYED = "✅ Carte jouée !",
    ENERGY_RESTORED = "🔋 Énergie restaurée : 8 points",
    STANDBY_ACTIVE = "🎯 Sélectionnez une cible",
    STANDBY_CANCELLED = "❌ Action annulée"
}

-- État du feedback visuel
local feedbackState = {
    energyColor = COLORS.ENERGY_OK,
    lastEnergyValue = 8,
    messageQueue = {},
    messageTimer = 0,
    glowEffects = {}
}

-- =========================================================================
-- SYSTÈME DE FEEDBACK ÉNERGÉTIQUE
-- =========================================================================

---Mise à jour des couleurs d'interface selon l'énergie disponible
---@param currentEnergy number Énergie actuelle du joueur
---@param maxEnergy number Énergie maximale (défaut: 8)
function visualFeedback.updateEnergyFeedback(currentEnergy, maxEnergy)
    maxEnergy = maxEnergy or 8

    -- Déterminer la couleur selon le niveau d'énergie
    local energyRatio = currentEnergy / maxEnergy

    if energyRatio <= 0.2 then
        feedbackState.energyColor = COLORS.ENERGY_INSUFFICIENT
    elseif energyRatio <= 0.5 then
        feedbackState.energyColor = COLORS.ENERGY_LOW
    else
        feedbackState.energyColor = COLORS.ENERGY_OK
    end

    -- Mettre à jour l'affichage HUD si disponible
    if hud and hud.setTextColor then
        hud.setTextColor("energy_display", feedbackState.energyColor)
    end

    -- Détecter changements significatifs
    if currentEnergy < feedbackState.lastEnergyValue then
        local energyUsed = feedbackState.lastEnergyValue - currentEnergy
        visualFeedback.showMessage(string.format("⚡ -%d énergie", energyUsed), 1.5)
    elseif currentEnergy > feedbackState.lastEnergyValue and currentEnergy == maxEnergy then
        visualFeedback.showMessage(FEEDBACK_MESSAGES.ENERGY_RESTORED, 2.0)
    end

    feedbackState.lastEnergyValue = currentEnergy

    -- Log pour debug
    if globalFunction and globalFunction.log then
        globalFunction.log.info(string.format("Energy feedback: %d/%d (%.1f%%) - Color updated",
            currentEnergy, maxEnergy, energyRatio * 100))
    end
end

---Vérifier si une carte peut être jouée et appliquer feedback visuel
---@param card table Données de la carte
---@param currentEnergy number Énergie disponible
---@return boolean canPlay Si la carte peut être jouée
function visualFeedback.checkCardPlayability(card, currentEnergy)
    if not card then return false end

    -- Calculer le coût de la carte
    local cardCost = card.PowerBlow or card.cost or card.power or 0
    local canPlay = currentEnergy >= cardCost

    -- Appliquer feedback visuel sur la carte
    if card.visual then
        if canPlay then
            card.visual.tint = COLORS.CARD_PLAYABLE
            card.visual.opacity = 1.0
        else
            card.visual.tint = COLORS.CARD_BLOCKED
            card.visual.opacity = 0.7
        end
    end

    return canPlay
end

-- =========================================================================
-- SYSTÈME DE FEEDBACK STANDBY ET CIBLAGE
-- =========================================================================

---Appliquer effet visuel pour carte en standby
---@param card table Carte mise en standby
function visualFeedback.applyStandbyGlow(card)
    if not card then return end

    -- Ajouter effet de brillance
    local glowEffect = {
        card = card,
        startTime = love.timer and love.timer.getTime() or 0,
        type = "standby",
        color = COLORS.STANDBY_GLOW
    }

    table.insert(feedbackState.glowEffects, glowEffect)

    -- Message informatif
    visualFeedback.showMessage(FEEDBACK_MESSAGES.STANDBY_ACTIVE, 3.0)

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Standby glow applied to card: " .. (card.name or "Unknown"))
    end
end

---Appliquer effet visuel pour confirmation de jeu
---@param card table Carte confirmée
function visualFeedback.applyConfirmGlow(card)
    if not card then return end

    -- Effet de confirmation
    local confirmEffect = {
        card = card,
        startTime = love.timer and love.timer.getTime() or 0,
        type = "confirm",
        color = COLORS.CONFIRM_GLOW,
        duration = 1.0
    }

    table.insert(feedbackState.glowEffects, confirmEffect)

    -- Message de succès
    visualFeedback.showMessage(FEEDBACK_MESSAGES.CARD_PLAYED, 2.0)
end

---Supprimer tous les effets visuels d'une carte
---@param card table Carte à nettoyer
function visualFeedback.clearCardEffects(card)
    if not card then return end

    -- Supprimer les effets de la liste
    for i = #feedbackState.glowEffects, 1, -1 do
        if feedbackState.glowEffects[i].card == card then
            table.remove(feedbackState.glowEffects, i)
        end
    end

    -- Restaurer apparence normale
    if card.visual then
        card.visual.tint = COLORS.CARD_PLAYABLE
        card.visual.opacity = 1.0
    end
end

-- =========================================================================
-- SYSTÈME DE MESSAGES INFORMATIFS
-- =========================================================================

---Afficher un message temporaire à l'écran
---@param message string Message à afficher
---@param duration number Durée d'affichage en secondes
function visualFeedback.showMessage(message, duration)
    duration = duration or 2.0

    local messageData = {
        text = message,
        startTime = love.timer and love.timer.getTime() or 0,
        duration = duration,
        alpha = 1.0
    }

    table.insert(feedbackState.messageQueue, messageData)

    -- Limiter le nombre de messages simultanés
    if #feedbackState.messageQueue > 3 then
        table.remove(feedbackState.messageQueue, 1)
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Visual message: " .. message)
    end
end

---Afficher message d'erreur pour énergie insuffisante
---@param cardCost number Coût de la carte
---@param currentEnergy number Énergie disponible
function visualFeedback.showInsufficientEnergyError(cardCost, currentEnergy)
    local message = string.format("⚡ Besoin de %d énergie (disponible: %d)", cardCost, currentEnergy)
    visualFeedback.showMessage(message, 2.5)

    -- Effet visuel d'erreur sur l'affichage énergie
    if hud and hud.animateColor then
        hud.animateColor("energy_display", COLORS.ENERGY_INSUFFICIENT, 0.5)
    end
end

-- =========================================================================
-- MISE À JOUR ET RENDU
-- =========================================================================

---Mise à jour des effets visuels (à appeler dans update)
---@param dt number Delta time
function visualFeedback.update(dt)
    local currentTime = love.timer and love.timer.getTime() or 0

    -- Mise à jour des effets de brillance
    for i = #feedbackState.glowEffects, 1, -1 do
        local effect = feedbackState.glowEffects[i]
        local elapsed = currentTime - effect.startTime

        -- Supprimer les effets expirés
        if effect.duration and elapsed > effect.duration then
            table.remove(feedbackState.glowEffects, i)
        else
            -- Mise à jour de l'effet (pulsation)
            if effect.card and effect.card.visual then
                local pulse = 0.8 + 0.2 * math.sin(elapsed * 4)
                effect.card.visual.glowIntensity = pulse
            end
        end
    end

    -- Mise à jour des messages
    for i = #feedbackState.messageQueue, 1, -1 do
        local msg = feedbackState.messageQueue[i]
        local elapsed = currentTime - msg.startTime

        if elapsed > msg.duration then
            table.remove(feedbackState.messageQueue, i)
        else
            -- Fade out progressif
            local fadeStart = msg.duration * 0.7
            if elapsed > fadeStart then
                local fadeProgress = (elapsed - fadeStart) / (msg.duration - fadeStart)
                msg.alpha = 1.0 - fadeProgress
            end
        end
    end
end

---Rendu des messages à l'écran (à appeler dans draw)
function visualFeedback.drawMessages()
    if not love.graphics then return end

    local screenWidth = love.graphics.getWidth()
    local startY = 100

    for i, msg in ipairs(feedbackState.messageQueue) do
        love.graphics.setColor(1, 1, 1, msg.alpha)

        -- Position centrée horizontalement
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(msg.text)
        local x = (screenWidth - textWidth) / 2
        local y = startY + (i - 1) * 30

        -- Ombre pour lisibilité
        love.graphics.setColor(0, 0, 0, msg.alpha * 0.8)
        love.graphics.print(msg.text, x + 2, y + 2)

        -- Texte principal
        love.graphics.setColor(1, 1, 1, msg.alpha)
        love.graphics.print(msg.text, x, y)
    end

    -- Restaurer couleur par défaut
    love.graphics.setColor(1, 1, 1, 1)
end

-- =========================================================================
-- INTÉGRATION AVEC LE SYSTÈME EXISTANT
-- =========================================================================

---Intégrer le feedback visuel avec le système de cartes existant
function visualFeedback.integreateWithCardSystem()
    -- Hook dans le système de jeu de cartes
    local originalPlayCard = _G.card_effects and _G.card_effects.applyCardEffect

    if originalPlayCard then
        _G.card_effects.applyCardEffectWithFeedback = function(card, source, target)
            -- Appliquer effet de confirmation
            visualFeedback.applyConfirmGlow(card)

            -- Exécuter l'effet original
            return originalPlayCard(card, source, target)
        end
    end

    -- Hook dans le système standby
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay then
        local originalPutInStandby = CardStandbyPlay.putCardInStandby
        if originalPutInStandby then
            CardStandbyPlay.putCardInStandbyWithFeedback = function(card, index)
                -- Appliquer feedback visuel
                visualFeedback.applyStandbyGlow(card)

                -- Exécuter fonction originale
                return originalPutInStandby(card, index)
            end
        end
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Visual feedback integrated with card system")
    end
end

-- =========================================================================
-- API PUBLIQUE
-- =========================================================================

-- Exposer le module globalement
_G.visualFeedback = visualFeedback

-- Initialiser l'intégration
visualFeedback.integreateWithCardSystem()

return visualFeedback
