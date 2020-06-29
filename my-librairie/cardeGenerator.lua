-- REQUIRE

local hud = require("my-librairie/hud");

local cardBackGround = love.graphics.newImage('img/card/CardTheme/card.jpg');
local cardDecoration = love.graphics.newImage('img/card/CardTheme/decoration.png');
local CardPastille = love.graphics.newImage('img/card/CardTheme/power.png');

local card = {};
--[[ LA MAIN DU JOUER ]]
card.hand = {};
--[[ LE DECK ]]
card.deck = {};
--[[ LE SIMETIERE ]]
card.Graveyard = {};

function card.create(p_cardName, p_ilustration, p_description, p_power, p_effect, p_cont)
    for i = 1, p_cont do

        local cart = {};
        cart.vector2 = 
        {
            x = screen.gameReso.width - 337 / 2,
            y = screen.gameReso.height - (462 / 2)
        };
        cart.scale = {
            x = 0.5,
            y = 0.5
        };
        cart.name = p_cardName;
        cart.card = cardBackGround;
        cart.decoration = cardDecoration;
        cart.ilustration = love.graphics.newImage(p_ilustration);
        cart.powerPastille = CardPastille;
        cart.description = p_description;
        cart.PowerBlowCard = p_power;
        cart.oldVector2 = {
            x = 60,
            y = 900
        };
        cart.effect = p_effect;

        local Width, Height = cart.card:getDimensions();
        cart.height = Height;
        cart.width = Width;
        -- generate canvas card
        cart.canvas = card.generate(cart);

        -- table.insert(card.objet, cart);
        table.insert(card.deck, cart);
    end

end

-- HOVER MOUSE DETECTION 
function card.hover(dt)



    for i = #card.hand, 1, -1 do

        value = card.hand[i];

        if screen.mouse.X >= value.vector2.x and screen.mouse.X <= value.vector2.x + (value.width * value.scale.x) and
            screen.mouse.Y >= value.vector2.y and screen.mouse.Y <= value.vector2.y + (value.height * value.scale.y) and Tour ~= "transition" then

            if (hud.hover() == false) then

                value.scale.x = 1;
                value.scale.y = 1;

                local isDown = love.mouse.isDown(1);

                if (isDown) then
                    -- DRAG CART MOUSE POSITION
                    value.vector2.y = screen.mouse.Y - (value.height / 2);
                    value.vector2.x = screen.mouse.X - (value.width / 2);

                else
                    --[[ Applique car si elle est deplaser go  moin a 300pixel de haut  ]]
                    if value.vector2.y <= 400 and hero.actor.state.power >= 0 then

                        if CardAction.Apllique(value) then
                            --[[ Reset POsition card to Right bottom Screen ]]
                            value.vector2.x = screen.gameReso.width - 168.5;
                            value.vector2.y = screen.gameReso.height - 231;
                            --[[ On enleve la carde de la main du jouer et on la met dans le simetiere  ]]
                            table.insert(card.Graveyard, card.hand[i]);
                            table.remove(card.hand, i);
                            --[[ est on reposition les carte restant dans la main du jouer  ]]
                            card.positioneHand();

                        end
                    elseif value.vector2.y >580 and isDown ==false then

                      lerp (value.vector2, {x=value.vector2.x,y=600},4);
                    end
                end

            end

       
        else

          local Arrival= lerp(value.vector2, value.oldVector2, 4);
            
           
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

        curentCart.oldVector2 = {
            x = 0,
            y = 0
        };
        curentCart.oldVector2.x = curentCart.oldVector2.x + ((curentCart.width / 2) * (i + 1));
        curentCart.oldVector2.y = screen.gameReso.height - curentCart.height / 2;

    end

end

return card;
