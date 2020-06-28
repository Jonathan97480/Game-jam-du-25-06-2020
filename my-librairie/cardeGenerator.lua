-- REQUIRE

local CardAction = require("my-librairie/cardAction");
local hud = require("my-librairie/hud");

local cardBackGround = love.graphics.newImage('img/card/CardTheme/card.jpg');
local cardDecoration = love.graphics.newImage('img/card/CardTheme/decoration.png');
local CardPastille = love.graphics.newImage('img/card/CardTheme/power.png');

local card = {};
card.objet = {};
card.hand = {};
card.deck = {};
card.Graveyard = {};

function card.create(p_cardName, p_ilustration, p_description, p_power, p_effect, p_cont)
    for i = 1, p_cont do
        -- body

        local cart = {

            vector2 = {
                x = screen.gameReso.width - 337 / 2,
                y = screen.gameReso.height - (462 / 2)
            },
            scale = {
                x = 0.5,
                y = 0.5
            },
            name = p_cardName,
            card = cardBackGround,
            decoration = cardDecoration,
            ilustration = love.graphics.newImage(p_ilustration),
            powerPastille = CardPastille,
            description = p_description,
            PowerBlowCard = p_power,
            oldVector2 = {
                x = 60,
                y = 900
            },
            effect = p_effect
        }

        local Width, Height = cart.card:getDimensions();
        cart.height = Height;
        cart.width = Width;
        -- generate canvas card
        cart.canvas = card.generate(cart)

        -- table.insert(card.objet, cart);
        table.insert(card.deck, cart);
    end

end

-- HOVER MOUSE DETECTION 
function card.hover()

    local isHover = false;


    for i = #card.hand, 1, -1 do

        value = card.hand[i];

        if ( screen.mouse.X >= value.vector2.x and screen.mouse.X <= value.vector2.x + (value.width * value.scale.x) and screen.mouse.Y >= value.vector2.y and screen.mouse.Y <=
            value.vector2.y + (value.height * value.scale.y) and isHover == false) then

           

            if (hud.hover()==false) then

                value.scale.x = 1;
                value.scale.y = 1;

                local isDown = love.mouse.isDown(1);

                if (isDown) then
                    -- DRAG CART MOUSE
                    value.vector2.y = screen.mouse.Y-(value.height / 2);
                    value.vector2.x = screen.mouse.X-(value.width / 2);

                else

                    if value.vector2.y <= 500 and hero.actor.state.power > 0 then
                        
                        if CardAction.Apllique(value) then

                            table.insert(card.Graveyard, card.hand[i]);
                            table.remove(card.hand, i);
                            card.positioneHand();
                        end
                    else
                        value.vector2.y = 600;
                    end
                end

            end

            isHover = true;

        else

            if math.dist(value.vector2.x, value.vector2.y, value.oldVector2.x, value.oldVector2.y) > 5 then

                lerp.x(value.vector2, value.oldVector2, 80);
                value.vector2.y = value.oldVector2.y;
            else

                value.vector2.x = value.oldVector2.x;
            end
            value.scale.x = 0.5;
            value.scale.y = 0.5;

        end

    end
end

function card.clearHand()

    for i = 1, #card.hand do
        local value = card.hand[i];
        table.insert(card.Graveyard, value);
    end

    card.hand = {};

end

-- Return canvas 
function card.generate(p_cart)

    -- create canvas
    local graphicsCard = love.graphics.newCanvas(337, 462);

    love.graphics.clear();

    -- direct drawing operations to the canvas
    love.graphics.setCanvas(graphicsCard);
    love.graphics.rectangle('fill', 0, 0, 338, 462);
    love.graphics.draw(p_cart.card, 0, 0);

    love.graphics.draw(p_cart.ilustration, 57, 50);
    love.graphics.draw(p_cart.decoration, 31, 17);

    love.graphics.draw(p_cart.powerPastille, 15, 22);
    love.graphics.setNewFont(30);
    love.graphics.print(p_cart.PowerBlowCard, 35, 35);
    love.graphics.setNewFont(20);
    love.graphics.print(p_cart.description, 66, 271);
    love.graphics.setNewFont(25);
    love.graphics.print(p_cart.name, 100, 20);

    -- re-enable drawing to the main screen
    love.graphics.setCanvas();

    return graphicsCard;

end

function card.tirage(p_numbercardHand)

    -- Check that there are cards in the deck
    if (#card.deck > 1) then
        pioche(p_numbercardHand);
    else

        for key, value in pairs(card.Graveyard) do
            table.insert(card.deck, value);
        end

        card.Graveyard = {};
        pioche(p_numbercardHand);
    end

end
function pioche(p_numbercardHand)

    -- We check that there are enough cards in the deck
    if (#card.deck < p_numbercardHand) then

        p_numbercardHand = #card.deck;
        card.hand = card.deck;
    else

        for i = 1, p_numbercardHand do

            local cardNumber = math.random(1, #card.deck);
            local curentCart = card.deck[cardNumber];
            curentCart.vector2 = {

                x = screen.gameReso.width - 337 / 2,
                y = screen.gameReso.height - (462 / 2)

            } 

            table.insert(card.hand, curentCart);

            table.remove(card.deck, cardNumber);
        end

        card.positioneHand();
        print(#card.hand)
    end

end
function card.positioneHand()

    hudGameplay.object.cardDeck.value[1].text = #card.deck;
    hudGameplay.object.cardGraveyard.value[1].text = #card.Graveyard;

    for i = 1, #card.hand do
        local curentCart = card.hand[i];

        curentCart.oldVector2 = {
            x = 0,
            y = 0
        };
        curentCart.oldVector2.x = curentCart.oldVector2.x + ((curentCart.width / 2) * (i + 1));
        curentCart.oldVector2.y = screen.gameReso.height - curentCart.height / 2;

    end

end

return card;
