local cardFunction = {}

--[[ deplasse une cart dun emplacement a un autre  ]]
function cardFunction.moveTo(p_localisation_origine, p_numeroCard, p_newLocalisation)

    --[[ Selectione une carte ho hazard a deplacer si numero de lacart est egale a zero ]]
    if p_numeroCard == 0 then

        p_numeroCard = math.random(1, #p_localisation_origine);

    end

    table.insert(p_newLocalisation, p_localisation_origine[p_numeroCard]);
    table.remove(p_localisation_origine, p_numeroCard);

    --[[ si on deplasse la card dans la main du jouer  ]]

    card.positioneHand();

end
--[[ Permet de chercher une carde grasse a son non  ]]
function cardFunction.find(p_nameCard, p_localisation)
    local result = 0;

    for i = 1, #p_localisation do

        if p_localisation[i].name == p_nameCard then
            result = i;
        end
    end
    return result;
end
--[[ Permet de jouer nimporte quelle carte qui se trouve dans la main du jouer
    peux prendre en parmatrre une nouvelle valeur pour le cout de la carte en energie ]]
function cardFunction.playCardInTheHand(p_numeroCard, p_value)

    card.hand[p_numeroCard].vector2.y = 300;
    card.hand[p_numeroCard].vector2.x = screen.gameReso.width / 1.5;

    CardAction.Apllique(card.hand[p_numeroCard], p_value);
    table.remove(card.hand,p_numeroCard);
    --[[ est on reposition les carte restant dans la main du jouer  ]]
    card.positioneHand();

end
--[[ Permet de deplacer une carte du simtier ou en le souette ou de toute le deplacer dun coup  ]]
function cardFunction.grveyardTomove(p_numeroCard, localisation)

    if p_numeroCard == 'all' or p_numeroCard == 0 then

        for i = #card.Graveyard, 1, -1 do

            card.Graveyard[i].vector2 = {

                x = screen.gameReso.width - 337 / 2,
                y = screen.gameReso.height - (462 / 2)
            };

            table.insert(localisation, card.Graveyard[i]);
            table.remove(card.Graveyard, i);

        end

        --[[ Clear table Graveyard ]]
        card.Graveyard = {};
        card.positioneHand();
        return;

    elseif p_numeroCard ~= 'all' and p_numeroCard > 0 then

        card.Graveyard[p_numeroCard].vector2 = {
            x = screen.gameReso.width - 337 / 2,
            y = screen.gameReso.height - (462 / 2)
        };

        table.insert(localisation, card.Graveyard[p_numeroCard]);
        table.remove(card.Graveyard, p_numeroCard);

        card.positioneHand();
        return;

    end

end
--[[ Permet de vider la main du jouer et de lui enfaire piocher des nouvelle de ou on veux ]]
function cardFunction.newHand(p_moveLocalisation, p_cardCunt, p_piocheLocalisation)

    for i = 1, #card.hand do

        table.insert(p_moveLocalisation, card.hand[i]);
        table.remove(card.hand, i);
    end
    card.hand = {};
    --[[ On verifie que le lieux de pioche contient des card  ]]
    if #p_piocheLocalisation ~= 0 then

        for i = p_cardCunt, 1, -1 do

            local cardNum = math.random(1, #p_piocheLocalisation);

            table.insert(card.hand, p_piocheLocalisation[cardNum]);
            table.remove(p_piocheLocalisation, cardNum);

        end
        card.positioneHand();
        return true;
    else
        return false;
    end
    return false;
end
return cardFunction;
