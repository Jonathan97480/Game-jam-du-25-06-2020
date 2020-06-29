local gameplay = {};
local lockClick = false;
-- REQUIRE

local hero = require("ActorScripts/hero");
local Enemies = require("ActorScripts/Enemies");
local cards = require("ressources/card");
 CardAction = require("my-librairie/cardAction");
Tour = 'transition';
-- VARIABLE

-- LOAD
function gameplay.load()
    effect.load();
    hudGameplay.load();
    for key, value in pairs(cards) do
        cardeGenerator.create(value.name, value.ImgIlustration, value.Description, value.PowerBlow, value.Effect, 2);
    end
    Enemies.load();
end

-- UPDATE
function gameplay.update(dt)

    cardeGenerator.hover(dt);

    if love.mouse.isDown(1) and lockClick == false then
        lockClick = true;
        hudGameplay.hover('click')
    elseif love.mouse.isDown(1) == false and lockClick == true then
        lockClick = false;
    end

    if Tour == ('Enemy') then

        Enemies.update(dt)

    end
    CardAction.update();
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

function gameplay.rezetGame()

    for i = 1, #cardeGenerator.hand do
        local value = cardeGenerator.hand[i]
        table.insert(cardeGenerator.deck, value);
    end
    for i = 1, #cardeGenerator.Graveyard do
        local value = cardeGenerator.Graveyard[i]
        table.insert(cardeGenerator.deck, value);
    end

    Enemies.load();
    hero.load();

end
return gameplay;
