-- =========================================================================
-- PHASE 3.1 : Système de tooltips contextuels
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 2 septembre 2025
-- Description: Affichage d'informations contextuelles pour cartes et interface
-- Dépendances: GlobalFunction, HUD, VisualFeedback
-- =========================================================================

local tooltipSystem = {}

-- Dépendances
local globalFunction = _G.globalFunction
local hud = _G.hud
local responsive = _G.responsive

-- Configuration des tooltips
local TOOLTIP_CONFIG = {
    maxWidth = 300,
    padding = 10,
    fontSize = 14,
    backgroundColor = { 0, 0, 0, 0.9 },
    borderColor = { 0.7, 0.7, 0.7, 1.0 },
    textColor = { 1, 1, 1, 1 },
    borderWidth = 2,
    cornerRadius = 5,
    showDelay = 0.5, -- Délai avant affichage (secondes)
    fadeSpeed = 4.0, -- Vitesse d'apparition/disparition
    offsetX = 15,    -- Décalage par rapport au curseur
    offsetY = -5
}

-- État du système
local tooltipState = {
    currentTooltip = nil,
    hoverStartTime = 0,
    visible = false,
    alpha = 0,
    targetAlpha = 0,
    mouseX = 0,
    mouseY = 0,
    cache = {} -- Cache des tooltips générés
}

-- Types de tooltips
local TOOLTIP_TYPES = {
    CARD = "card",
    ENERGY = "energy",
    BUTTON = "button",
    ACTOR = "actor",
    EFFECT = "effect"
}

-- =========================================================================
-- GÉNÉRATION DU CONTENU DES TOOLTIPS
-- =========================================================================

---Générer tooltip pour une carte
---@param card table Données de la carte
---@return table tooltip Données du tooltip
function tooltipSystem.generateCardTooltip(card)
    if not card then return nil end

    local lines = {}

    -- Nom de la carte
    table.insert(lines, {
        text = card.name or "Carte inconnue",
        style = "title"
    })

    -- Coût énergétique
    local cost = card.PowerBlow or card.cost or card.power or 0
    local costText = cost > 0 and string.format("Coût: %d ⚡", cost) or "Gratuit"
    table.insert(lines, {
        text = costText,
        style = "cost"
    })

    -- Ligne de séparation
    table.insert(lines, { text = "━━━━━━━━━━━━━━━━━━━━", style = "separator" })

    -- Description des effets
    if card.Effect then
        if card.Effect.target then
            table.insert(lines, { text = "🎯 Effets sur la cible:", style = "section" })
            tooltipSystem.addEffectLines(lines, card.Effect.target)
        end

        if card.Effect.caster then
            table.insert(lines, { text = "🛡️ Effets sur soi:", style = "section" })
            tooltipSystem.addEffectLines(lines, card.Effect.caster)
        end
    end

    -- AOE
    if card.multiTarget then
        table.insert(lines, {
            text = "💥 Affecte tous les ennemis",
            style = "special"
        })
    end

    -- Action spéciale
    if card.onPlay then
        table.insert(lines, {
            text = "⭐ Effet spécial au jeu",
            style = "special"
        })
    end

    -- Informations additionnelles
    if card.rarity then
        table.insert(lines, {
            text = "Rareté: " .. card.rarity,
            style = "info"
        })
    end

    return {
        type = TOOLTIP_TYPES.CARD,
        lines = lines,
        width = TOOLTIP_CONFIG.maxWidth
    }
end

---Ajouter lignes d'effets au tooltip
---@param lines table Liste des lignes
---@param effects table Effets de la carte
function tooltipSystem.addEffectLines(lines, effects)
    for effectName, value in pairs(effects) do
        local effectText = tooltipSystem.formatEffectText(effectName, value)
        if effectText then
            table.insert(lines, {
                text = "  • " .. effectText,
                style = "effect"
            })
        end
    end
end

