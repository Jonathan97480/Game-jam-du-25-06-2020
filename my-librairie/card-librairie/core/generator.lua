-- my-librairie/card-librairie/core/generator.lua
-- Copié de card-librairie/generator.lua, require vers core/common

local Common = require("my-librairie/card-librairie/core/common")
local dprint = Common.dprint

local M = {}

function M.loadCards(cardsRessources, actortag, deckName)
    local deck
    if deckName == nil then deckName = "globalDeck" end
    if type(cardsRessources) ~= "table" then
        dprint("[card.loadCards] cardsRessources n'est pas une table :", type(cardsRessources))
        return
    end
    if type(actortag) ~= "string" then
        dprint("[card.loadCards] actortag n'est pas une string :", type(actortag))
        return
    end
    if type(deckName) ~= "string" then
        dprint("[card.loadCards] deckName n'est pas une string :", type(deckName))
        return
    end

    if not Common.getisDeckExistsByDeck(deckName) then
        dprint("[card.loadCards] deck n'existe pas :", deckName .. " on va le créer")
        deck = Common.createDeck(deckName)
    else
        deck = Common.getDeckByName(deckName)
    end
    if deck == nil then
        dprint("[card.loadCards] deck est nil :", deckName)
        return
    end
    if not deck or type(deck) ~= "table" then
        dprint("[card.loadCards] deck n'est pas valide :", type(deck))
        return
    end

    for _, _card in ipairs(cardsRessources) do
        if type(_card) == "table" then
            local card = table.clone(_card)
            card.canvas = Common.generateCanvasCard(card)
            card.actorTag = actortag
            card.vector2 = { x = 0, y = 0 }
            card.oldVector2 = { x = 0, y = 0 }
            card._targetPos = { x = 0, y = 0 }
            card.scale = { x = 1, y = 1 }
            card._targetScale = { x = 1, y = 1 }
            card.__resolving = true
            card._suppressOnPlay = false
            card.onPlay = _card.onPlay or function() end
            card.__playing = false
            card._anim = { kind }
            card._safetyTimer = 0
            card.target = { x = 0, y = 0 }
            card.width = card.TextFormatting.card.width or 337
            card.height = card.TextFormatting.card.height or 512
            card._grabDX = 0
            card._grabDY = 0
            card._isGrabbed = false
            card.locked = false
            deck:addCard(card)
            dprint(("[card.loadCards] carte ajoutée au deck '%s' : %s"):format(deckName, card.name))
        else
            dprint("[card.loadCards] carte n'est pas valide :", type(_card))
        end
    end
end

return M
