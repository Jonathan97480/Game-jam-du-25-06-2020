-- my-librairie/card-librairie/play/anim.lua
-- Module d'animations pour les cartes en main
--
-- Ce module centralise les petits moteurs d'animation utilisés par la main
-- (distribution, saut vers le cimetière, interpolation douce, timers de sécurité).
-- Il expose :
--   - M.update(dt)      : mettre à jour les animations chaque frame
--   - M.draw()          : (placeholder) hook de rendu si besoin
--   - M.drawHand()      : dessine les cartes de la main
--

-- Import du nouveau CardManager
local CardManager = require("my-librairie/card-librairie/card_manager")
-- Principales fonctions internes (documentées ci-dessous) :
--   moveToGrave(card)   : gestion de l'envoi d'une carte au cimetière
--   handleSafety(card,dt): décrémente _safetyTimer et appelle moveToGrave
--   handleJump(card,dt) : anime le saut (arc) et termine en envoyant au cimetière
--   handleAnim(card,dt) : animation type DEAL (sx->tx avec easing + hop)
--   handleSmooth(card,dt): interpolation douce vers la target si nécessaire

local Common = require("my-librairie/card-librairie/core/common")
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
local function getCard() return rawget(_G, "Card") end
local M = {}

local dprint = (Common and Common.dprint) or function(...) print(...) end
-- NOTE: la documentation de chaque fonction est placée juste au-dessus
-- module-level helpers (déplacés hors de M.update pour réutilisation et test)
local function moveToGrave(_card)
    if not _card then return end
    _card._playing = false
    _card._safetyTimer = nil
    dprint("[card.anim] to grave ->", _card.name)
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

        -- NOUVEAU : Utiliser CardManager pour gestion sécurisée
        CardManager.onCardMoveToGrave(_card, "moveToGrave - anim.lua")
    end
end

local function handleSafety(_card, dt)
    if not (_card and _card._playing and not (_card._anim and _card._anim.kind == "jump")) then return end
    if _card._safetyTimer then
        _card._safetyTimer = _card._safetyTimer - dt
        if _card._safetyTimer <= 0 then
            local JUMP_HEIGHT = Common.HOVER and (Common.HOVER.HEIGHT or 80) or 80
        end
    end
end

local JUMP_HEIGHT = 80
local function handleJump(_card, dt)
    if not (_card and _card._playing and _card._anim and _card._anim.kind == "jump") then return end
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
        _card._anim = nil
        moveToGrave(_card)
    end
end

local function handleAnim(_card, dt)
    if not _card or not _card.anim then return end
    _card.anim.t = _card.anim.t + dt
    if _card.anim.t >= 0 then
        local p = math.min(1, _card.anim.t / (Common.DEAL and Common.DEAL.DURATION or 0.5))
        local k = (function(x)
            x = math.max(0, math.min(1, x)); return 1 - (1 - x) ^ 3
        end)(p)
        local function lerp(a, b, t) return a + (b - a) * t end
        _card.vector2.x = lerp(_card.anim.sx, _card.anim.tx, k)
        local hop = math.sin(math.pi * math.min(1, k)) * (_card.anim.hop or 0)
        _card.vector2.y = lerp(_card.anim.sy, _card.anim.ty, k) - hop
        if p >= 1 then
            _card.anim = nil; _card.locked = false
            if _card.target then
                _card.vector2.x, _card.vector2.y = _card.target.x, _card.target.y
                _card.oldVector2.x, _card.oldVector2.y = _card.target.x, _card.target.y
                _card._targetPos.x, _card._targetPos.y = _card.target.x, _card.target.y
            end
            dprint("[card.anim] done ->", _card.name or "card")
        end
    end
end

