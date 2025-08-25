-- Mock love.graphics.newCanvas pour Lua pur (doit être défini avant require)
if not rawget(_G, "love") then
    love = {
        timer = { getTime = function() return os.time() end },
        math = { setRandomSeed = function() end },
        graphics = {
            setColor = function() end,
            circle = function() end,
            setNewFont = function() return true end,
            print = function() end,
            pop = function() end,
            newCanvas = function() return {} end,
            push = function() end,
            origin = function() end,
            setLineWidth = function() end,
            rectangle = function() end,
            draw = function() end,
            setBlendMode = function() end,
            setScissor = function() end,
            setFont = function() end,
            setCanvas = function() end,
            clear = function() end,
            printf = function() end
        },
        window = { getMode = function() return 800, 600, {} end, setMode = function() end },
        mouse = { getPosition = function() return 0, 0 end, isDown = function() return false end }
    }
else
    if love.graphics then
        if not love.graphics.newCanvas then love.graphics.newCanvas = function() return {} end end
        if not love.graphics.push then love.graphics.push = function() end end
        if not love.graphics.origin then love.graphics.origin = function() end end
        if not love.graphics.setLineWidth then love.graphics.setLineWidth = function() end end
        if not love.graphics.rectangle then love.graphics.rectangle = function() end end
        if not love.graphics.draw then love.graphics.draw = function() end end
        if not love.graphics.setBlendMode then love.graphics.setBlendMode = function() end end
        if not love.graphics.setScissor then love.graphics.setScissor = function() end end
        if not love.graphics.setFont then love.graphics.setFont = function() end end
    end
end
-- Mock love.graphics.newCanvas pour Lua pur
if love and love.graphics and not love.graphics.newCanvas then
    love.graphics.newCanvas = function() return {} end
end
-- Mock table.clone pour Lua 5.1
if not table.clone then
    function table.clone(t)
        local c = {}
        for k, v in pairs(t) do
            if type(v) == "table" then
                c[k] = table.clone(v)
            else
                c[k] = v
            end
        end
        return c
    end
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
-- test/card_librairie_generator_test.lua
-- Test unitaire pour generator.lua

local Generator = require("my-librairie/card-librairie/generator")
local Common = require("my-librairie/card-librairie/common")

local cards = {
    { name = "Carte1", width = 100, height = 150 },
    { name = "Carte2", width = 100, height = 150 }
}

Generator.loadCards(cards, "Hero", "testDeckGen")
local deck = Common.createDeck("testDeckGen")
assert(deck, "Deck non créé par Generator.loadCards")
assert(deck:size() >= 2, "Les cartes n'ont pas été ajoutées au deck")

print("[TEST] generator.lua : OK")
