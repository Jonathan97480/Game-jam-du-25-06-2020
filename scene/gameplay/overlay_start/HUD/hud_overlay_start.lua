-- scene/overlay_start/HUD/hud_overlay_start.lua
-- HUD component for overlay_start using modular HUD system
local hud_overlay_start = {}

local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if ok then return mod end
    return nil
end

-- Load modules safely
local hud = _safeRequire("my-librairie/hud/hud") or _G.hud
local responsive = _G.screen or _safeRequire("my-librairie/utils/responsive")
local TransitionCombat = _safeRequire("my-librairie/transitions/templateCombatTransition")
local Card = _G.Card or _safeRequire("my-librairie/card-librairie/card")

-- Debug: Check if HUD is loaded
print("DEBUG overlay_start HUD: hud =", hud and "LOADED" or "NIL")
print("DEBUG overlay_start HUD: responsive =", responsive and "LOADED" or "NIL")

-- HUD configuration
local PADDING = 24
local BTN_W, BTN_H = 280, 56
local deckPlayerSnapshot = {}

-- Screen helpers
local function W()
    return (responsive and responsive.gameReso and responsive.gameReso.width) or 1024
end
local function H()
    return (responsive and responsive.gameReso and responsive.gameReso.height) or 768
end

local function buildDeckPlayerSnapshot()
    deckPlayerSnapshot = {}
    local deckPlayer = Card and Card.getDeckByName and Card.getDeckByName("HeroDeck")
    local gf = _G.globalFunction

    if not deckPlayer or (deckPlayer and type(deckPlayer.cards) == 'table' and #deckPlayer.cards == 0) then
        local msg = "Deck 'HeroDeck' non trouvé ou vide dans buildDeckPlayerSnapshot, tentative heuristique"
        if gf and gf.log and gf.log.warn then gf.log.warn(msg) else print(msg) end

        -- heuristic: search available decks for a name containing 'hero'
        if Card and Card.deckList then
            for _, d in ipairs(Card.deckList() or {}) do
                if d and d.name and tostring(d.name):lower():find('hero') then
                    deckPlayer = d
                    if gf and gf.log and gf.log.info then
                        gf.log.info("Deck heuristique trouvé:", d.name)
                    else
                        print("Deck heuristique trouvé:", d.name)
                    end
                    break
                end
            end
        end

        if not deckPlayer then
            local msg2 = "Aucun deck joueur trouvé après heuristique"
            if gf and gf.log and gf.log.warn then gf.log.warn(msg2) else print(msg2) end
            return {}
        end
    end

    if not Card or not deckPlayer.cards then return end
    local n = math.min(#deckPlayer.cards, 10)
    for i = 1, n do deckPlayerSnapshot[i] = deckPlayer.cards[i] end
end

-- Initialize HUD elements
function hud_overlay_start.load()
    print("DEBUG: hud_overlay_start.load() called")
    print("DEBUG: hud available =", hud and "YES" or "NO")

    if not hud then
        print("ERROR: HUD system not available!")
        return
    end

    buildDeckPlayerSnapshot()
    print("DEBUG: deckPlayerSnapshot has", #deckPlayerSnapshot, "cards")

    -- Clear existing elements for this overlay
    if hud.clear then
        hud.clear()
        print("DEBUG: HUD cleared")
    end

    -- Background semi-transparent overlay
    hud.setPanel("overlay_bg", 0, 0, W(), H(), { layer = "background" }, { color = { 0, 0, 0, 0.6 } })
    print("DEBUG: Background panel created")

    -- Title
    hud.addLabel("title", {
        x = W() / 2 - 200,
        y = 32,
        text = "Deck de départ (10 cartes max)",
        layer = "decor"
    })
    print("DEBUG: Title label created")

    -- Cards grid panel (invisible container)
    local gridY = 100
    local gridH = H() - 240
    hud.setPanel("cards_grid", PADDING, gridY, W() - PADDING * 2, gridH,
        { layer = "background" }, { type = "container" })

    -- Add individual card panels
    local cols, rows = 5, 2
    local cellW = (W() - PADDING * 2) / cols
    local cellH = gridH / rows

    for i, cardData in ipairs(deckPlayerSnapshot) do
        if i > 10 then break end -- Max 10 cards

        local r = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local x = PADDING + col * cellW
        local y = gridY + r * cellH

        local cardId = "card_" .. i

        -- Card background panel
        hud.setPanel(cardId .. "_bg", x + 8, y + 8, cellW - 16, cellH - 16,
            { layer = "props" }, { color = { 1, 1, 1, 0.08 } })

        -- Card name and cost
        if cardData then
            local cardText = string.format("%s  (Coût: %d)",
                cardData.name or "Carte",
                tonumber(cardData.PowerBlow) or 0)
            hud.addLabel(cardId .. "_text", {
                x = x + 12,
                y = y + cellH - 44,
                text = cardText,
                layer = "props"
            })
        end
    end

    -- Continue button with enhanced styling
    local btnX = (W() - BTN_W) * 0.5
    local btnY = H() - BTN_H - 40

    hud.addButton("continue_btn", {
        x = btnX,
        y = btnY,
        w = BTN_W,
        h = BTN_H,
        text = "Continuer",
        layer = "button",
        bgColor = { 0.9, 0.9, 0.9, 1 },     -- Fond blanc-gris
        hoverColor = { 1, 1, 1, 1 },        -- Blanc pur au survol
        clickColor = { 0.8, 0.8, 0.8, 1 },  -- Plus sombre au clic
        textColor = { 0, 0, 0, 1 },         -- Texte noir pour fond clair
        borderColor = { 0.4, 0.4, 0.4, 1 }, -- Bordure grise
        cornerRadius = 10,                  -- Coins arrondis
        onClick = function()
            print("DEBUG: Continue button clicked!")
            if TransitionCombat and TransitionCombat.continueFromStartOverlay then
                TransitionCombat:continueFromStartOverlay()
            else
                print("ERROR: Transition.continueFromStartOverlay not available")
            end
        end
    })
    print("DEBUG: Continue button created at", btnX, btnY)
end

-- Update HUD elements
function hud_overlay_start.update(dt)
    if hud and hud.update then
        hud.update(dt)
    end
end

-- Draw HUD elements
function hud_overlay_start.draw()
    -- ✅ HUD rendu centralisé dans main.lua - plus besoin d'appeler hud.draw() ici

    -- Custom drawing for card images (if needed)
    -- This part might need custom rendering since card.canvas needs special handling
    local cols, rows = 5, 2
    local cellW = (W() - PADDING * 2) / cols
    local cellH = (H() - 240) / rows

    for i, cardData in ipairs(deckPlayerSnapshot) do
        if i > 10 then break end

        local r = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local x = PADDING + col * cellW
        local y = 100 + r * cellH

        -- Draw card canvas if available (custom rendering)
        if cardData and cardData.canvas then
            local tf = cardData.TextFormatting or {}
            local tfcard = tf.card or {}
            local cw, ch = tfcard.width or 337, tfcard.height or 462
            local maxW, maxH = cellW - 32, cellH - 70
            local s = math.min(maxW / cw, maxH / ch)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(cardData.canvas,
                x + cellW * 0.5, y + 16 + maxH * 0.5,
                0, s, s, cw * 0.5, ch * 0.5)
        end
    end
end

-- Cleanup HUD elements
function hud_overlay_start.unload()
    print("DEBUG: hud_overlay_start.unload() called")

    if hud then
        -- Remove overlay-specific elements instead of clearing everything
        local elementsToRemove = {
            "overlay_bg", "title", "cards_grid", "continue_btn"
        }

        -- Remove card elements
        for i = 1, 10 do
            elementsToRemove[#elementsToRemove + 1] = "card_" .. i .. "_bg"
            elementsToRemove[#elementsToRemove + 1] = "card_" .. i .. "_text"
        end

        for _, id in ipairs(elementsToRemove) do
            if hud.remove then
                hud.remove(id)
                print("DEBUG: Removed HUD element:", id)
            end
        end
    end
end

return hud_overlay_start