---Formater le texte d'un effet
---@param effectName string Nom de l'effet
---@param value any Valeur de l'effet
---@return string|nil effectText Texte formaté
function tooltipSystem.formatEffectText(effectName, value)
    local formatMap = {
        attack = function(v) return string.format("Inflige %d dégâts", v) end,
        heal = function(v) return string.format("Restaure %d PV", v) end,
        shield = function(v) return string.format("Gagne %d bouclier", v) end,
        Epine = function(v) return string.format("Gagne %d épines", v) end,
        chancePassedTour = function(v) return string.format("%d%% de faire passer le tour", v) end,
        AttackReduction = function(v) return string.format("Réduit attaque de %d%%", v) end,
        force_augmented = function(v) return string.format("Force +%d pour %d tours", v.bonus or 0, v.number_turns or 1) end,
        bleeding = function(v) return string.format("Saignement %d/tour pendant %d tours", v.damage or 0,
                v.number_turns or 1) end
    }

    local formatter = formatMap[effectName]
    if formatter then
        return formatter(value)
    else
        return string.format("%s: %s", effectName, tostring(value))
    end
end

---Générer tooltip pour l'affichage d'énergie
---@param currentEnergy number Énergie actuelle
---@param maxEnergy number Énergie maximale
---@return table tooltip Données du tooltip
function tooltipSystem.generateEnergyTooltip(currentEnergy, maxEnergy)
    maxEnergy = maxEnergy or 8

    local lines = {}

    table.insert(lines, {
        text = "⚡ Énergie",
        style = "title"
    })

    table.insert(lines, {
        text = string.format("%d / %d points", currentEnergy, maxEnergy),
        style = "value"
    })

    table.insert(lines, { text = "━━━━━━━━━━━━━━━━━━━━", style = "separator" })

    -- Conseils selon l'énergie
    if currentEnergy == 0 then
        table.insert(lines, {
            text = "❌ Aucune action possible",
            style = "warning"
        })
        table.insert(lines, {
            text = "Terminez votre tour (E)",
            style = "tip"
        })
    elseif currentEnergy <= 2 then
        table.insert(lines, {
            text = "⚠️ Énergie faible",
            style = "warning"
        })
        table.insert(lines, {
            text = "Jouez vos dernières cartes",
            style = "tip"
        })
    else
        table.insert(lines, {
            text = "✅ Énergie suffisante",
            style = "success"
        })
        table.insert(lines, {
            text = "Choisissez vos cartes",
            style = "tip"
        })
    end

    return {
        type = TOOLTIP_TYPES.ENERGY,
        lines = lines,
        width = 250
    }
end

---Générer tooltip pour un acteur (héros/ennemi)
---@param actor table Données de l'acteur
---@return table tooltip Données du tooltip
function tooltipSystem.generateActorTooltip(actor)
    if not actor or not actor.state then return nil end

    local lines = {}

    -- Nom
    table.insert(lines, {
        text = actor.name or "Acteur",
        style = "title"
    })

    -- Statistiques
    local health = actor.state.health or 0
    local maxHealth = actor.state.maxHealth or health
    local shield = actor.state.shield or 0

    table.insert(lines, {
        text = string.format("❤️ PV: %d/%d", health, maxHealth),
        style = "stat"
    })

    if shield > 0 then
        table.insert(lines, {
            text = string.format("🛡️ Bouclier: %d", shield),
            style = "stat"
        })
    end

    -- Épines
    if actor.state.Epine and actor.state.Epine > 0 then
        table.insert(lines, {
            text = string.format("🌿 Épines: %d", actor.state.Epine),
            style = "stat"
        })
    end

    -- Effets temporels
    if actor.state.temporalEffects then
        table.insert(lines, { text = "━━━━━━━━━━━━━━━━━━━━", style = "separator" })
        table.insert(lines, { text = "🕐 Effets actifs:", style = "section" })

        for effectName, effect in pairs(actor.state.temporalEffects) do
            local turns = effect.number_turns or 1
            table.insert(lines, {
                text = string.format("  • %s (%d tours)", effectName, turns),
                style = "effect"
            })
        end
    end

    return {
        type = TOOLTIP_TYPES.ACTOR,
        lines = lines,
        width = 280
    }
end

-- =========================================================================
-- AFFICHAGE ET RENDU
-- =========================================================================

