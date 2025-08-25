local Common = require("my-librairie/card-librairie/common")
local hud = require("my-librairie/hud/hudManager")
local Card = require("my-librairie/card-librairie/card")

local cardsInHand = {}
local deckPlayer = Common.getDeckByName("Hero")

--[[

Fonction : cardsInHand.repositioningCardsInHand

Rôle : Fonction « Repositioning cards in hand » liée à la logique du jeu.

Paramètres :

  - (aucun)

Retour : aucune valeur (nil).

]]

function cardsInHand.repositioningCardsInHand()
    if not deckPlayer then return end

    -- Utilise la structure moderne deck/hand/graveyard (objets deck)
    hud.setText('deck_count', deckPlayer and deckPlayer:size() or 0)
    hud.setText('graveyard_count', Common.graveyard and Common.graveyard:size() or 0)

    if Common.hand and Common.hand.getAll then
        local handCards = Common.hand:getAll()
        for i = 1, #handCards do
            local curentCart = handCards[i]
            curentCart.oldVector2 = { x = 0, y = 0 }
            curentCart.oldVector2.x = curentCart.oldVector2.x + ((curentCart.width / 2) * (i + 1))
            curentCart.oldVector2.y = screen.gameReso.height - curentCart.height / 2
        end
    end
end

--[[

Fonction : cardsInHand.tirage

Rôle : Fonction « Tirage » liée à la logique du jeu.

Paramètres :

  - p_numbercardHand : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function cardsInHand.tirage(p_numbercardHand)
    -- Check that there are cards in the deck (structure moderne)
    if deckPlayer and deckPlayer:size() >= 5 then
        pioche(p_numbercardHand)
    else
        if Card and Card.func and Card.func.graveyardToMove then
            Card.func.graveyardToMove('all', deckPlayer)
        end
        pioche(p_numbercardHand)
    end
end

--[[

Fonction : pioche

Rôle : Fonction « Pioche » liée à la logique du jeu.

Paramètres :

  - p_numbercardHand : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function pioche(p_numbercardHand)
    -- Utilise la structure deck moderne
    if not (deckPlayer and deckPlayer:getAll()) then return end
    local deckCards = deckPlayer:getAll()
    for i = 1, p_numbercardHand do
        if #deckCards == 0 then break end
        local cardNumber
        if #deckCards > 5 then
            cardNumber = math.random(1, #deckCards)
        else
            cardNumber = #deckCards
        end
        local curentCart = deckCards[cardNumber]
        -- Reset position carte
        curentCart.vector2 = curentCart.vector2 or { x = 0, y = 0 }
        curentCart.vector2.x = screen.gameReso.width
        curentCart.vector2.y = screen.gameReso.height - 231
        card.hand:addCard(curentCart)
        table.remove(deckCards, cardNumber)
    end
    if card.positioneHand then card.positioneHand() end
end

return cardsInHand
