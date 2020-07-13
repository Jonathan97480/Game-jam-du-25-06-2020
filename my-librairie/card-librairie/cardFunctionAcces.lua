-- REQUIRE
local generateCard = require("my-librairie/card-librairie/cardGenerator");
local cardsInHand = require("my-librairie/card-librairie/repositioningCardsInHand");
local cardOver = require("my-librairie/card-librairie/cardOver");
local func = require("my-librairie/card-librairie/cardEffect/cardFunction");

local cards = {};
cards.func = func;
cards.hand = {};
--[[ LE DECK ]]
cards.deck = {};
--[[ LE SIMETIERE ]]
cards.Graveyard = {};
--[[ GENERATION CARD ]]
cards.create = function(p_cardName, p_ilustration, p_description, p_power, p_effect, p_cont)

    return generateCard.newCard(p_cardName, p_ilustration, p_description, p_power, p_effect, p_cont);
end

-- HOVER MOUSE DETECTION 
function cards.hover(dt)
    cardOver.hover(dt);
end

cards.clearHand = function()

    for i = 1, #cards.hand do
        local value = cards.hand[i];
        table.insert(cards.Graveyard, value);
    end

    cards.hand = {};

end

-- Return canvas 

function cards.tirage(p_numbercardHand)

    cardsInHand.tirage(p_numbercardHand);
end

--[[ GENERATION CARD ]]
function cards.positioneHand()

    cardsInHand.repositioningCardsInHand();

end

return cards;
