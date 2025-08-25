-- scene/overlay_start.lua
local overlay            = { name = "overlay_start" }

local screen             = rawget(_G, "screen") or require("my-librairie/responsive")
local Transition         = require("my-librairie/transition/manager")
local Card               = rawget(_G, "Card") or rawget(_G, "card")

local wasDown            = false
local deckPlayerSnapshot = {}

local function W() return screen.gameReso.width end
local function H() return screen.gameReso.height end
local PADDING = 24
local BTN_W, BTN_H = 280, 56
local btn = { x = 0, y = 0, w = BTN_W, h = BTN_H }

local function isOver(x, y, w, h, mx, my) return mx >= x and mx <= x + w and my >= y and my <= y + h end
local function mouse()
    local mx = (screen.mouse and screen.mouse.X) or (love.mouse and ({ love.mouse.getPosition() })[1]) or 0
    local my = (screen.mouse and screen.mouse.Y) or (love.mouse and ({ love.mouse.getPosition() })[2]) or 0
    local down = love.mouse and love.mouse.isDown(1)
    return mx, my, down
end
local function buildDeckPlayerSnapshot()
    deckPlayerSnapshot = {}
    local deckPlayer = Card.getDeckByName("HeroDeck")
    if not deckPlayer then
        print("Deck non trouver dans la fonction buildDeckPlayerSnapshot")
        return
    end
    if not Card or not deckPlayer.cards then return end
    local n = math.min(#deckPlayer.cards, 10)
    for i = 1, n do deckPlayerSnapshot[i] = deckPlayer.cards[i] end
end

function overlay.load()
    buildDeckPlayerSnapshot()
    btn.x = (W() - BTN_W) * 0.5
    btn.y = H() - BTN_H - 40
end

function overlay.update(dt)
    local mx, my, down = mouse()
    -- on n'utilise PAS clavier ici pour éviter l'auto-close
    if not down and wasDown and isOver(btn.x, btn.y, btn.w, btn.h, mx, my) then
        Transition.continueFromStartOverlay()
    end
    wasDown = down
end

function overlay.draw()
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, W(), H())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setNewFont(32)
    love.graphics.printf("Deck de départ (10 cartes max)", 0, 32, W(), "center")

    local cols, rows = 5, 2
    local cellW = (W() - PADDING * 2) / cols
    local cellH = (H() - 240) / rows
    love.graphics.setNewFont(18)

    for i, c in ipairs(deckPlayerSnapshot) do
        local r = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local x = PADDING + col * cellW
        local y = 100 + r * cellH

        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.rectangle("fill", x + 8, y + 8, cellW - 16, cellH - 16, 12, 12)
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("line", x + 8, y + 8, cellW - 16, cellH - 16, 12, 12)

        if c and c.canvas then
            local cw, ch = c.TextFormatting.card.width or 337, c.TextFormatting.card.height or 462
            local maxW, maxH = cellW - 32, cellH - 70
            local s = math.min(maxW / cw, maxH / ch)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(c.canvas, x + cellW * 0.5, y + 16 + maxH * 0.5, 0, s, s, cw * 0.5, ch * 0.5)
        end
        if c then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(string.format("%s  (Coût: %d)", c.name or "Carte", tonumber(c.PowerBlow) or 0),
                x + 12, y + cellH - 44, cellW - 24, "center")
        end
    end

    local mx, my = mouse()
    local over = isOver(btn.x, btn.y, btn.w, btn.h, mx, my)
    love.graphics.setColor(over and 1 or 0.9, over and 1 or 0.9, over and 1 or 0.9, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setNewFont(24)
    love.graphics.printf("Continuer", btn.x, btn.y + (BTN_H - 24) / 2, BTN_W, "center")

    love.graphics.pop()
end

return overlay
