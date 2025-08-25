-- my-librairie/card-librairie/ui/layout.lua
local Common = require("my-librairie/card-librairie/core/common")
local M = {}

local function getCard()
    return rawget(_G, "Card")
end

function M.positionHand()
    local count = #Common.hand.cards
    if count == 0 then return end
    local spacing = 90
    local totalW  = spacing * (count - 1)
    local startX  = (screen.gameReso.width - totalW) / 2
    local y       = screen.gameReso.height - 231
    for i = 1, count do
        local _card = Common.hand.cards[i]
        _card.vector2.x = startX + (i - 1) * spacing
        _card.vector2.y = y
        _card.oldVector2 = { x = _card.vector2.x, y = _card.vector2.y }
        _card.scale.x, _card.scale.y = Common.SCALE_BASE, Common.SCALE_BASE
        _card._targetPos = { x = _card.vector2.x, y = _card.vector2.y }
        _card._targetScale = { x = Common.SCALE_BASE, y = Common.SCALE_BASE }
    end
end

function M.bringToFront(i)
    local Card = getCard()
    if type(i) ~= "number" then return nil end
    if i <= 0 or i > #Common.hand.cards then return nil end
    if i == #Common.hand.cards then
        if Card and type(Card._updateHandTargets) == "function" and not Common.__dragLock then Card._updateHandTargets() end
        return true
    end
    local c = table.remove(Common.hand.cards, i)
    if not c then return nil end
    table.insert(Common.hand.cards, c)
    if Card and type(Card._updateHandTargets) == "function" and not Common.__dragLock then
        Card._updateHandTargets()
    end
    return true
end

function M.moveAll(from, dest)
    if type(from) ~= "table" then return 0 end
    local moved = 0
    local Card = getCard()
    for i = #from, 1, -1 do
        local c = table.remove(from, i)
        if c then
            if dest == "deck" then
                local deckRef = (c.actorTag == 'Enemy') and (Card and Card.deckAi) or (Card and Card.deck)
                if deckRef then table.insert(deckRef, c) end
            elseif dest == "graveyard" or dest == nil then
                if Card and Card.graveyard then table.insert(Card.graveyard, c) end
            elseif dest == "none" or dest == "remove" then
            else
                if Card and Card.graveyard then table.insert(Card.graveyard, c) end
            end
            moved = moved + 1
        end
    end
    if from == Common.hand.cards and Common._updateHandTargets and not Common.__dragLock then
        Common._updateHandTargets()
    end
    return moved
end

return M