---Calculer les styles de texte
---@param style string Style du texte
---@return table color Couleur RGBA
---@return number fontSize Taille de police
function tooltipSystem.getTextStyle(style)
    local styles = {
        title = { { 1, 1, 0.3, 1 }, TOOLTIP_CONFIG.fontSize + 2 },
        cost = { { 0.3, 1, 0.3, 1 }, TOOLTIP_CONFIG.fontSize },
        section = { { 0.7, 0.9, 1, 1 }, TOOLTIP_CONFIG.fontSize },
        effect = { { 0.9, 0.9, 0.9, 1 }, TOOLTIP_CONFIG.fontSize - 1 },
        special = { { 1, 0.7, 1, 1 }, TOOLTIP_CONFIG.fontSize },
        warning = { { 1, 0.7, 0.3, 1 }, TOOLTIP_CONFIG.fontSize },
        success = { { 0.3, 1, 0.3, 1 }, TOOLTIP_CONFIG.fontSize },
        tip = { { 0.7, 0.7, 0.7, 1 }, TOOLTIP_CONFIG.fontSize - 1 },
        separator = { { 0.5, 0.5, 0.5, 1 }, TOOLTIP_CONFIG.fontSize - 2 },
        info = { { 0.8, 0.8, 0.8, 1 }, TOOLTIP_CONFIG.fontSize - 1 },
        stat = { { 0.9, 0.9, 0.9, 1 }, TOOLTIP_CONFIG.fontSize },
        value = { { 1, 1, 1, 1 }, TOOLTIP_CONFIG.fontSize + 1 }
    }

    return styles[style] or styles.effect
end

---Calculer la position optimale du tooltip
---@param tooltipWidth number Largeur du tooltip
---@param tooltipHeight number Hauteur du tooltip
---@return number x Position X
---@return number y Position Y
function tooltipSystem.calculatePosition(tooltipWidth, tooltipHeight)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local x = tooltipState.mouseX + TOOLTIP_CONFIG.offsetX
    local y = tooltipState.mouseY + TOOLTIP_CONFIG.offsetY

    -- Éviter débordement droite
    if x + tooltipWidth > screenWidth then
        x = tooltipState.mouseX - tooltipWidth - TOOLTIP_CONFIG.offsetX
    end

    -- Éviter débordement bas
    if y + tooltipHeight > screenHeight then
        y = tooltipState.mouseY - tooltipHeight - TOOLTIP_CONFIG.offsetY
    end

    -- Garder dans les limites
    x = math.max(5, math.min(x, screenWidth - tooltipWidth - 5))
    y = math.max(5, math.min(y, screenHeight - tooltipHeight - 5))

    return x, y
end

---Dessiner le tooltip
---@param tooltip table Données du tooltip
---@param x number Position X
---@param y number Position Y
function tooltipSystem.drawTooltip(tooltip, x, y)
    if not tooltip or not love.graphics then return end

    local alpha = tooltipState.alpha
    if alpha <= 0 then return end

    -- Calculer dimensions
    local lineHeight = TOOLTIP_CONFIG.fontSize + 2
    local height = #tooltip.lines * lineHeight + TOOLTIP_CONFIG.padding * 2
    local width = tooltip.width or TOOLTIP_CONFIG.maxWidth

    -- Fond
    love.graphics.setColor(
        TOOLTIP_CONFIG.backgroundColor[1],
        TOOLTIP_CONFIG.backgroundColor[2],
        TOOLTIP_CONFIG.backgroundColor[3],
        TOOLTIP_CONFIG.backgroundColor[4] * alpha
    )
    love.graphics.rectangle("fill", x, y, width, height, TOOLTIP_CONFIG.cornerRadius)

    -- Bordure
    love.graphics.setColor(
        TOOLTIP_CONFIG.borderColor[1],
        TOOLTIP_CONFIG.borderColor[2],
        TOOLTIP_CONFIG.borderColor[3],
        TOOLTIP_CONFIG.borderColor[4] * alpha
    )
    love.graphics.setLineWidth(TOOLTIP_CONFIG.borderWidth)
    love.graphics.rectangle("line", x, y, width, height, TOOLTIP_CONFIG.cornerRadius)

    -- Texte
    local currentY = y + TOOLTIP_CONFIG.padding

    for _, line in ipairs(tooltip.lines) do
        local color, fontSize = tooltipSystem.getTextStyle(line.style or "effect")

        -- Appliquer alpha
        love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)

        -- Dessiner le texte
        love.graphics.print(line.text, x + TOOLTIP_CONFIG.padding, currentY)
        currentY = currentY + lineHeight
    end

    -- Restaurer couleur
    love.graphics.setColor(1, 1, 1, 1)
