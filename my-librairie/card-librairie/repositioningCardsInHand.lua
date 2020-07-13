local cardsInHand = {}

function cardsInHand.repositioningCardsInHand()

    hud.object.cardDeck.value.text = #card.deck;
    hud.object.cardGraveyard.value.text = #card.Graveyard;

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
    if (#card.deck >= 5) then
        pioche(p_numbercardHand);
    else

        card.func.grveyardTomove('all', card.deck);
        pioche(p_numbercardHand);
    end

end

function pioche(p_numbercardHand)

    for i = 1, p_numbercardHand do
        local cardNumber;
        if #card.deck > 5 then
            cardNumber = math.random(1, #card.deck);
        else
            cardNumber = #card.deck;
        end
        local curentCart = card.deck[cardNumber];

        --[[ Reset POsition card to Right bottom Screen ]]
        curentCart.vector2.x = screen.gameReso.width;
        curentCart.vector2.y = screen.gameReso.height - 231;

        table.insert(card.hand, curentCart);

        table.remove(card.deck, cardNumber);
    end

    card.positioneHand();

end

return cardsInHand
