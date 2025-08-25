-- my-librairie/card-librairie/player_ops.lua
-- Hover/drag, play, animations, queue, cimetière, Card.func
-- ⇨ Lookups dynamiques + anti-jitter drag + drag-lock layout
-- ⇨ FALLBACKS si myFonction est absent (hover/click/lerp)

local Common        = require("my-librairie/card-librairie/common")
local screen        = rawget(_G, "screen") or require("my-librairie/responsive")

-- ===== Logs =====
local dprint        = (Common and Common.dprint) or function(...) print(...) end
local DEBUG_VERBOSE = true
local function vlog(...) if DEBUG_VERBOSE then print(...) end end

-- ===== helpers dynamiques =====
local function getHud() return rawget(_G, "hud") end
local function getHero() return rawget(_G, "Hero") end
local function getEnemies() return rawget(_G, "Enemies") end
local function getTour() return rawget(_G, "Tour") end

-- ===== Safe require myFonction (optionnel) =====
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if ok then return mod end
    return nil
end
local myFonction = rawget(_G, "myFonction") or _safeRequire("my-librairie/myFunction")

-- ===== Fallbacks (si myFonction est nil ou incomplet) =====
local function _mousePos()
    local mx = (screen and screen.mouse and screen.mouse.X) or (love.mouse and ({ love.mouse.getPosition() })[1]) or 0
    local my = (screen and screen.mouse and screen.mouse.Y) or (love.mouse and ({ love.mouse.getPosition() })[2]) or 0
    return mx, my
end
local function _hoverRect(x, y, w, h, scale)
    local mx, my = _mousePos()
    local sx = (type(scale) == "table" and (scale.x or 1)) or 1
    local sy = (type(scale) == "table" and (scale.y or 1)) or 1
    local ww, hh = (w or 0) * sx, (h or 0) * sy
    return mx >= x and mx <= x + ww and my >= y and my <= y + hh
end
local function _justClicked(isDown, wasDown)
    return (not isDown) and wasDown
end
local function _lerpTable(vec2, target, speed, dt)
    local a = math.min(1, (dt or 0.016) * (speed or 10))
    vec2.x = vec2.x + (target.x - vec2.x) * a
    vec2.y = vec2.y + (target.y - vec2.y) * a
end

-- wrappers unifiés
local function UX_hover(x, y, w, h, scale)
    if myFonction and myFonction.mouse and myFonction.mouse.hover then
        return myFonction.mouse.hover(x, y, w, h, scale)
    end
    return _hoverRect(x, y, w, h, scale)
end
local function UX_click(isDown, wasDown)
    if myFonction and myFonction.mouse and myFonction.mouse.click then
        return myFonction.mouse.click()
    end
    return _justClicked(isDown, wasDown)
end
local function UX_lerp(vec, target, speed, dt)
    if myFonction and myFonction.lerp then
        return myFonction.lerp(vec, target, speed)
    end
    return _lerpTable(vec, target, speed, dt)
end

-- Détecte si la souris est au-dessus du HUD
local function isMouseOverHUD()
    local hud = getHud()
    local mx = (screen and screen.mouse and screen.mouse.X) or (love.mouse and ({ love.mouse.getPosition() })[1]) or 0
    local my = (screen and screen.mouse and screen.mouse.Y) or (love.mouse and ({ love.mouse.getPosition() })[2]) or 0

    -- 1) API explicite du HUD ?
    if hud then
        if type(hud.isMouseOver) == "function" then
            local ok, r = pcall(hud.isMouseOver, mx, my)
            if ok and r ~= nil then return r and true or false end
        end
        if type(hud.hitTest) == "function" then
            local ok, r = pcall(hud.hitTest, mx, my)
            if ok and r ~= nil then return r and true or false end
        end
        if type(hud.bounds) == "table" then
            local function inRect(ptx, pty, r)
                return ptx >= (r.x or 0) and ptx <= (r.x or 0) + (r.w or 0)
                    and pty >= (r.y or 0) and pty <= (r.y or 0) + (r.h or 0)
            end
            if hud.bounds.x then
                return inRect(mx, my, hud.bounds)
            else
                for _, r in ipairs(hud.bounds) do
                    if inRect(mx, my, r) then return true end
                end
            end
        end
    end

    -- 2) Fallback via HUD_ACTIVE_RECT global (un rect ou liste)
    local R = rawget(_G, "HUD_ACTIVE_RECT")
    local function inRect(ptx, pty, r)
        return ptx >= (r.x or 0) and ptx <= (r.x or 0) + (r.w or 0)
            and pty >= (r.y or 0) and pty <= (r.y or 0) + (r.h or 0)
    end
    if type(R) == "table" then
        if R.x then
            return inRect(mx, my, R)
        else
            for _, r in ipairs(R) do
                if inRect(mx, my, r) then return true end
            end
        end
    end

    -- 3) Dernier recours: supposer un HUD bas de 220px
    local fallbackH = rawget(_G, "HUD_FALLBACK_HEIGHT") or 220
    return my >= (screen.gameReso.height - fallbackH)