end

-- =========================================================================
-- GESTION DES ÉVÉNEMENTS
-- =========================================================================

---Commencer le survol d'un élément
---@param elementType string Type d'élément
---@param elementData any Données de l'élément
---@param mouseX number Position X de la souris
---@param mouseY number Position Y de la souris
function tooltipSystem.startHover(elementType, elementData, mouseX, mouseY)
    if not elementData then return end

    tooltipState.mouseX = mouseX
    tooltipState.mouseY = mouseY
    tooltipState.hoverStartTime = love.timer and love.timer.getTime() or 0

    -- Générer ou récupérer du cache
    local cacheKey = elementType .. "_" .. tostring(elementData)
    local tooltip = tooltipState.cache[cacheKey]

    if not tooltip then
        if elementType == TOOLTIP_TYPES.CARD then
            tooltip = tooltipSystem.generateCardTooltip(elementData)
        elseif elementType == TOOLTIP_TYPES.ENERGY then
            tooltip = tooltipSystem.generateEnergyTooltip(elementData.current, elementData.max)
        elseif elementType == TOOLTIP_TYPES.ACTOR then
            tooltip = tooltipSystem.generateActorTooltip(elementData)
        end

        if tooltip then
            tooltipState.cache[cacheKey] = tooltip
        end
    end

    tooltipState.currentTooltip = tooltip
end

---Arrêter le survol
function tooltipSystem.endHover()
    tooltipState.currentTooltip = nil
    tooltipState.targetAlpha = 0
    tooltipState.hoverStartTime = 0
end

---Mise à jour du tooltip
---@param dt number Delta time
function tooltipSystem.update(dt)
    -- Mise à jour de l'alpha
    local targetAlpha = 0

    if tooltipState.currentTooltip then
        local currentTime = love.timer and love.timer.getTime() or 0
        local hoverDuration = currentTime - tooltipState.hoverStartTime

        if hoverDuration >= TOOLTIP_CONFIG.showDelay then
            targetAlpha = 1
        end
    end

    tooltipState.targetAlpha = targetAlpha

    -- Animation smooth
    local alphaDiff = tooltipState.targetAlpha - tooltipState.alpha
    tooltipState.alpha = tooltipState.alpha + alphaDiff * TOOLTIP_CONFIG.fadeSpeed * dt

    -- Seuil minimal
    if math.abs(alphaDiff) < 0.01 then
        tooltipState.alpha = tooltipState.targetAlpha
    end

    tooltipState.visible = tooltipState.alpha > 0.01
end

---Rendu du tooltip
function tooltipSystem.draw()
    if not tooltipState.visible or not tooltipState.currentTooltip then
        return
    end

    local tooltip = tooltipState.currentTooltip
    local lineHeight = TOOLTIP_CONFIG.fontSize + 2
    local height = #tooltip.lines * lineHeight + TOOLTIP_CONFIG.padding * 2
    local width = tooltip.width or TOOLTIP_CONFIG.maxWidth

    local x, y = tooltipSystem.calculatePosition(width, height)
    tooltipSystem.drawTooltip(tooltip, x, y)
end

-- =========================================================================
-- INTÉGRATION
-- =========================================================================

---Vider le cache des tooltips
function tooltipSystem.clearCache()
    tooltipState.cache = {}

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Tooltip cache cleared")
    end
end

---Hook pour éléments avec tooltips
---@param element table Élément UI
---@param tooltipType string Type de tooltip
---@param tooltipData any Données pour le tooltip
function tooltipSystem.addTooltipToElement(element, tooltipType, tooltipData)
    if not element then return end

    -- Ajouter callbacks de survol
    element.onMouseEnter = function(mouseX, mouseY)
        tooltipSystem.startHover(tooltipType, tooltipData, mouseX, mouseY)
    end

    element.onMouseLeave = function()
        tooltipSystem.endHover()
    end

    element.onMouseMove = function(mouseX, mouseY)
        tooltipState.mouseX = mouseX
        tooltipState.mouseY = mouseY
    end
end

-- =========================================================================
-- INITIALISATION
-- =========================================================================

-- Exposer globalement
_G.tooltipSystem = tooltipSystem

if globalFunction and globalFunction.log then
    globalFunction.log.info("Tooltip system initialized")
end

return tooltipSystem
