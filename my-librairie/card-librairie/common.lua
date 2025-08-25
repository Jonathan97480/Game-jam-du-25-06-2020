-- my-librairie/card-librairie/common.lua
-- Données, utilitaires, RNG/shuffle, canvas, normalisation, tirage, Deck Global.
-- VERSION MODERNE - Seulement le nouveau système d'effets
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
local applyEffect = require("my-librairie/card-librairie/applyEffect")

local Common = {}



-- ===== Création de deck moderne (doit être défini avant toute utilisation) =====
local Common = {}
Common.deck = Common.deck or {}
function Common.createDeck(name)
    if not name or type(name) ~= "string" then return nil end
    -- Vérifie si le deck existe déjà
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

-- ===== Dépendances sûres =====
local screen       = rawget(_G, "screen") or require("my-librairie/responsive")
local effect       = rawget(_G, "effect") or require("ressources/effect")
local actorManager = rawget(_G, "actorManager") or require("my-librairie/actorManager")


local DEBUG_CARD = true
local function dprint(...) if DEBUG_CARD then print(...) end end
Common.DEBUG_CARD            = DEBUG_CARD
Common.dprint                = dprint

-- ===== Constantes visuelles =====
local CARD_W, CARD_H         = 337, 462
local SCALE_BASE             = 0.50
local DEAL                   = { ENABLED = true, FROM = 'left', DURATION = 0.35, STAGGER = 0.08, HOP = 12 }
Common.CARD_W, Common.CARD_H = CARD_W, CARD_H
Common.SCALE_BASE            = SCALE_BASE
Common.DEAL                  = DEAL



Common.DEFAULT_COPIES = Common.DEFAULT_COPIES or 1

-- ===== Utilitaires de copie profonde =====



-- ===== RNG + shuffle =====
Common._rngSeeded = Common._rngSeeded or false

local function _seedRng()
    if Common._rngSeeded then return end
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or os.time()
    if love.math and love.math.setRandomSeed then love.math.setRandomSeed(t) end
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

-- Convertit une couleur hexadécimale "#RRGGBB" ou "#RRGGBBAA" en valeurs 0-1
function hexToRGB(hex)
    hex = hex:gsub("#", "") -- enlève le #

    -- si seulement 6 caractères, on ajoute alpha à FF (opaque)
    if #hex == 6 then
        hex = hex .. "FF"
    end

    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = tonumber(hex:sub(7, 8), 16) / 255

    return { r = r, g = g, b = b, a = a }
end

--[[
    Fonction qui mélange les cartes d'un deck
    @param deck Le deck à mélanger (deck type table ou name deck type string)
]]
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

-- ===== Canvas & runtime =====

function Common.ensureDeck(deck, max)
    local currentDeck = Common.getDeckByName(deck.name)

    if not currentDeck then return end

    max = tonumber(max or 10) or 10
    if #currentDeck.cards <= max then return end
    Common.shuffle(currentDeck)
    while #currentDeck.cards > max do
        local c = table.remove(currentDeck.cards)
        -- Les cartes supprimées sont simplement retirées du jeu
    end
    dprint(("[player.deck] limité à %d cartes"):format(max))
end

-- Fonction principale pour jouer une carte avec le nouveau système
function Common.playCard(card, source, target)
    if type(card) ~= "table" then return false end
    if type(source) ~= "table" then return false end
    if type(target) ~= "table" then return false end
    if not applyEffect then
        dprint("[card.play] applyEffect requis")
        return false
    end

    -- Appliquer les effets modernes directement
    if applyEffect.applyCardEffect and card.effect then
        applyEffect.applyCardEffect(card, source, target)
    end

    dprint(string.format("[card.play] %s joué par %s contre %s",
        card.name or "Carte inconnue",
        tostring(source.tag or source.name or "Inconnu"),
        tostring(target.tag or target.name or "Inconnu")))

    return true
end

--[[
    Fonction pour récupérer un deck par son nom.
    @param name Le nom du deck à récupérer
    @return Le deck correspondant ou nil si non trouvé
]]
function Common.getDeckByName(name)
    if not name or type(name) ~= "string" then return nil end

    local target = tostring(name):lower()
    for _, d in ipairs(Common.deck) do
        if tostring(d.name or ""):lower() == target then return d or nil end
    end

    return nil
end

-- ===== Tirage moderne =====
function Common.tirage(count, animate, nameDeck)
    count = count or 1
    local currentDeck = Common.getDeckByName(nameDeck)
    if (currentDeck == nil) then
        print("Le deck spécifié n'existe pas.")
        return
    end
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

