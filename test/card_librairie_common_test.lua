-- Mock minimal pour screen et love si absents
if not rawget(_G, "screen") then
    screen = { gameReso = { width = 800, height = 600 }, mouse = { X = 0, Y = 0 } }
end
if not rawget(_G, "love") then
    love = { timer = { getTime = function() return os.time() end }, math = { setRandomSeed = function() end } }
end

local Common = require("my-librairie/card-librairie/common")

local function assertEquals(a, b, msg)
    if a ~= b then
        error((msg or "") .. "\nAttendu: " .. tostring(b) .. ", obtenu: " .. tostring(a))
    end
end

-- Test création de deck
local deck = Common.createDeck("testDeck")
assert(deck, "La création du deck a échoué")
assertEquals(deck.name, "testDeck", "Le nom du deck n'est pas correct")

-- Test ajout de carte
local card = { name = "CarteTest" }
deck:addCard(card)
assertEquals(deck:size(), 1, "La carte n'a pas été ajoutée au deck")
assertEquals(deck.cards[1].name, "CarteTest", "Le nom de la carte ajoutée n'est pas correct")

-- Test mélange (shuffle)
Common.shuffle(deck.cards)
-- Impossible de tester l'ordre, mais on vérifie que la taille reste la même
assertEquals(deck:size(), 1, "Le deck a perdu des cartes après shuffle")

print("[TEST] common.lua : OK")
