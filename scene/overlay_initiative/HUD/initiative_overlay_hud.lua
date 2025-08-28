-- scene/overlay_initiative/HUD/initiative_overlay_hud.lua
-- RENDU GRAPHIQUE UNIQUEMENT pour l'overlay d'initiative
local InitiativeHUD = {}

local hud = _G.hud
local globalFunction = _G.globalFunction

-- IDs des éléments HUD
local BACKGROUND_ID = "initiative_bg"
local PANEL_ID = "initiative_panel"
local TITLE_ID = "initiative_title"
local MESSAGE_ID = "initiative_message"
local STATUS_ID = "initiative_status"

function InitiativeHUD.create()
    local self = {}
    self.isVisible = false
    return setmetatable(self, { __index = InitiativeHUD })
end

-- Affiche l'overlay avec le message donné
function InitiativeHUD:show(W, H, whoMessage, statusText)
    self.W = W
    self.H = H
    self.isVisible = true
    self.whoMessage = whoMessage
    self.statusText = statusText

    -- Calcul des dimensions et positions
    local boxW = math.min(800, W * 0.8)
    local boxH = math.min(320, H * 0.5)
    self.panelX = (W - boxW) / 2
    self.panelY = (H - boxH) / 2
    self.boxW = boxW
    self.boxH = boxH

    if hud then
        globalFunction.log.info("[InitiativeHUD] Utilisation du système HUD global")

        -- Background semi-transparent
        hud.addIcon(BACKGROUND_ID, {
            x = 0,
            y = 0,
            layer = "background",
            w = W,
            h = H,
            color = { 0, 0, 0, 0.6 }
        })

        -- Panel principal
        hud.setPanel(PANEL_ID, self.panelX, self.panelY, boxW, boxH, {
            color = { 20 / 255, 22 / 255, 26 / 255, 0.95 }
        })

        -- Titre "Initiative"
        hud.addLabel(TITLE_ID, {
            x = self.panelX + (boxW / 2) - 60,
            y = self.panelY + 24,
            layer = "props",
            text = "Initiative",
            font = love.graphics.newFont(36),
            color = { 1, 1, 1, 1 }
        })

        -- Message principal (qui commence)
        hud.addLabel(MESSAGE_ID, {
            x = self.panelX + (boxW / 2) - 80,
            y = self.panelY + 110,
            layer = "props",
            text = whoMessage,
            font = love.graphics.newFont(28),
            color = { 1, 1, 1, 1 }
        })

        -- Texte de statut (instructions/compte à rebours)
        hud.addLabel(STATUS_ID, {
            x = self.panelX + (boxW / 2) - 120,
            y = self.panelY + boxH - 48,
            layer = "props",
            text = statusText,
            font = love.graphics.newFont(18),
            color = { 1, 1, 1, 1 }
        })

        globalFunction.log.info("[InitiativeHUD] Overlay affichée via HUD: " .. whoMessage)
    else
        globalFunction.log.warn("[InitiativeHUD] HUD system not available, using fallback")
    end

    return true
end

-- Met à jour le texte de statut
function InitiativeHUD:updateStatus(statusText)
    if not self.isVisible or not hud then return end

    hud.setText(STATUS_ID, statusText)
end

-- Dessine l'overlay (délègue au système HUD global ou fallback)
function InitiativeHUD:draw()
    if not self.isVisible then return end

    -- ✅ HUD rendu centralisé dans main.lua - plus besoin d'appeler hud.draw() ici
    -- Les éléments HUD sont automatiquement affichés par main.lua:love.draw()

    -- Garder seulement le fallback pour les cas où le système HUD global n'est pas disponible
    if not hud then
        -- Fallback: dessiner directement avec LÖVE2D
        self:drawFallback(self.whoMessage or "?", self.statusText or "...")
    end
end

-- Masque l'overlay
function InitiativeHUD:hide()
    if not hud then return end

    hud.remove(BACKGROUND_ID)
    hud.remove(PANEL_ID)
    hud.remove(TITLE_ID)
    hud.remove(MESSAGE_ID)
    hud.remove(STATUS_ID)

    self.isVisible = false
    globalFunction.log.info("[InitiativeHUD] Overlay masquée")
end

-- Vérifie si l'overlay est visible
function InitiativeHUD:isVisible()
    return self.isVisible
end

-- Rendu de fallback (si HUD non disponible)
function InitiativeHUD:drawFallback(whoMessage, statusText)
    if not self.W or not self.H then return end

    -- Background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, self.W, self.H)

    -- Panel central
    local boxW = math.min(800, self.W * 0.8)
    local boxH = math.min(320, self.H * 0.5)
    local x = (self.W - boxW) / 2
    local y = (self.H - boxH) / 2

    love.graphics.setColor(20 / 255, 22 / 255, 26 / 255, 0.95)
    love.graphics.rectangle("fill", x, y, boxW, boxH)

    -- Border du panel
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", x, y, boxW, boxH)

    -- Titre "Initiative"
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Initiative", x + boxW / 2 - 50, y + 24)

    -- Message principal (qui joue)
    love.graphics.setColor(0.9, 0.9, 0.2, 1)
    if whoMessage then
        love.graphics.print(whoMessage, x + boxW / 2 - 80, y + 110)
    end

    -- Statut
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    if statusText then
        love.graphics.print(statusText, x + boxW / 2 - 120, y + boxH - 48)
    end
end

return InitiativeHUD
