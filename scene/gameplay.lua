local gameplay = {};

-- REQUIRE

local hero = require("ActorScripts/hero");
 Enemies = require("ActorScripts/Enemies");
local cards = require("ressources/card");
CardAction = require("my-librairie/card-librairie/cardAction");
Tour = 'transition';
-- VARIABLE
local timerTransition = 0;
-- LOAD
function gameplay.load()
    effect.load();
    hud.load();
    for key, value in pairs(cards) do
        card.create(value.name, value.ImgIlustration, value.Description, value.PowerBlow, value.Effect, 2);
    end

end

-- UPDATE
function gameplay.update(dt)

    if Tour == "player" then
        
        if hero.actor.state.dead~=true then
           
            card.hover(dt);
            CardAction.update();
        
        else

            if myFonction.mouse.click() then

                hud.hover("click");

            end

        end

    elseif Tour == ('Enemy') then

        Enemies.update(dt)

    elseif Tour == 'transition' and timerTransition >= 1.5 then

        timerTransition = 0;
        
        Tour = 'player'
      
        
        hero.actor.state.power = 8;

    elseif Tour == 'transition' then

        timerTransition = timerTransition + delta;
        card.hover();
        
    end
end

-- DRAW
function gameplay.draw()

    -- DRAW ACTOR 
    hero.draw();
    Enemies.draw();
    -- DRAW CARD
    for key, value in pairs(card.hand) do

        love.graphics.draw(value.canvas, value.vector2.x, value.vector2.y, 0, value.scale.x, value.scale.y);

    end

    -- DRAW HUD
    hud.draw();

end

function gameplay.rezetGame()

    for i = 1, #card.hand do
        local value = card.hand[i]
        table.insert(card.deck, value);
    end
    for i = 1, #card.Graveyard do
        local value = card.Graveyard[i]
        table.insert(card.deck, value);
    end

    Enemies.rezet();
    hero.rezet();

end
return gameplay;
