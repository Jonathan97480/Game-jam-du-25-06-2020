-- Mock minimal pour love (LÖVE2D) si absent
if not rawget(_G, "love") then
    love = {
        timer = { getTime = function() return os.time() end },
        math = { setRandomSeed = function() end },
        graphics = { setColor = function() end, circle = function() end, setNewFont = function() return true end, print = function() end, pop = function() end },
        window = { getMode = function() return 800, 600, {} end, setMode = function() end },
        mouse = { getPosition = function() return 0, 0 end, isDown = function() return false end }
    }
end
-- test/card_librairie_card_test.lua
-- Test unitaire pour card.lua (vérifie l'API et l'intégration)

local Card = require("my-librairie/card-librairie/card")

local function assertType(val, t, msg)
    if type(val) ~= t then error((msg or "") .. "\nType attendu: " .. t .. ", obtenu: " .. type(val)) end
end

assertType(Card.deck, "table", "Card.deck doit être une table")
assertType(Card.hand, "table", "Card.hand doit être une table")
assertType(Card.graveyard, "table", "Card.graveyard doit être une table")
assertType(Card.loadCards, "function", "Card.loadCards doit être une fonction")
assertType(Card.shuffle, "function", "Card.shuffle doit être une fonction")

print("[TEST] card.lua : OK")
