local gameplay = {};
local curentTour = '';
-- REQUIRE
local cards = require("ressources/card");
hero = require("my-librairie/ActorScripts/player/hero");
Enemies = require("my-librairie/ActorScripts/Enemy/Enemies");
CardAction = require("my-librairie/card-librairie/cardEffect/cardAction");
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
    if curentTour ~= Tour then
        curentTour = Tour;
        print(curentTour);
    end
    if Tour == "player" and hero.actor.state.dead == false then

        card.hover(dt);
        CardAction.update();

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

    for i = #card.hand, 1, -1 do

        local value = card.hand[i];
        love.graphics.draw(value.canvas, value.vector2.x, value.vector2.y, 0, value.scale.x, value.scale.y);

    end
    -- DRAW HUD
    hud.draw();

end

function gameplay.rezetGame()
    --[[ on deplace toute les carte dans la main du jouer dans le deck  ]]
    for i = 1, #card.hand do
        --[[ On re positionne corectement la carte avant de la deplacer ]]
        card.hand[i].vector2 = {
            x = screen.gameReso.width - 337 / 2,
            y = screen.gameReso.height - (462 / 2)
        };

        table.insert(card.deck, card.hand[i]);
    end
    card.hand = {};
    --[[ on deplasse toute les carte du simetierre dans le deck  ]]
    card.func.grveyardTomove('all', card.deck)

    --[[ rezet les Enemy ]]
    Enemies.curentEnemy = {};
    Enemies.load();
    --[[ rezet le Hero ]]
    hero.rezet();
    --[[ On retire des nouvelle card ]]
    card.tirage(5);
    Tour = 'player';
end
return gameplay;
