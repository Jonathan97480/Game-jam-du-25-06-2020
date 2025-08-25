-- my-librairie/card-librairie/play/anim.lua
local Common = require("my-librairie/card-librairie/core/common")
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
local function getCard() return rawget(_G, "Card") end
local M = {}

local dprint = (Common and Common.dprint) or function(...) print(...) end

function M.update(dt)
    dt = dt or (love and love.timer and love.timer.getDelta and love.timer.getDelta()) or 0.016
    for i = #Common.hand.cards, 1, -1 do
        local _card = Common.hand.cards[i]
        if _card and _card._playing and not (_card._anim and _card._anim.kind == "jump") then
            if _card._safetyTimer then
                _card._safetyTimer = _card._safetyTimer - dt
                if _card._safetyTimer <= 0 then
                    _card._playing, _card._safetyTimer = false, nil
                    dprint("[card.anim] sécurité -> cimetière:", _card.name)
                    local C = getCard()
                    if C and type(C.cardToGraveyard) == "function" then
                        C.cardToGraveyard(_card)
                    else
                        for j = #Common.hand.cards, 1, -1 do
                            if Common.hand.cards[j] == _card then
                                table.remove(Common.hand.cards, j)
                                break
                            end
                        end
                        if Common.graveyard and Common.graveyard.addCard then
                            Common.graveyard:addCard(_card)
                        end
                        if Common._updateHandTargets and not Common.__dragLock then Common._updateHandTargets() end
                    end
                end
            end
        end
    end

    local JUMP_HEIGHT = 80
    for i = #Common.hand.cards, 1, -1 do
        local _card = Common.hand.cards[i]
        if _card and _card._playing and _card._anim and _card._anim.kind == "jump" then
            local a = _card._anim
            a.t = (a.t or 0) + dt
            local p = a.t / a.d; if p > 1 then p = 1 end
            local y = a.startY - (4 * JUMP_HEIGHT * p * (1 - p))
            _card.vector2.x = a.startX
            _card.vector2.y = y
            local sc = 0.95 + 0.05 * math.sin(math.pi * p)
            _card.scale.x, _card.scale.y = sc, sc
            _card._targetPos = _card._targetPos or { x = _card.vector2.x, y = _card.vector2.y }
            _card._targetScale = _card._targetScale or { x = _card.scale.x, y = _card.scale.y }
            _card._targetPos.x, _card._targetPos.y = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y
            if p >= 1 then
                _card._playing = false
                _card._anim    = nil
                dprint("[card.anim] fin jump -> cimetière:", _card.name)
                local C = getCard()
                if C and type(C.cardToGraveyard) == "function" then
                    C.cardToGraveyard(_card)
                else
                    for j = #Common.hand.cards, 1, -1 do
                        if Common.hand.cards[j] == _card then
                            table.remove(Common.hand.cards, j)
                            break
                        end
                    end
                    if Common.graveyard and Common.graveyard.addCard then
                        Common.graveyard:addCard(_card)
                    end
                    if Common._updateHandTargets and not Common.__dragLock then Common._updateHandTargets() end
                end
            end
        end
    end

    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        if _card.anim then
            _card.anim.t = _card.anim.t + dt
            if _card.anim.t >= 0 then
                local p = math.min(1, _card.anim.t / Common.DEAL.DURATION)
                local k = (function(x)
                    x = math.max(0, math.min(1, x)); return 1 - (1 - x) ^ 3
                end)(p)
                local function lerp(a, b, t) return a + (b - a) * t end
                _card.vector2.x = lerp(_card.anim.sx, _card.anim.tx, k)
                local hop = math.sin(math.pi * math.min(1, k)) * (_card.anim.hop or 0)
                _card.vector2.y = lerp(_card.anim.sy, _card.anim.ty, k) - hop
                if p >= 1 then
                    _card.anim = nil; _card.locked = false
                    _card.vector2.x, _card.vector2.y = _card.target.x, _card.target.y
                    _card.oldVector2.x, _card.oldVector2.y = _card.target.x, _card.target.y
                    _card._targetPos.x, _card._targetPos.y = _card.target.x, _card.target.y
                    dprint("[card.anim] done ->", _card.name or "card")
                end
            end
        else
            if not Common.__dragLock then
                if _card.target and (math.abs((_card.vector2.x or 0) - _card.target.x) > 0.5 or math.abs((_card.vector2.y or 0) - _card.target.y) > 0.5) then
                    local function lerp(a, b, t) return a + (b - a) * t end
                    _card.vector2.x = lerp(_card.vector2.x, _card.target.x, math.min(1, dt * 10))
                    _card.vector2.y = lerp(_card.vector2.y, _card.target.y, math.min(1, dt * 10))
                end
            end
        end
    end
end

function M.draw() end

function M.drawHand()
    if not love or not love.graphics then return end
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        if _card.canvas then
            love.graphics.draw(_card.canvas, _card.vector2.x, _card.vector2.y, 0, _card.scale.x, _card.scale.y)
        else
            -- fallback simple when canvas is missing: draw a plain card rectangle, title and cost
            local x = (_card.vector2 and _card.vector2.x) or 0
            local y = (_card.vector2 and _card.vector2.y) or 0
            local w = _card.width or Common.CARD_W or 280
            local h = _card.height or Common.CARD_H or 392
            local sx = (_card.scale and _card.scale.x) or 1
            local sy = (_card.scale and _card.scale.y) or 1

            -- background
            love.graphics.setColor(0.18, 0.18, 0.18)
            love.graphics.rectangle("fill", x, y, w * sx, h * sy)
            -- title
            love.graphics.setColor(1, 1, 1)
            local title = tostring(_card.name or _card.cardName or "Carte")
            love.graphics.print(title, x + 8, y + 8)
            -- cost badge
            love.graphics.setColor(0.2, 0.5, 0.9)
            love.graphics.circle("fill", x + 30, y + 30, 18)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(_card.cost or _card.PowerBlow or 0), x + 24, y + 22)
        end
    end
end

return M
