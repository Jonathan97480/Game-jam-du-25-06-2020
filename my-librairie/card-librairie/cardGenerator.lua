local cardBackGround = love.graphics.newImage('img/card/CardTheme/card.jpg');
local cardDecoration = love.graphics.newImage('img/card/CardTheme/decoration.png');
local CardPastille = love.graphics.newImage('img/card/CardTheme/power.png');
local Generator={}


function Generator.newCard(p_cardName, p_ilustration, p_description, p_power, p_effect, p_cont)
    for i = 1, p_cont do

        local cart = {};
        cart.vector2 = {
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
        cart.canvas = generateCanvasCard(cart);

        -- table.insert(card.objet, cart);
        table.insert(card.deck, cart);
    end

end

function generateCanvasCard(p_cart)

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

return Generator