end

local function _move_all(from, dest)
    if type(from) ~= "table" then return 0 end
    local moved = 0
    for i = #from, 1, -1 do
        local c = table.remove(from, i)
        if c then
            if dest == "deck" then
                local deckRef = (c.actorTag == 'Enemy') and Card.deckAi or Card.deck
                table.insert(deckRef, c)
            elseif dest == "graveyard" or dest == nil then
                table.insert(Card.graveyard, c)
            elseif dest == "none" or dest == "remove" then
                -- drop
            else
                table.insert(Card.graveyard, c)
            end
            moved = moved + 1
        end
    end
    if from == Common.hand.cards and Common._updateHandTargets and not Common.__dragLock then
        Common._updateHandTargets()
    end
    return moved
end

local M                = {}

-- ===== Constantes hover/drag =====
local HOVER_ELEVATE    = 100
local SCALE_BASE       = Common.SCALE_BASE
local SCALE_HOVER      = 0.95
local SCALE_DRAG       = 1.05
local LERP_POS_SPEED   = 10
local LERP_SCALE_SPEED = 12

-- ===== Drop line =====
local PLAY_LINE_Y      = rawget(_G, "CARD_PLAY_LINE_Y") or 400
local function isInPlayZone(v) return (v.vector2.y or 0) <= PLAY_LINE_Y end

-- ===== Etat input =====
local mouseWasDown = false
local function bringToFront(i)
    if i and Common.hand.cards[i] then
        local _card = table.remove(Common.hand.cards, i)
        table.insert(Common.hand.cards, _card)
    end
end
local draggedCard, draggedIndex = nil, nil

-- ===== Cimetière / positionnement =====
function M.cardToGraveyard(c)
    for i = #Common.hand.cards, 1, -1 do
        if Common.hand.cards[i] == c then
            table.remove(Common.hand.cards, i)
            break
        end
    end
    if Common.graveyard.cards and Common.graveyard.addCard then
        Common.graveyard:addCard(c)
    end
    dprint("[card.graveyard] ->", c.name, " | main:", #Common.hand.cards, "cimetière:",
        Common.graveyard and Common.graveyard:size() or 0)
    if not Common.__dragLock then
        Common._updateHandTargets()
    end
end

function M.positionHand()
    local count = #Common.hand.cards
    if count == 0 then return end
    local spacing = 90
    local totalW  = spacing * (count - 1)
    local startX  = (screen.gameReso.width - totalW) / 2
    local y       = screen.gameReso.height - 231
    for i = 1, count do
        local _card                  = Common.hand.cards[i]
        _card.vector2.x              = startX + (i - 1) * spacing
        _card.vector2.y              = y
        _card.oldVector2             = { x = _card.vector2.x, y = _card.vector2.y }
        _card.scale.x, _card.scale.y = SCALE_BASE, SCALE_BASE
        _card._targetPos             = { x = _card.vector2.x, y = _card.vector2.y }
        _card._targetScale           = { x = SCALE_BASE, y = SCALE_BASE }
    end
end

M.positionHand = M.positionHand

