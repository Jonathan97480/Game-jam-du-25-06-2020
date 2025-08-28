-- scene/overlay_initiative.lua
-- Petit panneau plein écran qui annonce qui commence.
local overlay    = { name = "overlay_initiative" }

local Transition = require("my-librairie/transition/manager")

local W, H
local timer      = 0
local hold       = 10 -- secondes avant auto-continue (peut être réduit)
local who        = "?"

-- Couleurs rapides
local function rgba(r, g, b, a) love.graphics.setColor(r / 255, g / 255, b / 255, a or 1) end

function overlay.load(self)
    W = (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    H = (screen and screen.gameReso and screen.gameReso.height) or love.graphics.getHeight()
end

function overlay.enter(self)
    timer = 0
    -- Qui commence ? le manager doit l’avoir décidé avant d’entrer dans cet état
    if Transition.getInitiative then
        who = Transition.getInitiative() == "Enemy" and "L'ennemi commence !" or "Vous commencez !"
    elseif _G.Tour == "Enemy" then
        who = "L'ennemi commence !"
    else
        who = "Vous commencez !"
    end
end

function overlay.update(self, dt)
    timer = timer + dt
    if timer >= hold then
        if Transition.announceContinue then Transition.announceContinue() end
    end
end

function overlay.draw(self)
    -- backdrop plein écran
    rgba(0, 0, 0, 0.6); love.graphics.rectangle("fill", 0, 0, W, H)

    -- card centrale
    local boxW, boxH = math.min(800, W * 0.8), math.min(320, H * 0.5)
    local x, y = (W - boxW) / 2, (H - boxH) / 2
    rgba(20, 22, 26, 0.95); love.graphics.rectangle("fill", x, y, boxW, boxH, 16, 16)
    rgba(255, 255, 255, 1)
    love.graphics.setNewFont(36)
    love.graphics.printf("Initiative", x, y + 24, boxW, "center")
    love.graphics.setNewFont(28)
    love.graphics.printf(who, x + 20, y + 110, boxW - 40, "center")

    love.graphics.setNewFont(18)
    local remain = math.max(0, math.ceil(hold - timer))
    love.graphics.printf("Cliquez ou appuyez sur ESPACE pour continuer (" .. remain .. "s)", x + 20, y + boxH - 48,
        boxW - 40, "center")
end

-- Entrées utilisateur pour “skip”
function overlay.keypressed(self, key)
    if key == "space" or key == "return" or key == "kpenter" then
        if Transition.announceContinue then Transition.announceContinue() end
    end
end

function overlay.mousepressed(self, mx, my, button)
    if button == 1 then
        if Transition.announceContinue then Transition.announceContinue() end
    end
end

-- Pour éviter que le HUD “mange” la souris pendant l’overlay :
function overlay.isMouseOver()
    return true
end

overlay.hitTest = overlay.isMouseOver
overlay.bounds = { { x = 0, y = 0, w = math.huge, h = math.huge } }

return overlay
