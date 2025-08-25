-- my-librairie/card-librairie/core/generator.lua
-- Copié de card-librairie/generator.lua, require vers core/common

local Common = require("my-librairie/card-librairie/core/common")
local dprint = Common.dprint

local M = {}

function M.loadCards(cardsRessources, actortag, deckName)
    local deck
    if deckName == nil then deckName = "globalDeck" end
    if type(cardsRessources) ~= "table" then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] cardsRessources n'est pas une table :",
                type(cardsRessources))
        else
            print("[card.loadCards] cardsRessources n'est pas une table :",
                type(cardsRessources))
        end
        return false
    end
    if type(actortag) ~= "string" then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] actortag n'est pas une string :", type(actortag))
        else
            print("[card.loadCards] actortag n'est pas une string :", type(actortag))
        end
        return false
    end
    if type(deckName) ~= "string" then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] deckName n'est pas une string :", type(deckName))
        else
            print("[card.loadCards] deckName n'est pas une string :", type(deckName))
        end
        return false
    end

    -- Ensure the named deck exists and obtain a reference to it.
    deck = Common.getDeckByName(deckName)
    if not deck then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] deck n'existe pas :", deckName, " -> création")
        else
            print("[card.loadCards] deck n'existe pas :", deckName, " -> création")
        end
        Common.createDeck(deckName)
        deck = Common.getDeckByName(deckName)
    end
    if deck == nil then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] impossible d'obtenir le deck :", deckName)
        else
            print(
                "[card.loadCards] impossible d'obtenir le deck :", deckName)
        end
        return false
    end
    if not deck or type(deck) ~= "table" then
        if Common and Common.dprint then
            Common.dprint("[card.loadCards] deck n'est pas valide :", type(deck))
        else
            print(
                "[card.loadCards] deck n'est pas valide :", type(deck))
        end
        return false
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
            if Common and Common.dprint then
                Common.dprint(("[card.loadCards] carte ajoutée au deck '%s' : %s"):format(
                    deckName, card.name))
            else
                print(("[card.loadCards] carte ajoutée au deck '%s' : %s"):format(deckName,
                    card.name))
            end
        else
            if Common and Common.dprint then
                Common.dprint("[card.loadCards] carte n'est pas valide :", type(_card))
            else
                print("[card.loadCards] carte n'est pas valide :", type(_card))
            end
        end
    end
end

return M