-- ===== Jouer une carte =====
local function _tryPlay(_card)
    local tour = getTour()
    vlog(string.format("[card.tryPlay] start name='%s' tag=%s  Tour=%s",
        tostring(_card.name), tostring(_card.actorTag), tostring(tour)))

    if _card.actorTag == 'Hero' and tour ~= 'player' then
        vlog(string.format("[card.tryPlay] REFUS: pas le tour du joueur (Tour=%s)", tostring(tour)))
        return false
    end
    if _card.actorTag ~= 'Hero' and tour ~= 'Enemy' then
        vlog(string.format("[card.tryPlay] REFUS: pas le tour de l'ennemi (Tour=%s)", tostring(tour)))
        return false
    end

    local HeroG    = getHero()
    local EnemiesG = getEnemies()
    local source   = (_card.actorTag == 'Hero') and (HeroG and HeroG.actor) or (EnemiesG and EnemiesG.curentEnemy)
    local target   = (_card.actorTag == 'Hero') and (EnemiesG and EnemiesG.curentEnemy) or (HeroG and HeroG.actor)

    if not source then
        vlog(string.format(
            "[card.tryPlay] REFUS: source introuvable (Hero=%s, Hero.actor=%s, Enemies=%s, Enemies.curentEnemy=%s)",
            tostring(HeroG ~= nil), tostring(HeroG and HeroG.actor ~= nil),
            tostring(EnemiesG ~= nil), tostring(EnemiesG and EnemiesG.curentEnemy ~= nil)
        ))
        return false
    end

    if _card._resolving then
        vlog("[card.tryPlay] REFUS: déjà en cours de résolution")
        return false
    end
    _card._resolving  = true
    local prevCurrent = M._currentPlaying
    M._currentPlaying = _card

    local cost        = tonumber(_card.PowerBlow or 0) or 0
    local curPow      = source.state and source.state.power or nil

    if (source.tag == 'Hero') then
        vlog(string.format("[card.tryPlay] cost=%d  power_avant=%s", cost, tostring(curPow)))

        if not free and source.state and source.state.power and source.state.power < cost then
            vlog(string.format("[card.tryPlay] REFUS: énergie insuffisante (need=%d, have=%d)", cost, source.state.power))
            _card._resolving = false
            M._currentPlaying = prevCurrent
            return false
        end
        if not free and source.state and source.state.power then
            source.state.power = source.state.power - cost
            vlog(string.format("[card.tryPlay] énergie consommée -> power_rest=%d", source.state.power))
            local hud = getHud()
            if hud and hud.object and hud.object.energie and hud.object.energie.value then
                hud.object.energie.value.text = tostring(source.state.power)
            end
        end
    end

    dprint("[card.play] joue:\t", _card.name, "\tcost:\t", cost, "\ttag:\t", _card.actorTag)

    if _card.Effect then
        Common.playCard(_card, source, target)
    else
        vlog("[card.tryPlay] NOTE: pas d'effets sur la carte (effects/effect nil)")
    end

    if type(_card.onPlay) == "function" and not _card._suppressOnPlay then
        local user = (_card.actorTag == 'Hero') and getHero() or getEnemies()
        local prev_card = rawget(_G, "card")
        local prev_Card = rawget(_G, "Card")
        rawset(_G, "card", _G.Card or {})
        rawset(_G, "Card", _G.Card or {})
        local ok, err = pcall(_card.onPlay, user)
        rawset(_G, "card", prev_card)
        rawset(_G, "Card", prev_Card)
        if not ok then vlog("[card.tryPlay] ERREUR onPlay:", err) end
    end
    _card._suppressOnPlay = nil

    _card._playing        = true
    _card._anim           = { kind = "jump", t = 0, d = 0.35, startX = _card.vector2.x, startY = _card.vector2.y }
    _card._safetyTimer    = 0.6

    _card._resolving      = false
    M._currentPlaying     = prevCurrent
    vlog("[card.tryPlay] SUCCÈS")
    return true
end
M._tryPlay = _tryPlay

-- ===== File d’actions =====
M.action = { queue = {}, current = nil, busy = false }
function M.action.add(_card) if _card then table.insert(M.action.queue, _card) end end

M.action.addAction = M.action.add
function M.action.setCurrent() if not M.action.current then M.action.current = table.remove(M.action.queue, 1) end end

M.action.setCurrentAction = M.action.setCurrent
function M.action._applyEffect(_card) return _tryPlay(_card, false) end

function M.action.play()
    if not M.action.current then M.action.setCurrent() end
    if not M.action.current then return end
    _tryPlay(M.action.current, false)
    M.action.current = nil
end

