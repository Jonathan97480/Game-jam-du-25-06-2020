local Common         = require("my-librairie/card-librairie/core/common")
local UX             = require("my-librairie/card-librairie/ui/ux")
local screen         = rawget(_G, "screen") or require("my-librairie/responsive")
local Layout         = require("my-librairie/card-librairie/ui/layout")
local okInput, input = pcall(require, "my-librairie/inputManager")
if not okInput then input = nil end
local okI, inputI = pcall(require, "my-librairie/inputInterface")
if not okI then inputI = nil end

local M                         = {}

local mouseWasDown              = false
local draggedCard, draggedIndex = nil, nil
local DEBUG                     = rawget(_G, "DEBUG_CARD_INTERACTION") or false

local function _lerpTable(vec2, target, speed)
    local dt = (love and love.timer and love.timer.getDelta and love.timer.getDelta()) or 0.016
    local a = math.min(1, dt * (speed or 10))
    vec2.x = vec2.x + (target.x - vec2.x) * a
    vec2.y = vec2.y + (target.y - vec2.y) * a
end

local function _getCursor()
    local ok, cur = pcall(require, "my-librairie/cursor")
    if ok and cur and cur.get then return cur.get() end
    return 0, 0
end

M._getDragState = function()
    return draggedCard, draggedIndex
end
M._setDragState = function(card, idx)
    draggedCard, draggedIndex = card, idx
end

function M.resetInteractions(hard)
    draggedCard, draggedIndex = nil, nil
    Common.__dragLock = false
    mouseWasDown = false
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
        local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
        _card._targetPos = _card._targetPos or { x = bx, y = by }
        _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }
        _card._targetPos.x, _card._targetPos.y = bx, by
        _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
        if hard then
            _card.vector2.x, _card.vector2.y = bx, by
            _card.scale.x, _card.scale.y = Common.SCALE_BASE, Common.SCALE_BASE
        end
    end
end

function M.onTurnChanged(newTour)
    if newTour ~= 'player' then
        M.resetInteractions(true)
    end
end

function M.hover(dt)
    local tour = rawget(_G, "Tour")
    local isDown = false
    if input and input.state then
        local s = input.state()
        isDown = (s == 'pressed' or s == 'held')
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            isDown = iface.isActionDown()
        else
            -- fallback to robust globalFunction.mouse.state if available
            local okG, gf = pcall(require, "my-librairie/globalFunction")
            if okG and gf and gf.mouse and gf.mouse.state then
                local st = gf.mouse.state()
                isDown = (st == 'pressed' or st == 'held')
            else
                local ok, v = pcall(function() return love.mouse.isDown(1) end)
                isDown = ok and (v == true) or false
            end
        end
    end
    local action = UX.UX_click(isDown, mouseWasDown) and "click" or nil
    if DEBUG then print("[Card.Interaction] isDown", isDown, "mouseWasDown", mouseWasDown, "action", action) end

    if tour ~= 'player' then
        if draggedCard or Common.__dragLock then
            M.resetInteractions(true)
        end
        for i = 1, #Common.hand.cards do
            local _card = Common.hand.cards[i]
            local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
            local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
            _card._targetPos = _card._targetPos or { x = bx, y = by }
            _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }
            _card._targetPos.x, _card._targetPos.y = bx, by
            _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
            _lerpTable(_card.vector2, _card._targetPos, 10)
            _lerpTable(_card.scale, _card._targetScale, 12)
        end
        mouseWasDown = isDown
        return
    end

    local hud = rawget(_G, "hud")
    local overHUD = UX.isMouseOverHUD()
    local hudHover = false
    if hud and hud.hover and overHUD and not draggedCard then
        hudHover = hud.hover(action) or false
    end
    if hudHover then
        mouseWasDown = isDown; return
    end

    local topOverI = nil
    if not draggedCard and #Common.hand.cards > 0 then
        for i = #Common.hand.cards, 1, -1 do
            local _card = Common.hand.cards[i]
            if not _card._playing and not _card.locked then
                if UX.UX_hover(_card.vector2.x, _card.vector2.y, _card.width, _card.height, _card.scale) then
                    topOverI = i; if DEBUG then print("[Card.Interaction] topOverI", topOverI, _card.name) end; break
                end
            end
        end
    end
    local hoveredCard = (topOverI and Common.hand.cards[topOverI]) or nil
    local active = draggedCard or hoveredCard
    if DEBUG then
        local dcName = draggedCard and draggedCard.name or nil
        print("[Card.Interaction] active index", topOverI, "dragged", dcName)
    end

    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
        local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
        _card._targetPos = _card._targetPos or { x = bx, y = by }
        _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }

        if _card._playing or _card.locked or _card.anim then
            _card._targetPos.x, _card._targetPos.y = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y
        elseif _card == draggedCard then
            _card.scale.x, _card.scale.y = 1.05, 1.05
            local ex, ey = _getCursor()
            ex = ex - (_card._grabDX or _card.width / 2)
            ey = ey - (_card._grabDY or _card.height / 2)
            _card.vector2.x, _card.vector2.y = ex, ey
            _card._targetPos.x, _card._targetPos.y = ex, ey
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y

            if not isDown then
                draggedCard, draggedIndex = nil, nil
                Common.__dragLock = false
                local mx, my = _getCursor()
                local dropY = my
                local playLine = rawget(_G, "CARD_PLAY_LINE_Y") or 400
                local inZone = (dropY <= playLine)
                if DEBUG then print("[Card.Interaction] dropY", dropY, "playLine", playLine, "inZone", inZone) end
                if inZone then
                    local Card = rawget(_G, "Card")
                    local ok = Card and Card.Play and Card.Play.tryPlay and Card.Play.tryPlay(_card, false)
                    if not ok then
                        _card._targetPos.x, _card._targetPos.y = bx, by
                        _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
                    end
                else
                    _card._targetPos.x, _card._targetPos.y = bx, by
                    _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
                end
            end
        else
            if active and _card == active then
                _card._targetPos.x = bx
                _card._targetPos.y = by - 100
                _card._targetScale.x, _card._targetScale.y = 0.95, 0.95
                if isDown and not mouseWasDown and not draggedCard then
                    draggedCard, draggedIndex = _card, i
                    Common.__dragLock = true
                    local gx, gy = _getCursor()
                    _card._grabDX = gx - _card.vector2.x
                    _card._grabDY = gy - _card.vector2.y
                    if i ~= #Common.hand.cards then Layout.bringToFront(i) end
                    if DEBUG then
                        print("[Card.Interaction] start drag", i, _card.name, "grabDX", _card._grabDX, "grabDY",
                            _card._grabDY)
                    end
                end
            else
                _card._targetPos.x, _card._targetPos.y = bx, by
                _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
            end
        end

        if _card ~= draggedCard and not _card._playing and not _card.locked and not _card.anim then
            _lerpTable(_card.vector2, _card._targetPos, 10)
            _lerpTable(_card.scale, _card._targetScale, 12)
        end
    end

    mouseWasDown = isDown
    if DEBUG and not isDown and draggedCard == nil then print("[Card.Interaction] mouse up, no draggedCard") end
end

return M
