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

local Card = require("my-librairie/card-librairie/card")
local Common = require("my-librairie/card-librairie/common")

-- Ajoute une carte à la main et teste le positionnement
local card = { name = "CarteMain", width = 100, height = 150, vector2 = { x = 0, y = 0 }, scale = { x = 1, y = 1 } }
Common.hand:addCard(card)
Card.positionHand()
assert(card.vector2.x and type(card.vector2.x) == "number", "La carte n'a pas de position x après positionHand")
assert(card.vector2.y and type(card.vector2.y) == "number", "La carte n'a pas de position y après positionHand")

-- print("[TEST] player_ops.lua : OK")
local gf = rawget(_G, 'globalFunction')
local _msg = "[TEST] player_ops.lua : OK"
if gf and gf.log and gf.log.info then gf.log.info(_msg) else print(_msg) end
