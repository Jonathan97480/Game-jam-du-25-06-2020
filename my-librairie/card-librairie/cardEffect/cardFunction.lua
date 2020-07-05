local cardFunction = {}

--[[ deplasse une cart dun emplacement a un autre  ]]
function cardFunction.moveTo(localisationA, numerocard, localisationB)

    local theCard = localisationA[numerocard];
    table.remove(localisationA, numerocard);
    table.insert(localisationB, theCard);

end
--[[ Permet de chercher une carde grasse a son non  ]]
function cardFunction.find(nameCard, localisation)
    local result = 0;
    for i = 1, #localisation do
        if localisation[i].name == nameCard then
            result = i;
        end
    end
    return result;
end
--[[ Permet de jouer nimporte quelle carte qui se trouve dans la main du jouer ]]
function cardFunction.playCardInTheHand(numerocard, newEnergieValue)

    local theCard = card.hand[numerocard];
    theCard.vector2.y = 300;
    theCard.vector2.x = screen.gameReso / 1.5;
    CardAction.Apllique(theCard);

end
--[[ Permet de deplacer une carte du simtier ou en le souette ou de toute le deplacer dun coup  ]]
function cardFunction.grveyardTomove(numeroCard, localisation)

    if numeroCard == 'all' then
        for i = 1, #card.Graveyard do

            local theCard = card.Graveyard[i];
            table.remove(card.Graveyard, i);
            table.insert(localisation, theCard);

        end
    else
        table.insert(localisation, card.Graveyard[numeroCard]);
        table.remove(card.Graveyard, numeroCard);
    end

end
--[[ Permet de vider la main du jouer et de lui enfaire piocher des nouvelle de ou on veux ]]
function cardFunction.newHand(lolalisationMoveHand, cardCunt, localisationPioche)

    if cardCunt ==0 then
        cardCunt = #card.hand;
    end

    for i = 1, #card.hand do
        local theCard = card.hand[i];
        table.insert(lolalisationMoveHand, theCard);
        table.remove(card.hand, i);
    end
    
    if #localisationPioche ~= 0 then

        for i = 1, cardCunt do

            local cardnum = math.random(1, #localisationPioche);
            local theCard = localisationPioche[cardnum];
            table.insert(card.hand, theCard);
            table.remove(localisationPioche, cardnum);

        end
        card.positioneHand();
        return true;
    else
        return false;
    end
    return false;
end
return cardFunction;
