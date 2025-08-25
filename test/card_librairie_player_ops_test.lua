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
-- test/card_librairie_player_ops_test.lua
-- Test unitaire pour player_ops.lua

local Player = require("my-librairie/card-librairie/player_ops")
local Common = require("my-librairie/card-librairie/common")

-- Ajoute une carte à la main et teste le positionnement
local card = { name = "CarteMain", width = 100, height = 150, vector2 = { x = 0, y = 0 }, scale = { x = 1, y = 1 } }
Common.hand:addCard(card)
Player.positioneHand()
assert(card.vector2.x, "La carte n'a pas de position x après positioneHand")
assert(card.vector2.y, "La carte n'a pas de position y après positioneHand")

print("[TEST] player_ops.lua : OK")
