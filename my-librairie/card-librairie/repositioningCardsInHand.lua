local cardsInHand ={}

function cardsInHand.repositioningCardsInHand()

    hud.object.cardDeck.value[1].text = #card.deck;
    hud.object.cardGraveyard.value[1].text = #card.Graveyard;

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


function cardsInHand.tirage(p_numbercardHand)

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

                --[[ Reset POsition card to Right bottom Screen ]]
                curentCart.vector2.x = screen.gameReso.width ;
                curentCart.vector2.y = screen.gameReso.height - 231;

            table.insert(card.hand, curentCart);

            table.remove(card.deck, cardNumber);
        end

        card.positioneHand();

    end

end

return cardsInHand