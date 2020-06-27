-- REQUIRE
local screen = require("my-librairie/responsive");
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
                x = 60,
                y = 900
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

        table.insert(card.objet, cart);
        table.insert(card.deck, cart);
    end

end

-- HOVER MOUSE DETECTION 
function card.hover()

    local isHover = false;

    local x, y = love.mouse.getPosition();

    x = x / screen.ratioScreen.width;
    y = y / screen.ratioScreen.height;

    for i = #card.hand, 1, -1 do

        value = card.hand[i];

        if (x >= value.vector2.x and x <= value.vector2.x + (value.width * value.scale.x) and y >= value.vector2.y and y <=
            value.vector2.y + (value.height * value.scale.y) and isHover == false) then

            local objet = hud.hover();

            if (objet.validate == false) then
                value.scale.x = 1;
                value.scale.y = 1;

                card.dragAndDrop(x, y, value, i);

                -- DEBUG
                love.graphics.setColor(1, 0, 0);
                love.graphics.rectangle('line', value.vector2.x, value.vector2.y, value.width * value.scale.x,
                                        value.height * value.scale.y);
                love.graphics.setColor(1, 1, 1);

            end

            isHover = true;

        else

            value.vector2.y = value.oldVector2.y;
            value.vector2.x = value.oldVector2.x;

            value.scale.x = 0.5;
            value.scale.y = 0.5;
        end

    end
end

function card.clearHand()

    for key, value in pairs(card.hand) do

        table.insert(card.Graveyard, value);

    end

    card.hand = {};

end

-- DRAG CART MOUSE
function card.dragAndDrop(p_x, p_y, cart, p_cardNumber)

    -- check is down
    if love.mouse.isDown(1) then

        cart.vector2.y = p_y - (cart.height / 2);
        cart.vector2.x = p_x - (cart.width / 2);

    else

        -- Reset Position Cart

        if cart.vector2.y <= 500 then
            if CardAction.Apllique(cart) then

                table.insert(card.Graveyard, card.hand[p_cardNumber]);
                table.remove(card.hand, p_cardNumber);
                card.positioneHand();
            end
        else
            cart.vector2.y = 600;
        end

    end

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
    love.graphics.print(p_cart.name, 125, 20);

    -- re-enable drawing to the main screen
    love.graphics.setCanvas();

    return graphicsCard;

end

function card.tirage(p_numbercardHand)

    -- Check that there are cards in the deck
    if (#card.deck ~= 0) then
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

            table.insert(card.hand, curentCart);

            table.remove(card.deck, cardNumber);
        end

        card.positioneHand();
    end

end
function card.positioneHand()

    hudGameplay.object.cardDeck.value[1].text = #card.deck;
    hudGameplay.object.cardGraveyard.value[1].text = #card.Graveyard;

    for i = 1, #card.hand do
        local curentCart = card.hand[i];
        curentCart.vector2 = {
            x = 0,
            y = 0
        };
        curentCart.vector2.x = curentCart.vector2.x + ((curentCart.width / 2) * (i + 1));
        curentCart.oldVector2.x = curentCart.vector2.x;
    end

end

return card;