-- Adaptateur universel (accepte update(dt), self:update(dt), update({dt=...}), update({0.016}))
local function _coerce_dt(a, b)
    if type(a) == "number" and b == nil then return a end
    if type(a) == "table" and type(b) == "number" then return b end
    if type(a) == "table" and type(a.dt) == "number" then return a.dt end
    if type(a) == "table" and type(a[1]) == "number" then return a[1] end
    if love and love.timer and love.timer.getDelta then return love.timer.getDelta() end
    return 0.016
end

function M.action.update(a, b)
    local dt = _coerce_dt(a, b)
    return M.action._update(dt)
end

-- Garde ton ancienne logique dans M.action._update(dt)
local _old_update = M.action.update -- renomme si elle existe déjà
M.action._update = _old_update      -- suppose que ta version actuelle s'appelle M.action.update


-- ===== Update anims (arrival + jump) =====
function M.action._update(dt)
    -- purge sécurité
    for i = #Common.hand.cards, 1, -1 do
        local _card = Common.hand.cards[i]
        if _card and _card._playing and not (_card._anim and _card._anim.kind == "jump") then
            if _card._safetyTimer then
                _card._safetyTimer = _card._safetyTimer - dt
                if _card._safetyTimer <= 0 then
                    _card._playing, _card._safetyTimer = false, nil
                    dprint("[card.anim] sécurité -> cimetière:", _card.name)
                    M.cardToGraveyard(_card)
                end
            end
        end
    end

    -- jump
    local JUMP_HEIGHT = 80
    for i = #Common.hand.cards, 1, -1 do
        local _card = Common.hand.cards[i]
        if _card and _card._playing and _card._anim and _card._anim.kind == "jump" then
            local a = _card._anim
            a.t = (a.t or 0) + dt
            local p = a.t / a.d; if p > 1 then p = 1 end

            local y                                    = a.startY - (4 * JUMP_HEIGHT * p * (1 - p))
            _card.vector2.x                            = a.startX
            _card.vector2.y                            = y

            local sc                                   = 0.95 + 0.05 * math.sin(math.pi * p)
            _card.scale.x, _card.scale.y               = sc, sc

            _card._targetPos                           = _card._targetPos or { x = _card.vector2.x, y = _card.vector2.y }
            _card._targetScale                         = _card._targetScale or { x = _card.scale.x, y = _card.scale.y }
            _card._targetPos.x, _card._targetPos.y     = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y

            if p >= 1 then
                _card._playing = false
                _card._anim    = nil
                dprint("[card.anim] fin jump -> cimetière:", _card.name)
                M.cardToGraveyard(_card)
            end
        end
    end

    -- arrivée (deal) + suivi (pas de re-layout si drag lock)
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
                local hop       = math.sin(math.pi * math.min(1, k)) * (_card.anim.hop or 0)
                _card.vector2.y = lerp(_card.anim.sy, _card.anim.ty, k) - hop
                if p >= 1 then
                    _card.anim                             = nil; _card.locked = false
                    _card.vector2.x, _card.vector2.y       = _card.target.x, _card.target.y
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

function M.action.draw()
    --[[ M.drawHand() ]]
end

-- ===== Dessin de la main =====
function M.drawHand()
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        if _card.canvas then
            love.graphics.draw(_card.canvas, _card.vector2.x, _card.vector2.y, 0, _card.scale.x, _card.scale.y)
        end
    end
end

-- ===== Hover / Drag & Drop =====
local function round(x) return math.floor(x + 0.5) end -- anti-jitter

