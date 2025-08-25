-- scene/overlay_reward.lua
local Transition = require("my-librairie/transition/manager")
local responsive = require("my-librairie/responsive")

local overlay = { name = "overlay_reward" }

local cards = nil
local hovered = 0

function overlay.load(self)
    cards = Transition.getRewardOptions()
end

function overlay.update(self, dt)
    hovered = 0
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local total = 3
    local spacing = 280
    local startX = (w - spacing * (total - 1)) * 0.5
    local y = h * 0.5 - 240

    for i = 1, total do
        local x = startX + (i - 1) * spacing
        if mx >= x and mx <= x + 220 and my >= y and my <= y + 360 then
            hovered = i
        end
    end
end

function overlay.draw(self)
    local w = responsive.gameReso.width
    local h = responsive.gameReso.height
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Choisis une carte à ajouter à ton deck", 0, 40, w, "center")

    local total = 3
    local spacing = 280
    local startX = (w - spacing * (total - 1)) * 0.5
    local y = h * 0.5 - 240

    for i = 1, total do
        local x = startX + (i - 1) * spacing
        local c = cards and cards[i]
        if c and c.canvas then
            local sc = (hovered == i) and 0.7 or 0.6
            love.graphics.draw(c.canvas, x, y, 0, sc, sc)
            if hovered == i then
                love.graphics.setColor(1, 1, 0, 0.25)
                love.graphics.rectangle("fill", x, y, 220, 360)
                love.graphics.setColor(1, 1, 1, 1)
            end
        else
            love.graphics.rectangle("line", x, y, 220, 360)
        end
    end

    love.graphics.printf("Clique sur une carte", 0, h - 80, w, "center")
end

function overlay.mousepressed(self, mx, my, btn)
    if btn ~= 1 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local total = 3
    local spacing = 280
    local startX = (w - spacing * (total - 1)) * 0.5
    local y = h * 0.5 - 240

    for i = 1, total do
        local x = startX + (i - 1) * spacing
        if mx >= x and mx <= x + 220 and my >= y and my <= y + 360 then
            Transition.rewardSelect(i)
            break
        end
    end
end

return overlay
