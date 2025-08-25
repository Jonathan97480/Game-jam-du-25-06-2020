-- Mock local pour ressources/card (module inexistant)
package.loaded["ressources/card"] = {}

-- S'assurer que la table globale love est initialisée avant tout accès à ses sous-tables
if not rawget(_G, "love") then love = {} end
love.window = love.window or {}
love.window.getMode = function() return 800, 600, {} end
love.window.setMode = function() end
love.graphics = love.graphics or {}
love.graphics.newImage = function(path) return { mocked_image = path } end
love.mouse = love.mouse or {}
love.mouse.getPosition = function() return 0, 0 end
love.mouse.isDown = function() return false end

-- Mock local pour my-librairie/myFunction afin de casser la chaîne de dépendances
package.loaded["my-librairie/myFunction"] = {
    dummy = function() end
}

-- Mock global pour hud (utilisé dans repositioningCardsInHand)
if not rawget(_G, "hud") then
    hud = { setText = function() end }
end
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
-- test/card_librairie_repositioningCardsInHand_test.lua
-- Test unitaire pour repositioningCardsInHand.lua

local repositioning = require("my-librairie/card-librairie/repositioningCardsInHand")
local Common = require("my-librairie/card-librairie/common")

-- Ajoute une carte à la main
local card = { name = "CarteMain", width = 100, height = 150, oldVector2 = { x = 0, y = 0 } }
Common.hand:addCard(card)
repositioning.repositioningCardsInHand()
assert(card.oldVector2.x, "oldVector2.x non défini après repositioningCardsInHand")
assert(card.oldVector2.y, "oldVector2.y non défini après repositioningCardsInHand")

print("[TEST] repositioningCardsInHand.lua : OK")