function M.hover(dt)
    local tour = getTour()

    local isDown = love.mouse.isDown(1)
    local action = UX_click(isDown, mouseWasDown) and "click" or nil

    -- Même si ce n’est pas le tour du joueur, on relâche proprement et on recolle
    if tour ~= 'player' then
        -- libère un éventuel drag ou hover figé
        if draggedCard or Common.__dragLock then
            M.resetInteractions(true)
        end
        -- douceur vers la base
        for i = 1, #Common.hand.cards do
            local _card                                = Common.hand.cards[i]
            local bx                                   = (_card.oldVector2 and _card.oldVector2.x) or
                (_card.target and _card.target.x) or
                _card.vector2.x
            local by                                   = (_card.oldVector2 and _card.oldVector2.y) or
                (_card.target and _card.target.y) or
                _card.vector2.y
            _card._targetPos                           = _card._targetPos or { x = bx, y = by }
            _card._targetScale                         = _card._targetScale or { x = SCALE_BASE, y = SCALE_BASE }
            _card._targetPos.x, _card._targetPos.y     = bx, by
            _card._targetScale.x, _card._targetScale.y = SCALE_BASE, SCALE_BASE
            _lerpTable(_card.vector2, _card._targetPos, LERP_POS_SPEED)
            _lerpTable(_card.scale, _card._targetScale, LERP_SCALE_SPEED)
        end
        mouseWasDown = isDown
        return
    end

    -- === À partir d’ici : tour du joueur, comportement normal ===

    -- 1) HUD ne capte que si la souris est vraiment dessus
    local hud      = getHud()
    local overHUD  = isMouseOverHUD()
    local hudHover = false
    if hud and hud.hover and overHUD and not draggedCard then
        hudHover = hud.hover(action) or false
        if hudHover and not _hud_eats_interactions_logged then
            print("[card.hover] HUD consomme l'input (hover/click) → cartes bloquées cette frame (log unique).")
            _hud_eats_interactions_logged = true
        end
    else
        _hud_eats_interactions_logged = false
    end
    if hudHover then
        mouseWasDown = isDown
        return
    end

    -- 2) carte sous la souris (top-most), sauf si on est déjà en drag
    local topOverI = nil
    if not draggedCard and #Common.hand.cards > 0 then
        for i = #Common.hand.cards, 1, -1 do
            local _card = Common.hand.cards[i]
            if not _card._playing and not _card.locked then
                if UX_hover(_card.vector2.x, _card.vector2.y, _card.width, _card.height, _card.scale) then
                    topOverI = i; break
                end
            end
        end
    end
    if topOverI and topOverI ~= #Common.hand.cards then bringToFront(topOverI) end
    local active = draggedCard or (topOverI and Common.hand.cards[#Common.hand.cards] or nil)

    -- 3) itère les cartes (anti-jitter + drag/hover)
    for i = 1, #Common.hand.cards do
        local _card        = Common.hand.cards[i]
        local bx           = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or
            _card.vector2.x
        local by           = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or
            _card.vector2.y

        _card._targetPos   = _card._targetPos or { x = bx, y = by }
        _card._targetScale = _card._targetScale or { x = SCALE_BASE, y = SCALE_BASE }

        if _card._playing or _card.locked or _card.anim then
            _card._targetPos.x, _card._targetPos.y     = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y
        elseif _card == draggedCard then
            _card.scale.x, _card.scale.y               = SCALE_DRAG, SCALE_DRAG
            local ex                                   = screen.mouse.X - (_card._grabDX or _card.width / 2)
            local ey                                   = screen.mouse.Y - (_card._grabDY or _card.height / 2)
            _card.vector2.x, _card.vector2.y           = ex, ey
            _card._targetPos.x, _card._targetPos.y     = ex, ey
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y

            if not isDown then
                draggedCard, draggedIndex = nil, nil
                Common.__dragLock = false
                local inZone = (_card.vector2.y <= (rawget(_G, "CARD_PLAY_LINE_Y") or 400))
                print(("[card.drop] name='%s' pos=(%.1f,%.1f) inZone=%s Tour=%s"):format(
                    _card.name or "?", _card.vector2.x, _card.vector2.y, tostring(inZone), tostring(tour)))
                if inZone then
                    local ok = M._tryPlay(_card, false)
                    if not ok then
                        _card._targetPos.x, _card._targetPos.y     = bx, by
                        _card._targetScale.x, _card._targetScale.y = SCALE_BASE, SCALE_BASE
                    end
                else
                    _card._targetPos.x, _card._targetPos.y     = bx, by
                    _card._targetScale.x, _card._targetScale.y = SCALE_BASE, SCALE_BASE
                end
            end
        else
            if active and _card == active then
                _card._targetPos.x = bx
                _card._targetPos.y = by - 100 -- HOVER_ELEVATE
                _card._targetScale.x, _card._targetScale.y = 0.95, 0.95
                if isDown and not mouseWasDown and not draggedCard then
                    draggedCard, draggedIndex = _card, i
                    Common.__dragLock = true
                    _card._grabDX = screen.mouse.X - _card.vector2.x
                    _card._grabDY = screen.mouse.Y - _card.vector2.y
                    if i ~= #Common.hand then bringToFront(i) end
                end
            else
                _card._targetPos.x, _card._targetPos.y     = bx, by
                _card._targetScale.x, _card._targetScale.y = SCALE_BASE, SCALE_BASE
            end
        end

        if _card ~= draggedCard and not _card._playing and not _card.locked and not _card.anim then
            _lerpTable(_card.vector2, _card._targetPos, LERP_POS_SPEED)
            _lerpTable(_card.scale, _card._targetScale, LERP_SCALE_SPEED)
        end
    end

    mouseWasDown = isDown
end

-- ===== Card.func (compat) =====
M.func = M.func or {}

local function _normName(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return string.lower(s)
end

function M.func.find(name, list)
    if type(list) ~= "table" then return 0 end
    local target = _normName(name)
    for i = 1, #list do
        local it = list[i]
        if it and _normName(it.name) == target and it ~= M._currentPlaying and not it._resolving and not it._playing then
            return i
        end
    end
    return 0
end

function M.func.moveTo(fromList, index, toList)
    if type(fromList) ~= "table" or type(toList) ~= "table" then return end
    local it = fromList[index]; if not it then return end
    table.remove(fromList, index); table.insert(toList, it)
end

function M.func.playCardInTheHand(index, costOverride)
    local _card = Common.hand[index].cards; if not _card then return end
    if M._currentPlaying and M._currentPlaying ~= _card then _card._suppressOnPlay = true end
    return _tryPlay(_card, (tonumber(costOverride) or 0) == 0)
end

function M.func.graveyardToMove(mode, dest)
    if mode == 'all' and type(dest) == "table" then
        for i = #Common.graveyard.cards, 1, -1 do
            table.insert(dest, Common.graveyard.cards[i])
            table.remove(Common.graveyard.cards, i)
        end
    end
end

-- Vider la main (joueur/ennemi)
function M.clearHand(opts)
    opts        = opts or {}
    local owner = (opts.owner == "Enemy") and "Enemy" or "Hero"
    local dest  = opts.dest or "graveyard"
    if owner == "Enemy" then
        -- pas de main IA : no-op
        return 0
    else
        return _move_all(Common.hand.cards, dest)
    end
end

function M.clearHandPlayer(opts)
    opts = opts or {}; opts.owner = "Hero"
    return M.clearHand(opts)
end

function M.clearHandEnemy(opts)
    opts = opts or {}; opts.owner = "Enemy"
    return M.clearHand(opts)
end

M.func.graveyardToMove = M.func.grveyardTomove

-- === Reset d'interactions (anti-freeze entre tours) =====================

-- remet tous les états d'interaction à zéro et recolle les cartes à leur base
function M.resetInteractions(hard)
    -- hard=true force aussi la position/échelle immédiate
    draggedCard, draggedIndex = nil, nil
    Common.__dragLock = false
    mouseWasDown = false

    for i = 1, #Common.hand.cards do
        local _card                                = Common.hand.cards[i]
        local bx                                   = (_card.oldVector2 and _card.oldVector2.x) or
            (_card.target and _card.target.x) or
            _card.vector2.x
        local by                                   = (_card.oldVector2 and _card.oldVector2.y) or
            (_card.target and _card.target.y) or
            _card.vector2.y

        _card._targetPos                           = _card._targetPos or { x = bx, y = by }
        _card._targetScale                         = _card._targetScale or { x = SCALE_BASE, y = SCALE_BASE }
        _card._targetPos.x, _card._targetPos.y     = bx, by
        _card._targetScale.x, _card._targetScale.y = SCALE_BASE, SCALE_BASE

        if hard then
            _card.vector2.x, _card.vector2.y = bx, by
            _card.scale.x, _card.scale.y     = SCALE_BASE, SCALE_BASE
        end
    end
end

-- appelé par le gameplay lors d'un changement de tour
function M.onTurnChanged(newTour)
    -- dès qu’on quitte le tour du joueur, on purge tout état d’input
    if newTour ~= 'player' then
        M.resetInteractions(true)
    end
end

return M
