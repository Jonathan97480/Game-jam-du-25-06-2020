local gameplay = {};
local lockClick = false;
-- REQUIRE

local hero = require("ActorScripts/hero");
local Enemies = require("ActorScripts/Enemies");
local cards = require("ressources/card");
-- VARIABLE

-- LOAD
function gameplay.load()

    hudGameplay.init();
    for key, value in pairs(cards) do
        cardeGenerator.create(key, value.ImgIlustration, value.Description, value.PowerBlow, value.Effect,2);
    end
    cardeGenerator.tirage(5);
end

-- UPDATE
function gameplay.update()

    cardeGenerator.hover();

    if love.mouse.isDown(1) and lockClick == false then
        lockClick = true;
        hudGameplay.hover('click')
    elseif love.mouse.isDown(1) == false and lockClick == true then
        lockClick = false;
    end

end

-- DRAW
function gameplay.draw()

    -- DRAW ACTOR 
    hero.draw();
    Enemies.draw();
    -- DRAW CARD
    for key, value in pairs(cardeGenerator.hand) do

        love.graphics.draw(value.canvas, value.vector2.x, value.vector2.y, 0, value.scale.x, value.scale.y);

    end

    -- DRAW HUD
    hudGameplay.draw();

end
return gameplay;
