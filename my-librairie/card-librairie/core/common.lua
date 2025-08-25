-- my-librairie/card-librairie/core/common.lua
-- Données, utilitaires, RNG/shuffle, canvas, normalisation, tirage, Deck Global.
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
-- Formerly required 'applyEffect'. After refactor effects live under `effects/cardEffect_shim`.
local ok, applyEffect = pcall(require, "my-librairie/card-librairie/effects/cardEffect_shim")
if not ok then
    -- fallback: try legacy path to keep backward compatibility
    local status, mod = pcall(require, "my-librairie/card-librairie/applyEffect")
    applyEffect = status and mod or nil
end

local Common = {}
Common.deck = Common.deck or {}
function Common.createDeck(name)
    if not name or type(name) ~= "string" then return nil end
    for _, d in ipairs(Common.deck) do
        if d.name == name then return d end
    end
    local deck = {
        name = name,
        cards = {},
        addCard = function(self, card)
            if type(card) == "table" then table.insert(self.cards, card) end
        end,
        removeCard = function(self, idx)
            table.remove(self.cards, idx)
        end,
        size = function(self)
            return #self.cards
        end,
        getAll = function(self)
            return self.cards
        end
    }
    table.insert(Common.deck, deck)
    return deck
end

Common.hand        = Common.createDeck("hand")
Common.graveyard   = Common.createDeck("graveyard")

local screen       = rawget(_G, "screen") or require("my-librairie/responsive")
local effect       = rawget(_G, "effect") or require("ressources/effect")
local actorManager = rawget(_G, "actorManager") or require("my-librairie/actorManager")

local DEBUG_CARD   = true
local function dprint(...) if DEBUG_CARD then print(...) end end
Common.DEBUG_CARD = DEBUG_CARD
Common.dprint     = dprint

