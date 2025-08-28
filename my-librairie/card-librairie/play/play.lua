-- my-librairie/card-librairie/play/play.lua
local Common = require("my-librairie/card-librairie/core/common")
local Layout = require("my-librairie/card-librairie/ui/layout")
local Anim   = require("my-librairie/card-librairie/play/anim")

local function getHud() return rawget(_G, "hud") end
local function getHero() return rawget(_G, "Hero") end
local function getEnemies() return rawget(_G, "Enemies") end
local function getTour() return rawget(_G, "Tour") end

local M = {}

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
    if not Common.__dragLock and Common._updateHandTargets then
        Common._updateHandTargets()
    end
end

local function _tryPlay(_card, free)
    local tour = getTour()
    if _card.actorTag == 'Hero' and tour ~= 'player' then return false end
    if _card.actorTag ~= 'Hero' and tour ~= 'Enemy' then return false end

    local HeroG    = getHero()
    local EnemiesG = getEnemies()
    local source   = (_card.actorTag == 'Hero') and (HeroG and HeroG.actor) or (EnemiesG and EnemiesG.curentEnemy)
    local target   = (_card.actorTag == 'Hero') and (EnemiesG and EnemiesG.curentEnemy) or (HeroG and HeroG.actor)

    if not source then return false end
    if _card._resolving then return false end
    _card._resolving = true
    local prevCurrent = M._currentPlaying
    M._currentPlaying = _card

    local cost = tonumber(_card.PowerBlow or 0) or 0
    if (source.tag == 'Hero') then
        if not free and source.state and source.state.power and source.state.power < cost then
            _card._resolving = false; M._currentPlaying = prevCurrent; return false
        end
        if not free and source.state and source.state.power then
            source.state.power = source.state.power - cost
            local hud = getHud()
            if hud and type(hud.updateLabel) == "function" then
                hud.updateLabel('energy_text', tostring(source.state.power))
            elseif hud and hud.object and hud.object.energie and hud.object.energie.value then
                hud.object.energie.value.text = tostring(source.state.power)
            end
        end
    end

    if _card.Effect then
        Common.playCard(_card, source, target)
    end

    if type(_card.onPlay) == "function" and not _card._suppressOnPlay then
        local user = (_card.actorTag == 'Hero') and getHero() or getEnemies()
        local prev_card = rawget(_G, "card")
        local prev_Card = rawget(_G, "Card")
        rawset(_G, "card", _G.Card or {})
        rawset(_G, "Card", _G.Card or {})
        pcall(_card.onPlay, user)
        rawset(_G, "card", prev_card)
        rawset(_G, "Card", prev_Card)
    end

    _card._suppressOnPlay = nil
    _card._playing = true
    _card._anim = { kind = "jump", t = 0, d = 0.35, startX = _card.vector2.x, startY = _card.vector2.y }
    _card._safetyTimer = 0.6

    _card._resolving = false
    M._currentPlaying = prevCurrent
    return true
end
M._tryPlay = _tryPlay
M.tryPlay = _tryPlay

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
    if Anim and type(Anim.update) == "function" then return Anim.update(dt) end
end

function M.action.draw()
    if Anim and type(Anim.draw) == "function" then return Anim.draw() end
end

function M.drawHand()
    if Anim and type(Anim.drawHand) == "function" then return Anim.drawHand() end
end

M.func = {}
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
    local _card = Common.hand.cards[index]; if not _card then return end
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

function M.clearHand(opts)
    opts        = opts or {}
    local owner = (opts.owner == "Enemy") and "Enemy" or "Hero"
    local dest  = opts.dest or "graveyard"
    if owner == "Enemy" then return 0 else return Layout.moveAll(Common.hand.cards, dest) end
end

function M.clearHandPlayer(opts)
    opts = opts or {}; opts.owner = "Hero"; return M.clearHand(opts)
end

function M.clearHandEnemy(opts)
    opts = opts or {}; opts.owner = "Enemy"; return M.clearHand(opts)
end

return M