-- ===== Accès/Debug =====
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
    -- Sécurisation des accès et valeurs par défaut
    local tf                           = card.TextFormatting or {}
    local screenRationW, screenRationH = screen.getRatio()
    local tf_card                      = tf.card or { width = 280, height = 392, scale = 1 }
    local tf_title                     = tf.title or { x = 0, y = 0, font = 'Cambria', size = 16, color = '#FFFFFF' }
    local tf_text                      = tf.text or
        {
            x = 0,
            y = 0,
            width = 200,
            height = 40,
            font = 'Cambria',
            size = 10,
            color = '#FFFFFF',
            align =
            'left'
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
    local can                          = love.graphics.newCanvas(tf_card.width, tf_card.height)
    love.graphics.push("all")
    love.graphics.setCanvas(can)
    love.graphics.clear(1, 1, 1, 1)

    -- Illustration
    if c.illustration then
        local ok, img = pcall(love.graphics.newImage, c.illustration)
        if ok and img then
            local imageScaleW = (tf_card.width / img:getWidth())
            local imageScaleH = (tf_card.height / img:getHeight())

            love.graphics.draw(img, 0, 0, 0, imageScaleW, imageScaleH)
        else
            love.graphics.setColor(0.25, 0.25, 0.3, 1)
            love.graphics.rectangle("fill", 20, 80, w - 40, h - 220)
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.print("Illustration", 28, 88)
        end
    else
        love.graphics.setColor(0.25, 0.25, 0.3, 1)
        love.graphics.rectangle("fill", 20, 80, w - 40, h - 220)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.print("Pas d'illustration", 28, 88)
    end
    local fontScale = 1920 / 1080
    -- Titre
    local pathTitle = 'fonts/' .. (tf_title.font or 'Cambria.ttc')
    local font = love.graphics.newFont(pathTitle, tf_title.size * fontScale or 16)
    love.graphics.setFont(font)
    --[[   local okFontTitle = pcall(love.graphics.setNewFont, pathTitle, tf_title.size * fontScale or 16) ]]
    local _Color = hexToRGB(tf_title.color)

    love.graphics.setColor(_Color.r, _Color.g, _Color.b, _Color.a)
    love.graphics.print(c.name, tf_title.x or 0, tf_title.y or 0)

    -- Description
    local okFontText = pcall(love.graphics.setNewFont, 'fonts/' .. (tf_text.font or 'Cambria'),
        tf_text.size or 10)
    local _Color = hexToRGB(tf_text.color or '#FFFFFF')
    love.graphics.setColor(_Color.r, _Color.g, _Color.b, _Color.a)
    love.graphics.printf(c.description, tf_text.x or 0, tf_text.y or 0, tf_text.width or (w - 40),
        tf_text.align or "left")

    -- Energie
    love.graphics.setColor(0.2, 0.5, 0.9, 1)
    love.graphics.circle("fill", tf_energy.x or 30, tf_energy.y or 30, 18)

    local _Color = hexToRGB(tf_energy.color or '#FFFFFF')
    love.graphics.setColor(_Color.r, _Color.g, _Color.b, _Color.a)
    local okFontEnergy = pcall(love.graphics.setNewFont, 'fonts/' .. (tf_energy.font or 'Cambria'),
        tf_energy.size or 12)


    love.graphics.print(tostring(c.cost), (tf_energy.x or 30) - 6, (tf_energy.y or 30) - 8)


    love.graphics.pop()
    return can
end

--[[
    MODE POSSIBLE : move,copy,
    default : copy
    Move : déplace les cartes (les retire du deck source)
    Copy : copie les cartes (les laisse dans le deck source)
    @param nameDeckSource : le nom du deck source
    @param nameDeckTarget : le nom du deck cible
    @param numberCards : le nombre de cartes à déplacer/copier
    @param mode : le mode d'opération (move ou copy)
]]
--TODO: impleter un tirage random pour le transfert
Common.MoveCardNumberCardDeckToDeck = function(nameDeckSource, nameDeckTarget, numberCards, mode)
    --[[ MODE POSSIBLE : move,copy, ]]

    if mode == nil or type(mode) ~= "string" then
        mode = "copy"
    end
    print(Common.deck)
    local deckSource = Common.getDeckByName(nameDeckSource)
    local deckTarget = Common.getDeckByName(nameDeckTarget)

    if not deckSource or not deckTarget then
        print("Un ou plusieurs decks sont introuvables.")
        return
    end

    if numberCards > #deckSource.cards then
        print("Nombre de cartes à déplacer supérieur au nombre de cartes dans le deck source le deck source possède " ..
            #deckSource.cards .. " cartes. et on doit deplacer " .. numberCards .. " cartes.")
        return
    end

    if mode == "move" then
        for i = 1, numberCards do
            local _card = table.remove(deckSource.cards, 1)
            table.insert(deckTarget.cards, _card)
            print(("Déplacé la carte '%s' de '%s' vers '%s'"):format(_card.name, nameDeckSource, nameDeckTarget))
        end
    elseif mode == "copy" then
        for i = 1, numberCards do
            local _card = table.clone(deckSource.cards[i])
            table.insert(deckTarget.cards, _card)
            print(("Copié la carte '%s' de '%s' vers '%s'"):format(_card and _card.name or "?", nameDeckSource or "?",
                nameDeckTarget or "?"))
        end
    end

    print(("Déplacé %d cartes de '%s' vers '%s'"):format(numberCards, nameDeckSource, nameDeckTarget))
end

return Common