local function handleSmooth(_card, dt)
    if not _card then return end
    if _card.anim then return end
    if Common.__dragLock then return end
    if _card.target and (math.abs((_card.vector2.x or 0) - _card.target.x) > 0.5 or math.abs((_card.vector2.y or 0) - _card.target.y) > 0.5) then
        local function lerp(a, b, t) return a + (b - a) * t end
        local hoverScale = Common.HOVER and (Common.HOVER.SCALE or 1.05) or 1.05
        local speed = (Common.ANIM and Common.ANIM.SMOOTH_SPEED) or 10
        _card.vector2.x = lerp(_card.vector2.x, _card.target.x, math.min(1, dt * speed))
        _card.vector2.y = lerp(_card.vector2.y, _card.target.y, math.min(1, dt * speed))
    end
end

function M.update(dt)
    dt = dt or (love and love.timer and love.timer.getDelta and love.timer.getDelta()) or 0.016
    -- iterate hand once and dispatch to handlers
    for i = #Common.hand.cards, 1, -1 do
        handleSafety(Common.hand.cards[i], dt)
    end
    for i = #Common.hand.cards, 1, -1 do
        handleJump(Common.hand.cards[i], dt)
    end
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        if _card then
            if _card.anim then
                handleAnim(_card, dt)
            else
                handleSmooth(_card, dt)
            end
        end
    end
end

function M.draw() end

function M.drawHand()
    if not love or not love.graphics then return end

    -- NOUVEAU : Dessiner d'abord la copie standby si elle existe
    local CardStandbyPlay = rawget(_G, "CardStandbyPlay")
    if CardStandbyPlay and CardStandbyPlay.getStandbyCopy then
        local standbyCopy = CardStandbyPlay.getStandbyCopy()
        if standbyCopy and standbyCopy.isVisible ~= false then
            M.drawSingleCard(standbyCopy)
        end
    end

    -- Dessiner les cartes de la main (en ignorant les invisibles)
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]

        -- NOUVEAU : Ignorer les cartes invisibles
        if _card.isVisible ~= false then
            M.drawSingleCard(_card)
        end
    end
end

-- NOUVELLE FONCTION : Dessiner une seule carte (factorisation du code)
function M.drawSingleCard(_card)
    if not _card then return end

    -- compute dimensions and scales
    local x = (_card.vector2 and _card.vector2.x) or 0
    local y = (_card.vector2 and _card.vector2.y) or 0
    local w = _card.width or Common.CARD_W or 280
    local h = _card.height or Common.CARD_H or 392
    local sx = (_card.scale and _card.scale.x) or 1
    local sy = (_card.scale and _card.scale.y) or 1

    -- anchor draw at bottom-center so scaling keeps the base fixed
    local drawX = x + (w * 0.5)
    local drawY = y + h

    -- optional offsets to tweak card placement after changing anchor
    -- prefer per-card override `_card.drawOffset`, else use global `Common.HAND_DRAW_OFFSET`
    local offs = (_card.drawOffset ~= nil) and _card.drawOffset or (Common.HAND_DRAW_OFFSET or { x = 0, y = 0 })
    local ox = offs.x or 0
    local oy = offs.y or 0

    if _card.canvas then
        love.graphics.draw(_card.canvas, drawX + ox, drawY + oy, 0, sx, sy, w * 0.5, h)
    else
        -- fallback simple when canvas is missing: draw a plain card rectangle, title and cost
        local topLeftX = drawX - (w * sx) * 0.5 + ox
        local topLeftY = drawY - (h * sy) + oy

        -- background
        love.graphics.setColor(0.18, 0.18, 0.18)
        love.graphics.rectangle("fill", topLeftX, topLeftY, w * sx, h * sy)
        -- title
        love.graphics.setColor(1, 1, 1)
        local title = tostring(_card.name or _card.cardName or "Carte")
        love.graphics.print(title, topLeftX + 8, topLeftY + 8)
        -- cost badge (not scaled for simplicity)
        love.graphics.setColor(0.2, 0.5, 0.9)
        love.graphics.circle("fill", topLeftX + 30, topLeftY + 30, 18)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(_card.cost or _card.PowerBlow or 0), topLeftX + 24, topLeftY + 22)
    end
end

return M
