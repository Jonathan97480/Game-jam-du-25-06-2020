-- scene/overlay_gameover.lua
local Transition = require("my-librairie/transition/manager")

local overlay = { name = "overlay_gameover" }

local buttons = {
    { label = "Recommencer", action = function() Transition.cmdRestart() end },
    { label = "Menu",        action = function() Transition.cmdBackToMenu() end },
}

local hot = 0

function overlay.load(self)
    hot = 0
end

function overlay.update(self, dt)
    local mx, my = 0, 0
    local okc, cursor = pcall(require, "my-librairie/cursor")
    if okc and cursor and cursor.get then
        mx, my = cursor.get()
    else
        local ok2, x, y = pcall(function() return love.mouse.getPosition() end)
        if ok2 then
            mx = x or 0; my = y or 0
        end
    end
    hot = 0
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local bw, bh = 240, 52
    local baseY = h * 0.6

    for i = 1, #buttons do
        local x = w * 0.5 - bw * 0.5
        local y = baseY + (i - 1) * (bh + 14)
        if mx >= x and mx <= x + bw and my >= y and my <= y + bh then
            hot = i
        end
    end
end

function overlay.draw(self)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.printf("GAME OVER", 0, h * 0.3, w, "center")

    local bw, bh = 240, 52
    local baseY = h * 0.6
    for i, b in ipairs(buttons) do
        local x = w * 0.5 - bw * 0.5
        local y = baseY + (i - 1) * (bh + 14)
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", x, y, bw, bh, 10, 10)
        if hot == i then
            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.rectangle("fill", x, y, bw, bh, 10, 10)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(b.label, x, y + 16, bw, "center")
    end
end

function overlay.mousepressed(self, mx, my, btn)
    if btn ~= 1 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local bw, bh = 240, 52
    local baseY = h * 0.6

    for i, b in ipairs(buttons) do
        local x = w * 0.5 - bw * 0.5
        local y = baseY + (i - 1) * (bh + 14)
        if mx >= x and mx <= x + bw and my >= y and my <= y + bh then
            if b.action then b.action() end
            break
        end
    end
end

function overlay.keypressed(self, key)
    if key == "escape" then
        Transition.cmdBackToMenu()
    end
end

return overlay