-- utility pour appeler des fonctions potentiellement absentes (love.*)
local function safe_call(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

-- helper to call love.graphics functions by name (index access avoids static linter mapping)
-- compatibility fallbacks for table.pack / table.unpack on older Lua (LuaJIT/Lua 5.1)
local _table_pack = table.pack or function(...)
    local t = { ... }
    t.n = select('#', ...)
    return t
end
local _table_unpack = table.unpack or unpack

local function lg_call(name, ...)
    local args = _table_pack(...)
    return safe_call(function()
        local lg = love and love.graphics
        local fn = lg and lg[name]
        if type(fn) == 'function' then
            return fn(_table_unpack(args, 1, args.n))
        end
    end)
end

-- helper for love.math functions
local function mm_call(name, ...)
    local args = _table_pack(...)
    return safe_call(function()
        local lm = love and love.math
        local fn = lm and lm[name]
        if type(fn) == 'function' then
            return fn(_table_unpack(args, 1, args.n))
        end
    end)
end

local CARD_W, CARD_H         = 337, 462
local SCALE_BASE             = 0.50
local DEAL                   = { ENABLED = true, FROM = 'left', DURATION = 0.35, STAGGER = 0.08, HOP = 12 }
Common.CARD_W, Common.CARD_H = CARD_W, CARD_H
Common.SCALE_BASE            = SCALE_BASE
Common.DEAL                  = DEAL

Common.DEFAULT_COPIES        = Common.DEFAULT_COPIES or 1

local function _seedRng()
    if Common._rngSeeded then return end
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or os.time()
    mm_call('setRandomSeed', t)
    math.randomseed(t)
    Common._rngSeeded = true
end

function Common.shuffle(t)
    if type(t) ~= "table" or #t <= 1 then return end
    _seedRng()
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function hexToRGB(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        hex = hex .. "FF"
    end
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = tonumber(hex:sub(7, 8), 16) / 255
    return { r = r, g = g, b = b, a = a }
end

function Common.shuffleDeck(deck)
    if not deck then return end
    if type(deck) ~= "table" then
        if type(deck) == "string" then
            deck = Common.getDeckByName(deck)
        else
            dprint("[card.shuffle] deck n'est pas valide :", type(deck))
            return
        end
    end
    local deckRef = deck
    Common.shuffle(deckRef.cards)
    dprint(("[card.shuffle] %s deck mélangé (%d cartes)"):format(deck.name, #deckRef.cards))
end

function Common._computeSlot(i, n)
    local spacing      = 180
    local baselineY    = screen.gameReso.height - 150
    local baseScale    = SCALE_BASE
    local cw           = CARD_W * baseScale
    local ch           = CARD_H * baseScale
    local total        = (n - 1) * spacing
    local startCenterX = (screen.gameReso.width - total) * 0.5
    local cx           = startCenterX + (i - 1) * spacing
    local cy           = baselineY - ch * 0.5
    return cx, cy
end

function Common._updateHandTargets()
    local n = Common.hand:size()
    for i, _card in ipairs(Common.hand.cards) do
        local tx, ty = Common._computeSlot(i, n)
        if not _card.target then _card.target = { x = 0, y = 0 } end
        if not _card.scale then _card.scale = { x = SCALE_BASE, y = SCALE_BASE } end
        if not _card.width then _card.width = CARD_W end
        if not _card.height then _card.height = CARD_H end
        if not _card.vector2 then _card.vector2 = { x = tx, y = ty } end
        if not _card.oldVector2 then _card.oldVector2 = { x = tx, y = ty } end
        if not _card._targetPos then _card._targetPos = { x = tx, y = ty } end
        _card.target.x, _card.target.y         = tx, ty
        _card.oldVector2.x, _card.oldVector2.y = tx, ty
        _card._targetPos.x, _card._targetPos.y = tx, ty
    end
end

function Common.ensureDeck(deck, max)
    local currentDeck = Common.getDeckByName(deck.name)
    if not currentDeck then return end
    max = tonumber(max or 10) or 10
    if #currentDeck.cards <= max then return end
    Common.shuffle(currentDeck)
    while #currentDeck.cards > max do
        local c = table.remove(currentDeck.cards)
    end
    dprint(("[player.deck] limité à %d cartes"):format(max))
end

function Common.playCard(card, source, target)
    if type(card) ~= "table" then return false end
    if type(source) ~= "table" then return false end
    if type(target) ~= "table" then return false end
    if not applyEffect then
        dprint("[card.play] applyEffect requis")
        return false
    end
    if not card then return false end
    if not (source and target) then
        dprint("[card.play] source et target requis")
        return false
    end
    if applyEffect.applyCardEffect then applyEffect.applyCardEffect(card, source, target) end
    dprint(string.format("[card.play] %s joué par %s contre %s",
        card.name or "Carte inconnue",
        tostring(source.tag or source.name or "Inconnu"),
        tostring(target.tag or target.name or "Inconnu")))
    return true
end

function Common.getDeckByName(name)
    if not name or type(name) ~= "string" then return nil end
    local target = tostring(name):lower()
    for _, d in ipairs(Common.deck) do
        if tostring(d.name or ""):lower() == target then return d or nil end
    end
    return nil
end

function Common.tirage(count, animate, nameDeck)
    count = count or 1
    local currentDeck = Common.getDeckByName(nameDeck)
    if (currentDeck == nil) then
        print("Le deck spécifié n'existe pas.")
        return
    end
    print(string.format("[debug] Common.tirage -> demande %d depuis '%s' (deck size before=%d)", count,
        tostring(nameDeck), #currentDeck.cards))
    if count <= 0 then return end
    local actuallyDrawn = 0
    for _ = 1, count do
        if #currentDeck.cards == 0 then break end
        local _card = table.remove(currentDeck.cards, 1)
        if not _card then break end
        Common.hand:addCard(_card)
        _card.scale   = _card.scale or { x = 0.5, y = 0.5 }
        _card.width   = _card.width or CARD_W
        _card.height  = _card.height or CARD_H
        actuallyDrawn = actuallyDrawn + 1
    end
    if actuallyDrawn == 0 then return end
    Common._updateHandTargets()
    print(string.format("[debug] Common.tirage -> tiré %d cartes (hand now=%d, deck now=%d)", actuallyDrawn,
        #Common.hand.cards, #currentDeck.cards))
    local n = #Common.hand.cards
    local startIndex = n - actuallyDrawn + 1
    local baseDelay = 0
    for i = startIndex, n do
        local _card = Common.hand.cards[i]
        local sx = (DEAL.FROM == 'left') and (-_card.width - 40) or (screen.gameReso.width + 40)
        local sy = _card.target.y
        if animate ~= false and DEAL.ENABLED then
            _card.locked     = true
            _card.anim       = {
                t        = -baseDelay,
                sx       = sx,
                sy       = sy,
                tx       = _card.target.x,
                ty       = _card.target.y,
                duration = DEAL.DURATION,
                hop      = DEAL.HOP
            }
            _card.vector2    = { x = sx, y = sy }
            _card.oldVector2 = { x = _card.target.x, y = _card.target.y }
            _card._targetPos = { x = _card.target.x, y = _card.target.y }
            baseDelay        = baseDelay + DEAL.STAGGER
        else
            _card.vector2    = { x = _card.target.x, y = _card.target.y }
            _card.oldVector2 = { x = _card.target.x, y = _card.target.y }
            _card._targetPos = { x = _card.target.x, y = _card.target.y }
            _card.locked     = false
            _card.anim       = nil
        end
    end
    dprint(("[card.draw] +%d -> hand:%d (animate=%s)"):format(actuallyDrawn, #Common.hand, tostring(animate ~= false)))
end

function Common.deckList() return Common.deck end

function Common.handList() return Common.hand.cards end

function Common.displayDeck()
    return table.concat((function()
        local t = {}
        for i, c in ipairs(Common.deck) do
            t[i] = (c and c.name) or "?"
        end
        return t
    end)(), ", ")
end

function Common.getisDeckExistsByDeck(deck)
    if not (deck and type(deck) == "table") then
        print("Le deck n'est pas valide.")
        return false
    end
    if not (deck.name and type(deck.name) == "string") then
        print("Le nom du deck n'est pas valide.")
        return false
    end
    for _, d in ipairs(Common.deck) do
        if d.name == deck.name then
            return true
        end
    end
    return false
end

function Common.generateCanvasCard(card)
    local tf                           = card.TextFormatting or {}
    local screenRationW, screenRationH = screen.getRatio()
    local tf_card                      = tf.card or { width = 280, height = 392, scale = 1 }
    local tf_title                     = tf.title or { x = 0, y = 0, font = 'Cambria', size = 16, color = '#FFFFFF' }
    local tf_text                      = tf.text or {
        x = 0,
        y = 0,
        width = 200,
        height = 40,
        font = 'Cambria',
        size = 10,
        color = '#FFFFFF',
        align = 'left'
    }
    local tf_energy                    = tf.energy or { x = 30, y = 30, font = 'Cambria', size = 12, color = '#FFFFFF' }
    local w                            = tf_card.width or 280
    local h                            = tf_card.height or 392
    local scale                        = tf_card.scale or 1
    local c                            = {}
    c.name                             = card.name or card.Name or card.title or card.cardName or "Carte"
    c.description                      = card.Description or card.description or ""
    c.cost                             = card.PowerBlow or card.cost or card.power or 0
    c.illustration                     = card.ImgIlustration or card.illustration
    -- Si LÖVE n'est pas présent (analyse statique / tests), rendre neutre
    if not (love and love.graphics) then
        return nil
    end

    local can
    do
        local ok, val = lg_call('newCanvas', tf_card.width, tf_card.height)
        if ok then can = val end
    end
    if not can then return nil end

    lg_call('push')
    lg_call('setCanvas', can)
    lg_call('clear')

    if c.illustration then
        local ok, img = lg_call('newImage', c.illustration)
        if ok and img then
            local imageW = (type(img['getWidth']) == 'function' and img['getWidth'](img)) or 1
            local imageH = (type(img['getHeight']) == 'function' and img['getHeight'](img)) or 1
            local imageScaleW = tf_card.width / imageW
            local imageScaleH = tf_card.height / imageH
            lg_call('draw', img, 0, 0, 0, imageScaleW, imageScaleH)
        else
            lg_call('setColor', 0.25, 0.25, 0.3, 1)
            lg_call('rectangle', "fill", 20, 80, w - 40, h - 220)
            lg_call('setColor', 1, 1, 1, 0.6)
            lg_call('print', "Illustration", 28, 88)
        end
    else
        lg_call('setColor', 0.25, 0.25, 0.3, 1)
        lg_call('rectangle', "fill", 20, 80, w - 40, h - 220)
        lg_call('setColor', 1, 1, 1, 0.6)
        lg_call('print', "Pas d'illustration", 28, 88)
    end

    local fontScale = 1920 / 1080
    local pathTitle = 'fonts/' .. (tf_title.font or 'Cambria.ttc')
    local fontSize = (tf_title.size or 16) * fontScale
    local okFont, font = lg_call('newFont', pathTitle, fontSize)
    if okFont and font then lg_call('setFont', font) end

    local _Color = hexToRGB(tf_title.color)
    lg_call('setColor', _Color.r, _Color.g, _Color.b, _Color.a)
    lg_call('print', c.name, tf_title.x or 0, tf_title.y or 0)

    lg_call('setNewFont', 'fonts/' .. (tf_text.font or 'Cambria'), tf_text.size or 10)
    local _ColorText = hexToRGB(tf_text.color or '#FFFFFF')
    lg_call('setColor', _ColorText.r, _ColorText.g, _ColorText.b, _ColorText.a)
    lg_call('printf', c.description, tf_text.x or 0, tf_text.y or 0, tf_text.width or (w - 40), tf_text.align or "left")

    lg_call('setColor', 0.2, 0.5, 0.9, 1)
    lg_call('circle', "fill", tf_energy.x or 30, tf_energy.y or 30, 18)

    local _ColorEnergy = hexToRGB(tf_energy.color or '#FFFFFF')
    lg_call('setColor', _ColorEnergy.r, _ColorEnergy.g, _ColorEnergy.b, _ColorEnergy.a)
    lg_call('setNewFont', 'fonts/' .. (tf_energy.font or 'Cambria'), tf_energy.size or 12)
    lg_call('print', tostring(c.cost), (tf_energy.x or 30) - 6, (tf_energy.y or 30) - 8)

    -- ensure we unset the canvas before popping the graphics state
    lg_call('setCanvas', nil)
    lg_call('pop')
    return can
end

-- Déplace/copie un nombre de cartes d'un deck vers un autre (nom des decks, insensible à la casse)
-- mode: 'move' ou 'copy' (par défaut 'copy'). Retourne true si OK, false sinon.
function Common.MoveCardNumberCardDeckToDeck(nameDeckSource, nameDeckTarget, numberCards, mode)
    if type(nameDeckSource) ~= 'string' or type(nameDeckTarget) ~= 'string' then
        dprint('[MoveCard] noms de decks invalides')
        return false
    end
    mode = (type(mode) == 'string') and mode or 'copy'
    numberCards = tonumber(numberCards) or 0
    if numberCards <= 0 then
        dprint('[MoveCard] nombre de cartes invalide:', tostring(numberCards))
        return false
    end

    local src = Common.getDeckByName(nameDeckSource)
    local dst = Common.getDeckByName(nameDeckTarget)
    if not src or not dst then
        dprint(('[MoveCard] deck introuvable src=%s dst=%s'):format(tostring(nameDeckSource), tostring(nameDeckTarget)))
        return false
    end

    if #src.cards == 0 then
        dprint(('[MoveCard] src vide: %s'):format(src.name))
        return true -- rien à faire, mais pas une erreur
    end

    if numberCards > #src.cards then
        dprint(('[MoveCard] demandé %d > disponible %d, on adapte'):format(numberCards, #src.cards))
        numberCards = #src.cards
    end

    if mode == 'move' then
        for i = 1, numberCards do
            local c = table.remove(src.cards, 1)
            if c then table.insert(dst.cards, c) end
        end
    else -- copy
        for i = 1, numberCards do
            local c = src.cards[i]
            if c then table.insert(dst.cards, table.clone(c)) end
        end
    end
    dprint(('[MoveCard] %d cartes %s de %s -> %s (src now=%d dst now=%d)'):format(numberCards, mode, src.name, dst.name,
        #src.cards, #dst.cards))
    return true
end

return Common
